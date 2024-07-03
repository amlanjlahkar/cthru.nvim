Cthru exposes a global `:CthruToggle` user command which can be used to toggle the background color property of [certain](lua/cthru/defaults.lua#L4) highlight groups.

![demo](assets/cthru_demo.gif)

---

## Installation and usage

> [!IMPORTANT]
> Neovim version 0.10.0 or higher required!

Install as any other normal plugin.

An optional `configure` method can be used for altering the default behavior. The available options are:

```lua
require("cthru").configure({
    excluded_groups = {}, -- table? highlight groups to be excluded from default list
    additional_groups = {}, -- table? additional highlight groups to be included
    remember_state = nil, -- boolean? remember previous cthru state(unset by default)
})
```
> [!NOTE]
> Avoid lazyloading cthru if `remember_state` is set to `true`

Additionaly the global variable `g:cthru_groups` can also be used to extend the default list without needing to call `configure`.

```lua
if package.loaded["cthru"] then
    local custom_hl_groups = {} -- append extra groups
    vim.g.cthru_groups = vim.list_extend(vim.g.cthru_groups, custom_hl_groups)
end
```

## Caveats
- Sometimes other plugins or other parts of the configuration might also utilize the `ColorScheme` event to listen for colorscheme changes and modify the highlight groups of the default colorscheme set by the user. To prevent race conditions in such scenarios, cthru delays calling its main function until a specific timeout period passes. This timeout duration can be adjusted using the `g:cthru_defer_count` variable, which defaults to 10(ms). Consider reducing it or set to 0 if no such parallel events are to occur, or increasing it if some groups are being incorrectly interpreted.

## Plans

- [x] Persistent highlight state between restarts
