local g = vim.g
local api = vim.api
local usercmd_name = "CthruToggle"
local default_groups = g.cthru_groups

local M = {}

---@class CThruConf
---@field additional_groups table? Additional highlight groups to be included
---@field excluded_groups table? Highlight groups to be excluded from default list

---Gateway method for external configuration
---@param opts? CThruConf
M.configure = function(opts)
    opts = opts or {}

    if opts then
        local valid_arg_types = {
            additional_groups = "table",
            excluded_groups = "table",
        }
        for key, value in pairs(opts) do
            assert(valid_arg_types[key], "cthru: invalid key received inside setup call: " .. key)
            vim.validate({ [key] = { value, { valid_arg_types[key] }, true } })
        end
    end

    -- Delete usercommand set by plugin/cthru upon calling configure
    pcall(api.nvim_del_user_command, usercmd_name)

    M.register_usrcmd(opts)
end

---@param opts? CThruConf
M.register_usrcmd = function(opts)
    opts = opts or {}

    local hl_groups_iter = vim.iter(default_groups)

    if opts then
        local exclude = opts.excluded_groups
        if exclude then
            hl_groups_iter:map(function(hlg)
                return not vim.list_contains(exclude, hlg) and hlg or nil
            end)
        end
        vim.list_extend(default_groups, opts.additional_groups or {})
        g.cthru_groups = default_groups
    end

    if vim.tbl_isempty(Cthru_hl_map) then
        for _, hlg in pairs(g.cthru_groups) do
            Cthru_hl_map[hlg] = api.nvim_get_hl(0, { name = hlg })
        end
    end

    api.nvim_create_user_command(usercmd_name, function()
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
end

return M
