local uv = vim.uv
local api = vim.api
local set_hl = api.nvim_set_hl

local utils = require("cthru.utils")

local M = {}

---@class CThruOpts
---@field additional_groups table? Additional highlight groups to be included
---@field cache_path string? Cache location
---@field excluded_groups table? Highlight groups to be excluded from default list

---Setup method for cthru
---@param opts CThruOpts
M.setup = function(opts)
    assert(vim.fn.has("nvim-0.10.0") == 1, "cthru: minimum neovim version 0.10.0 required!")

    opts = opts or {}

    if opts then
        local valid_arg_types = {
            additional_groups = "table",
            cache_path = "string",
            excluded_groups = "table",
        }

        local arg_enum = vim.iter(valid_arg_types):enumerate()

        for key, value in pairs(opts) do
            -- stylua: ignore
            assert(arg_enum:any(function(_, arg) return key == arg end), "cthru: invalid key received inside setup call: " .. key)
            vim.validate({
                [key] = {
                    value,
                    function(v)
                        return vim.list_contains({ valid_arg_types[key], "nil" }, type(v))
                    end,
                    valid_arg_types[key],
                },
            })
        end
    end

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
    local hl_groups = hl_groups_iter:totable()

    if opts then
        local exclude = opts["excluded_groups"]
        if exclude then
            hl_groups_iter:map(function(hlg)
                return not vim.list_contains(exclude, hlg) and hlg or nil
            end)
        end
        vim.list_extend(hl_groups, opts["additional_groups"] or {})
        cache_path = opts.cache_path or cache_path
    end

    local usercmd_name = defaults.usrcmd

    assert(vim.fn.exists(":" .. usercmd_name) ~= 2)
    api.nvim_create_user_command(usercmd_name, function()
        M.cthru(cache_path, hl_groups)
    end, {
        nargs = 0,
        bar = false,
        bang = false,
        desc = "Toggle background color of highlight groups",
    })
end

---Main function
---@param cache_path string
---@param hl_groups table
M.cthru = function(cache_path, hl_groups)
    assert(type(hl_groups) == "table")

    local hl_map = {}
    local update_cache = false

    ---@diagnostic disable-next-line: undefined-field
    if not uv.fs_access(cache_path, "R") then
        hl_map = utils.gen_new_hlmap(hl_groups)
        update_cache = true
    end

    if not next(vim.g._cthru_cache) then
        if next(hl_map) then
            vim.g._cthru_cache = hl_map
        else
            local file = assert(io.open(cache_path))
            if not file then return end

            local cached_data = file:read("*l")
            hl_map = vim.json.decode(cached_data)
            vim.g._cthru_cache = hl_map

            file:close()
        end
    else
        hl_map = vim.g._cthru_cache
    end

    local hl_map_copy = {}
    update_cache, hl_map_copy = utils.cmp_hlmap(hl_groups, hl_map)

    vim.g._cthru = not vim.g._cthru

    for hlg, val in pairs(hl_map_copy) do
        if vim.g._cthru then
            local hl_opt = vim.tbl_extend("keep", { bg = "NONE", ctermbg = "NONE" }, val.hl_opt)
            if val.use then set_hl(0, hlg, hl_opt) end
        else
            set_hl(0, hlg, val.hl_opt)
        end
    end

    if update_cache then
        vim.g._cthru_cache = hl_map
        vim.schedule(function()
            utils.overwrite_cache(cache_path, vim.json.encode(hl_map))
        end)
    end

end

return M
