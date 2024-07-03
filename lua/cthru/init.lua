-- Global table to store highlight group attributes
Cthru_hl_map = {}

local g = vim.g
local api = vim.api
local usrcmd_name = "CthruToggle"
local default_groups = g.cthru_groups
local cache_path = vim.fn.stdpath("data") .. "/.cthru_prev_state"

-- stylua: ignore
---@diagnostic disable-next-line: undefined-field
if not vim.uv.fs_access(cache_path, "R") then
    assert(vim.fn.writefile({}, cache_path, "s") == 0)
end

local M = {}

M.reset_hl_map = function()
    Cthru_hl_map = {}
    for _, hlg in pairs(g.cthru_groups) do
        Cthru_hl_map[hlg] = api.nvim_get_hl(0, { name = hlg, create = false })
    end
end

---@class CThruConf
---@field additional_groups table? Additional highlight groups to be included
---@field excluded_groups table? Highlight groups to be excluded from default list
---@field remember_state boolean? Remember previous cthru state

---Gateway method for external configuration
---@param opts? CThruConf
M.configure = function(opts)
    opts = opts or {}

    if opts then
        local valid_arg_types = {
            additional_groups = "table",
            excluded_groups = "table",
            remember_state = "boolean",
        }
        for key, value in pairs(opts) do
            assert(valid_arg_types[key], "cthru: invalid key received inside setup call: " .. key)
            vim.validate({ [key] = { value, { valid_arg_types[key] }, true } })
        end
    end

    -- Empty the highlight table and delete usercommand set by plugin/cthru upon calling configure
    if vim.fn.exists(":" .. usrcmd_name) == 2 then
        api.nvim_del_user_command(usrcmd_name)
        Cthru_hl_map = {}
    end

    M.register_usrcmd(opts)
end

---@param opts? CThruConf
M.register_usrcmd = function(opts)
    opts = opts or {}

    local hl_groups_iter = vim.iter(default_groups)
    local hl_groups = hl_groups_iter:totable()

    local exclude = opts.excluded_groups
    if exclude then
        hl_groups_iter:map(function(hlg)
            return not vim.list_contains(exclude, hlg) and hlg or nil
        end)
    end
    vim.list_extend(hl_groups, opts.additional_groups or {})
    g.cthru_groups = hl_groups

    local table_empty = 1
    if opts.remember_state then
        local file = assert(io.open(cache_path))
        if file then
            g._cthru = file:read("*l") == "true"
            if g._cthru then
                table_empty = 0
                vim.defer_fn(function()
                    M.reset_hl_map()
                    M.hook_cthru(false)
                end, g.cthru_defer_count)
            end
            file:close()
        end
    end

    -- If empty, populate the highlight table at startup
    if table_empty == 1 then vim.defer_fn(function()
        M.reset_hl_map()
    end, g.cthru_defer_count) end

    api.nvim_create_user_command(usrcmd_name, function()
        M.hook_cthru(true)
    end, {
        nargs = 0,
        bar = false,
        bang = false,
        desc = "Toggle background color of highlight groups",
    })
end

---@param toggle boolean Toggle cthru state
M.hook_cthru = function(toggle)
    assert(type(_G["Cthru_hl_map"]) == "table" and type(toggle) == "boolean")

    if toggle then g._cthru = not g._cthru end

    for hlg, attr in pairs(Cthru_hl_map) do
        if g._cthru then
            api.nvim_set_hl(0, hlg, vim.tbl_extend("keep", { bg = "NONE", ctermbg = "NONE" }, attr))
        else
            api.nvim_set_hl(0, hlg, attr)
        end
    end

    -- stylua: ignore
    if toggle then
        assert(vim.fn.writefile({ tostring(g._cthru) }, cache_path, "s") == 0)
    end
end

return M
