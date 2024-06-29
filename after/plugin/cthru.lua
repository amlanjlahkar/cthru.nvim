assert(vim.fn.has("nvim-0.10.0") == 1, "cthru: minimum neovim version 0.10.0 required!")

local defaults = require("cthru.defaults")

vim.g._cthru = false
vim.g._cthru_changed = false
vim.g.cthru_groups = vim.g.cthru_groups or defaults.hl_groups

if vim.fn.exists(":" .. defaults.usrcmd) ~= 2 then require("cthru").register_usrcmd({}) end

-- Make sure vim.g.colors_name is loaded properly
local timeout = 1000
vim.defer_fn(function()
    vim.g._cthru_color = vim.g.colors_name
end, timeout)

local augroup = vim.api.nvim_create_augroup("_cthru", { clear = true })

vim.api.nvim_create_autocmd("ColorSchemePre", {
    group = augroup,
    callback = function()
        vim.cmd.highlight("clear")
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    desc = "Maintain cthru state on changing colorschemes",
    group = augroup,
    callback = function()
        vim.defer_fn(function()
            vim.g._cthru_changed = vim.g._cthru_color ~= vim.g.colors_name
            if vim.g._cthru_changed then vim.g._cthru_color = vim.g.colors_name end
        end, timeout + 500)

        local color_same = require("cthru.utils").cmp_hl_color(defaults.cache_path)

        if not color_same or vim.g._cthru or vim.g._cthru_changed then
            local force_update = not color_same or vim.g._cthru_changed

            require("cthru.utils.cthru").init_cthru({
                hl_groups = vim.g.cthru_groups,
                force_update = force_update,
                toggle = false,
            })
        end
    end,
})
