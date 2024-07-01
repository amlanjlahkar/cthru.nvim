local g = vim.g
local set_hl = vim.api.nvim_set_hl

local M = {}

---@class CThruOpts
---@field reset? boolean #Reset global hl_map table. default is `false`
---@field toggle boolean #Toggle cthru state

---@param opts CThruOpts
M.hook_cthru = function(opts)
    assert(type(opts.toggle) == "boolean")

    local reset = opts.reset or false

    Cthru_hl_map = Cthru_hl_map or {}

    if reset then
        for _, hlg in pairs(g.cthru_groups) do
            Cthru_hl_map[hlg] = vim.api.nvim_get_hl(0, { name = hlg })
        end
    end

    if opts.toggle then g._cthru = not g._cthru end

    for _, hlg in pairs(g.cthru_groups) do
        if g._cthru then
            set_hl(0, hlg, vim.tbl_extend("keep", { bg = "NONE", ctermbg = "NONE" }, Cthru_hl_map[hlg]))
        else
            set_hl(0, hlg, Cthru_hl_map[hlg])
        end
    end
end

return M
