Cthru exposes a global `:CthruToggle` user command which can be used to toggle the background color property of [certain](lua/cthru/defaults.lua#L3-L18) highlight groups.

![demo](assets/cthru_demo.gif)

---

## Installation and usage

> [!IMPORTANT]
> Neovim version 0.10.0 or higher required!

Install as any other normal plugin.

The `setup` method used for registering the user command expects a table with three keys, all of which are optional.

```lua
require("cthru").setup({
    cache_path = vim.fn.stdpath("data") .. "/cthru_cache.json", -- default cache location
    excluded_groups = {}, -- highlight groups to be excluded from default list
    additional_groups = {}, -- additional highlight groups to be included
})
```

## Plans

- [ ] Persistent highlight state between restarts
