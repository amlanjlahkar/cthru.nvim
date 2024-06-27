local set_hl = vim.api.nvim_set_hl
local utils = require("cthru.utils")

local M = {}

---@param cache_path string
---@param hl_groups table
M.init_cthru = function(cache_path, hl_groups)
    assert(type(hl_groups) == "table")

    local hl_map = {}
    local update_cache = false

    ---@diagnostic disable-next-line: undefined-field
    if not vim.uv.fs_access(cache_path, "R") then
        hl_map = utils.gen_new_hlmap(hl_groups)
        update_cache = true
    end

    if not next(vim.g._cthru_cache) then
        if next(hl_map) then
            vim.g._cthru_cache = hl_map
        else
            local file = assert(io.open(cache_path))
            if not file then return end

            local cached_data = file:read("*l")
            hl_map = vim.json.decode(cached_data)
            vim.g._cthru_cache = hl_map

            file:close()
        end
    else
        hl_map = vim.g._cthru_cache
    end

    local hl_map_copy = {}
    update_cache, hl_map_copy = utils.cmp_hlmap(hl_groups, hl_map)

    vim.g._cthru = not vim.g._cthru

    for hlg, val in pairs(hl_map_copy) do
        if vim.g._cthru then
            local hl_opt = vim.tbl_extend("keep", { bg = "NONE", ctermbg = "NONE" }, val.hl_opt)
            if val.use then set_hl(0, hlg, hl_opt) end
        else
            set_hl(0, hlg, val.hl_opt)
        end
    end

    if update_cache then
        vim.g._cthru_cache = hl_map
        vim.schedule(function()
            utils.overwrite_cache(cache_path, vim.json.encode(hl_map))
        end)
    end
end

return M
