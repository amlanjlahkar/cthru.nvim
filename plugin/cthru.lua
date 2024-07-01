assert(vim.fn.has("nvim-0.10.0") == 1, "cthru: minimum neovim version 0.10.0 required!")

local g = vim.g

g._cthru = false
g.cthru_groups = g.cthru_groups or require("cthru.default_groups")
g.cthru_defer_count = g.cthru_defer_count or 300

require("cthru").register_usrcmd()

local color_changed = false
local default_color = nil
local prev_color = nil
local hook_cthru = require("cthru.cthru").hook_cthru

local augroup = vim.api.nvim_create_augroup("_cthru", { clear = true })

vim.api.nvim_create_autocmd("ColorSchemePre", {
    desc = "Clear custom highlight groups before setting a colorscheme",
    group = augroup,
    callback = function(opts)
        color_changed = prev_color ~= opts.match

        if color_changed then vim.cmd.highlight("clear") end

        if not prev_color or color_changed then prev_color = opts.match end
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    desc = "Maintain cthru state on changing colorschemes",
    group = augroup,
    callback = function(opts)
        if not default_color then default_color = g.colors_name end

        if g._cthru then
            -- Defer calling method to ensure custom highlights for default colorscheme are properly applied
            if opts.match == default_color then
                vim.defer_fn(function()
                    hook_cthru({ reset = true, toggle = false })
                end, g.cthru_defer_count)
            else
                hook_cthru({ reset = true, toggle = false })
            end
        end

        color_changed = false
    end,
})
