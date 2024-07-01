local g = vim.g
local api = vim.api
local usercmd_name = "CthruToggle"
local default_groups = require("cthru.default_groups")

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
    local hl_groups = hl_groups_iter:totable()

    if opts then
        local exclude = opts.excluded_groups
        if exclude then
            hl_groups_iter:map(function(hlg)
                return not vim.list_contains(exclude, hlg) and hlg or nil
            end)
        end
        vim.list_extend(hl_groups, opts.additional_groups or {})
        g.cthru_groups = hl_groups
    end

    api.nvim_create_user_command(usercmd_name, function()
        M.hook_cthru()
    end, {
        nargs = 0,
        bar = false,
        bang = false,
        desc = "Toggle background color of highlight groups",
    })
end

---@param toggle? boolean #Default is `true`
M.hook_cthru = function(toggle)
    toggle = (toggle == nil or toggle) and true

    if toggle then g._cthru = not g._cthru end

    for _, hlg in pairs(g.cthru_groups) do
        if g._cthru then
            api.nvim_set_hl(0, hlg, vim.tbl_extend("keep", { bg = "NONE", ctermbg = "NONE" }, Cthru_hl_map[hlg]))
        else
            api.nvim_set_hl(0, hlg, Cthru_hl_map[hlg])
        end
    end
end

return M
