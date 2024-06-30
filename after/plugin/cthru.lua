assert(vim.fn.has("nvim-0.10.0") == 1, "cthru: minimum neovim version 0.10.0 required!")

local g = vim.g
local defaults = require("cthru.defaults")

g._cthru = false
g._cthru_changed = false
g.cthru_groups = g.cthru_groups or defaults.hl_groups
g.cthru_defer_count = g.cthru_defer_count or 300

if vim.fn.exists(":" .. defaults.usrcmd) ~= 2 then require("cthru").register_usrcmd({}) end

-- Make sure vim.g.colors_name is loaded properly
vim.defer_fn(function()
    g._cthru_color = g.colors_name
end, 1000)

local augroup = vim.api.nvim_create_augroup("_cthru", { clear = true })

vim.api.nvim_create_autocmd("ColorSchemePre", {
    group = augroup,
    command = "hi clear",
})

vim.api.nvim_create_autocmd("ColorScheme", {
    desc = "Maintain cthru state on changing colorschemes",
    group = augroup,
    callback = function(opts)
        g._cthru_changed = g._cthru_color ~= nil and g._cthru_color ~= g.colors_name
        if g._cthru_changed then g._cthru_color = g.colors_name end

        -- Always called when cthru is enabled to reflect changes on the same colorscheme
        if g._cthru then
            --[[
                Defer calling method to ensure custom highlights
                for default colorscheme are properly applied
            --]]
            vim.defer_fn(function()
                require("cthru.utils.cthru").hook_cthru({
                    force_update = g._cthru_changed,
                    toggle = false,
                })
            end, opts.match == g.cthru_color and g.cthru_defer_count or 0)
        end
    end,
})
