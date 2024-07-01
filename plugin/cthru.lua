assert(vim.fn.has("nvim-0.10.0") == 1, "cthru: minimum neovim version 0.10.0 required!")

local g = vim.g

g._cthru = false
g._cthru_usrcmd_name = "CthruToggle"
g.cthru_groups = g.cthru_groups or require("cthru.default_groups")
g.cthru_defer_count = g.cthru_defer_count or 300

require("cthru").register_usrcmd()

local augroup = vim.api.nvim_create_augroup("_cthru", { clear = true })
local hook_cthru = require("cthru.cthru").hook_cthru
local default_color = nil

vim.api.nvim_create_autocmd("ColorSchemePre", {
    desc = "Clear custom highlight groups before setting a colorscheme",
    group = augroup,
    callback = function(opts)
        local curr_color = opts.match

        g._cthru_col_changed = g._cthru_col_prev ~= curr_color

        if g._cthru_col_changed then vim.cmd.highlight("clear") end

        if not g._cthru_col_prev or g._cthru_col_changed then g._cthru_col_prev = curr_color end
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
                    hook_cthru({ toggle = false })
                end, g.cthru_defer_count)
            else
                hook_cthru({ toggle = false })
            end
        end
    end,
})