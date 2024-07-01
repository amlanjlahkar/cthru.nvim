assert(vim.fn.has("nvim-0.10.0") == 1, "cthru: minimum neovim version 0.10.0 required!")

local g = vim.g
local defaults = require("cthru.defaults")

g._cthru = false
g.cthru_groups = g.cthru_groups or defaults.hl_groups
g.cthru_defer_count = g.cthru_defer_count or 300

if vim.fn.exists(":" .. defaults.usrcmd) ~= 2 then require("cthru").register_usrcmd({}) end

local augroup = vim.api.nvim_create_augroup("_cthru", { clear = true })

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
        --[[
            Always call hook method if cthru is enabled to maintain state,
            particularly on the same colorscheme when switched
        --]]
        if g._cthru then
            -- Defer calling method to ensure custom highlights for default colorscheme are properly applied
            vim.defer_fn(function()
                require("cthru.utils.cthru").hook_cthru({
                    force_update = g._cthru_col_changed,
                    toggle = false,
                })
            end, opts.match == g.cthru_color and g.cthru_defer_count or 0)
        end
    end,
})
