local M = {}

---@class CThruOpts
---@field additional_groups table? Additional highlight groups to be included
---@field cache_path string? Cache location
---@field excluded_groups table? Highlight groups to be excluded from default list

---Gateway method for external configuration
---@param opts CThruOpts
M.configure = function(opts)
    assert(vim.fn.has("nvim-0.10.0") == 1, "cthru: minimum neovim version 0.10.0 required!")

    opts = opts or {}

    if opts then
        local valid_arg_types = {
            additional_groups = "table",
            cache_path = "string",
            excluded_groups = "table",
        }
        for key, value in pairs(opts) do
            assert(valid_arg_types[key], "cthru: invalid key received inside setup call: " .. key)
            vim.validate({ [key] = { value, { valid_arg_types[key] }, true } })
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
    vim.api.nvim_create_user_command(usercmd_name, function()
        require("cthru.utils.cthru").init_cthru(cache_path, hl_groups)
    end, {
        nargs = 0,
        bar = false,
        bang = false,
        desc = "Toggle background color of highlight groups",
    })
end

return M
