assert(vim.fn.has("nvim-0.10.0") == 1, "cthru: minimum neovim version 0.10.0 required!")

local g = vim.g
local api = vim.api

g._cthru = false
g.cthru_groups = require("cthru.default_groups")
g.cthru_defer_count = 100

local color_changed = false
local default_color = nil
local prev_color = nil
local cthru = require("cthru")

-- Global table to store highlight group attributes
Cthru_hl_map = {}

local function reset_hl_map()
    for _, hlg in pairs(g.cthru_groups) do
        Cthru_hl_map[hlg] = api.nvim_get_hl(0, { name = hlg })
    end
end

local augroup = api.nvim_create_augroup("_cthru", { clear = true })

api.nvim_create_autocmd("ColorSchemePre", {
    desc = "Clear custom highlight groups before setting a colorscheme",
    group = augroup,
    callback = function(opts)
        color_changed = prev_color ~= opts.match

        if color_changed then vim.cmd.highlight("clear") end

        if not prev_color or color_changed then prev_color = opts.match end
    end,
})

api.nvim_create_autocmd("ColorScheme", {
    desc = "Maintain cthru state on changing colorschemes",
    group = augroup,
    callback = function(opts)
        if not default_color then default_color = g.colors_name end

        if vim.v.vim_did_enter > 0 and color_changed then reset_hl_map() end

        if g._cthru then
            if opts.match == default_color then
                -- stylua: ignore
                vim.defer_fn(function() cthru.hook_cthru(false) end, g.cthru_defer_count)
            else
                cthru.hook_cthru(false)
            end
        end
    end,
})

-- Populate the highlight table at startup
vim.defer_fn(function()
    if vim.tbl_isempty(Cthru_hl_map) then reset_hl_map() end
end, g.cthru_defer_count)

cthru.register_usrcmd()
