local uv = vim.uv
local api = vim.api
local set_hl = api.nvim_set_hl

local utils = require("cthru.utils")

local M = {}

---@class CThruOpts
---@field cache_path string? A custom location for storing cache
---@field additional_groups table? Additional groups to be managed by cthru

---Setup method for cthru
---@param opts CThruOpts
M.setup = function(opts)
    assert(type(opts) == "table", "cthru: Pass an empty table if no options are to be provided")
    vim.validate({
        additional_groups = { opts["additional_groups"], { "table", "nil" } },
        excluded_groups = { opts["excluded_groups"], { "table", "nil" } },
        cache_path = { opts["cache_path"], { "string", "nil" } },
    })

    vim.g._cthru = false
    vim.g._cthru_cache = {}

    M.register_usrcmd(opts)
end

---Register user command
---@param opts table
M.register_usrcmd = function(opts)
    local defaults = require("cthru.defaults")

    local cache_path = defaults.cache_path
    local hl_groups_iter = vim.iter(defaults.hl_groups)

    if opts then
        local exclude = opts["excluded_groups"]
        if exclude then
            hl_groups_iter:map(function(hlg)
                return not vim.tbl_contains(exclude, hlg) and hlg or nil
            end)
        end
        vim.list_extend(hl_groups_iter:totable(), opts["additional_groups"] or {})
        cache_path = opts.cache_path or cache_path
    end

    local usercmd_name = "CThru"

    assert(vim.fn.exists(":" .. usercmd_name) ~= 2)
    api.nvim_create_user_command(usercmd_name, function()
        M.cthru(cache_path, hl_groups_iter:totable())
    end, {
        nargs = 0,
        bar = false,
        bang = false,
        desc = "Toggle background color for certain highlight groups \
                to get a 'C-Thru' effect",
    })
end

---Main function
---@param cache_path string
---@param hl_groups table
M.cthru = function(cache_path, hl_groups)
    assert(type(hl_groups) == "table")

    ---@diagnostic disable-next-line: undefined-field
    if not uv.fs_access(cache_path, "R") then
        local hl_map = utils.gen_new_hlmap(hl_groups)
        utils.overwrite_cache(cache_path, vim.json.encode(hl_map))
    end

    local hl_map_cached = {}

    if not next(vim.g._cthru_cache) then
        local file = assert(io.open(cache_path))
        if not file then return end

        local cached_data = file:read("*l")
        hl_map_cached = vim.json.decode(cached_data)
        vim.g._cthru_cache = hl_map_cached

        file:close()
    else
        hl_map_cached = vim.g._cthru_cache
    end

    local update_cache, hl_map = utils.cmp_hlmap(hl_groups, hl_map_cached)

    if update_cache then
        vim.schedule(function()
            utils.overwrite_cache(cache_path, vim.json.encode(hl_map_cached))
        end)
        vim.g._cthru_cache = hl_map_cached
    end

    vim.g._cthru = not vim.g._cthru

    for hlg, val in pairs(hl_map) do
        if vim.g._cthru then
            local hl_opt = vim.tbl_extend("keep", { bg = "NONE", ctermbg = "NONE" }, val.hl_opt)
            if val.use then set_hl(0, hlg, hl_opt) end
        else
            set_hl(0, hlg, val.hl_opt)
        end
    end
end

return M
