local g = vim.g
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
    pcall(vim.api.nvim_del_user_command, usercmd_name)

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

    local startup = 0
    vim.api.nvim_create_user_command(usercmd_name, function()
        require("cthru.cthru").hook_cthru({ reset = startup == 0, toggle = true })
        if startup == 0 then startup = 1 end
    end, {
        nargs = 0,
        bar = false,
        bang = false,
        desc = "Toggle background color of highlight groups",
    })
end

return M
