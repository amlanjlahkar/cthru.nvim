local g = vim.g
local set_hl = vim.api.nvim_set_hl

local M = {}

---@class CThruOpts
---@field toggle boolean #Toggle cthru state

---@param opts CThruOpts
M.hook_cthru = function(opts)
    assert(type(opts.toggle) == "boolean")

    HlMap = HlMap or {}

    if g._cthru_col_changed then
        for _, hlg in pairs(g.cthru_groups) do
            HlMap[hlg] = vim.api.nvim_get_hl(0, { name = hlg })
        end
    end

    if opts.toggle then g._cthru = not g._cthru end

    for _, hlg in pairs(g.cthru_groups) do
        if g._cthru then
            set_hl(0, hlg, vim.tbl_extend("keep", { bg = "NONE", ctermbg = "NONE" }, HlMap[hlg]))
        else
            set_hl(0, hlg, HlMap[hlg])
        end
    end

    g._cthru_col_changed = false
end

return M
