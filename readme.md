Cthru provides a global **"CthruToggle"** user command that toggles the background color property of [certain](lua/cthru/default_groups.lua) highlight groups.

## Installation and usage

> [!IMPORTANT]
> Neovim version 0.10.0 or higher required!

Install as any other normal plugin.

In order to register the user command the `configure` method exposed by the `cthru` module is needed to be called.
Optionally a table can be passed to the method to alter the plugin's default behavior. The available options are:

```lua
require("cthru").configure({
    excluded_groups = {}, -- table? Highlight groups to be excluded from default list
    additional_groups = {}, -- table? Additional highlight groups to be included
    remember_state = ???, -- boolean? Remember previous cthru state. Default is `true`
})
```

Additionally the global variable `g:cthru_groups` can also be used to extend the default list of highlight groups.

```lua
if package.loaded["cthru"] then
    local custom_hl_groups = {} -- append extra groups
    vim.g.cthru_groups = vim.list_extend(vim.g.cthru_groups, custom_hl_groups)
end
```

## Caveats
- Sometimes other plugins or other parts of the configuration might also utilize the `ColorScheme` event to listen for colorscheme changes and modify the highlight groups of the default colorscheme set by the user. To prevent race conditions in such scenarios, cthru delays calling its main function until a specific timeout period passes. This timeout duration can be adjusted using the `g:cthru_defer_count` variable, which defaults to 10(ms). Consider reducing it or set to 0 if no such parallel events are to occur, or increasing it if some groups are being incorrectly interpreted.

- Although it is possible to lazyload Cthru, e.g., on the "CthruToggle" command, I do not recommend doing so; primarily because of three reasons:
    - `remember_state = true` only works when Cthru is allowed to load at startup
    - Incorrect identification of default color set by the user, the significance of which is described in the previous point(this can be solved by introducing another variable/option but I don't think any more changes to the codebase, solely because of this, is worth it, see next point)
    - Cthru takes almost negligible amount of time to load(~1ms)

## Plans

- [x] Persistent highlight state between restarts
