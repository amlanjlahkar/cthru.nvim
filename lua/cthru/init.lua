local defaults = require("cthru.defaults")
local usercmd_name = defaults.usrcmd

local M = {}

---@class CThruOpts
---@field additional_groups table? Additional highlight groups to be included
---@field cache_path string? Cache location
---@field excluded_groups table? Highlight groups to be excluded from default list

---Gateway method for external configuration
---@param opts CThruOpts
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

    -- Delete usercommand set by default upon calling configure
    pcall(vim.api.nvim_del_user_command, usercmd_name)

    M.register_usrcmd(opts)
end

---Register user command
---@param opts table
M.register_usrcmd = function(opts)
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
        vim.g.cthru_groups = hl_groups
    end

    assert(vim.fn.exists(":" .. usercmd_name) ~= 2)
    vim.api.nvim_create_user_command(usercmd_name, function()
        require("cthru.utils.cthru").init_cthru({
            hl_groups = vim.g.cthru_groups,
            force_update = false,
            toggle = true,
        })
    end, {
        nargs = 0,
        bar = false,
        bang = false,
        desc = "Toggle background color of highlight groups",
    })
end

return M
