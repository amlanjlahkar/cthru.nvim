local api = vim.api
local uv = vim.uv
local g = vim.g

local utils = {}

---Generate value to be mapped with `hl_group`
---@param hl_group string
---@return table
utils.gen_map_val = function(hl_group)
    local hl_opt = api.nvim_get_hl(0, { name = hl_group, create = false })
    return { hl_opt = hl_opt, use = false }
end

---Generate new highlight mapping based off of `hl_groups`
---@param hl_groups table
---@return table
utils.gen_new_map = function(hl_groups)
    local hl_map = {}
    for _, hlg in pairs(hl_groups) do
        local value = utils.gen_map_val(hlg)
        hl_map[hlg] = value
    end
    return { colorscheme = g.colors_name, hl_map = hl_map }
end

---Compare current/provided colorscheme with cached colorscheme
---@param cache_path string
---@param color? string Colorscheme to match against, `g:colors_name` if nil
---@return boolean #`true` if same, `false` otherwise
utils.cmp_hl_color = function(cache_path, color)
    assert(type(cache_path) == "string")

    color = color or g.colors_name

    ---@diagnostic disable-next-line: undefined-field
    if not uv.fs_access(cache_path, "R") then return true end

    local file = assert(io.open(cache_path))

    if file then
        local data = file:read("*l")
        local hl = vim.json.decode(data)
        file:close()
        return hl.colorscheme == color
    end

    return true
end

---Overwrite cthru cache
---@param path string Location of cthru cache
---@param hl_map string json encoded highlight mapping
utils.overwrite_cache = function(path, hl_map)
    local file = assert(io.open(path, "w"))
    if file then
        file:write(hl_map)
        file:close()
    end
end

---Compare highlight groups with cached groups. Alters the `use` attribute value of matching groups
---@param hl_groups table
---@param hl_map_cached table
---@param redefine? boolean Force redefine groups, default is `false`
---@return table #A modified copy of `hl_map_cached`
utils.cmp_hlmap = function(hl_groups, hl_map_cached, redefine)
    redefine = redefine or false

    local hl_map = vim.deepcopy(hl_map_cached, true)

    for _, hlg in pairs(hl_groups) do
        if not hl_map_cached[hlg] or redefine then
            local value = utils.gen_map_val(hlg)
            hl_map_cached[hlg] = value
            hl_map[hlg] = vim.deepcopy(value, true)
        end
        hl_map[hlg].use = true
    end

    return hl_map
end

return utils
