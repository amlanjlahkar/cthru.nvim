local api = vim.api

local utils = {}

---Generate value to be mapped with `hl_group`
---@param hl_group string
---@return table
function utils.gen_hlmap_val(hl_group)
    local hl_opt = api.nvim_get_hl(0, { name = hl_group, create = false })
    return { hl_opt = hl_opt, use = false }
end

---Generate new highlight mapping based off of `hl_groups`
---@param hl_groups table
---@return table
function utils.gen_new_hlmap(hl_groups)
    local hl_map = {}
    for _, hlg in pairs(hl_groups) do
        local value = utils.gen_hlmap_val(hlg)
        hl_map[hlg] = value
    end
    return hl_map
end

---Overwrite cthru cache
---@param path string Location of cthru cache
---@param hl_map string json encoded highlight mapping
function utils.overwrite_cache(path, hl_map)
    local file = assert(io.open(path, "w"))
    if file then
        file:write(hl_map)
        file:close()
    end
end

---Compare highlight groups with cached groups
---@param hl_groups table
---@param hl_map_cached table
---@return boolean update_cache
---@return table #A modified copy of `hl_map_cached`
function utils.cmp_hlmap(hl_groups, hl_map_cached)
    local update_cache = false

    local hl_map = vim.deepcopy(hl_map_cached, true)

    for _, hlg in pairs(hl_groups) do
        if not hl_map_cached[hlg] then
            local value = utils.gen_hlmap_val(hlg)
            hl_map_cached[hlg] = value
            hl_map[hlg] = vim.deepcopy(value, true)
            if not update_cache then update_cache = true end
        end
        hl_map[hlg].use = true
    end

    return update_cache, hl_map
end

return utils
