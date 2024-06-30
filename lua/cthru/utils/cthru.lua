local set_hl = vim.api.nvim_set_hl
local utils = require("cthru.utils")
local g = vim.g

local M = {}

---@class CthruInitOpts
---@field force_update? boolean #Default is false
---@field toggle boolean #Toggle cthru state

---@param opts CthruInitOpts
M.update_cthru = function(opts)
    assert(type(opts.toggle) == "boolean")

    local force_update = opts.force_update or false
    local hl_groups = g.cthru_groups
    local cache_path = require("cthru.defaults").cache_path

    local hl = {}
    local write_cache = false

    ---@diagnostic disable-next-line: undefined-field
    if not vim.uv.fs_access(cache_path, "R") or force_update then
        hl = utils.gen_new_hl_cache(hl_groups)
        write_cache = true
    end

    if not force_update and vim.tbl_isempty(hl) then
        local file = assert(io.open(cache_path))
        if file then
            local data = file:read("*l")
            hl = vim.json.decode(data)
            file:close()
        end
    end

    local hl_map_copy = utils.cmp_hlmap(hl_groups, hl.hl_map, force_update)

    if opts.toggle then g._cthru = not g._cthru end

    for hlg, val in pairs(hl_map_copy) do
        if g._cthru then
            local hl_opt = vim.tbl_extend("keep", { bg = "NONE", ctermbg = "NONE" }, val.hl_opt)
            if val.use then set_hl(0, hlg, hl_opt) end
        else
            set_hl(0, hlg, val.hl_opt)
        end
    end

    if write_cache or force_update then
        vim.schedule(function()
            utils.overwrite_cache(cache_path, vim.json.encode(hl))
        end)
    end
end

return M
