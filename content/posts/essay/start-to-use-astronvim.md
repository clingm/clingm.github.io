---
title: Start to Use AstroNvim
date: 2023-12-31T14:32:11+08:00
tags:
  - Essay
mathjax: false
description: 
toc: true
---

AstroNvim is an aesthetic and feature-rich Neovim configuration that focuses on extensibility and usability.

最近把原先的LzayVim换成了AstroNvim，用了一段时间感觉还不错

## why AstroNvim

首先引用以下AstroNvim官网的话

> We found other Neovim configurations either being powerful out of the box but hard to customize, or easy to customize but minimal out of the box functionality. AstroNvim aims to find the middle ground with a great out of the box experience while empowering the user to make tweaks where they want.

在熟悉AstroNvim的配置方法后感觉确实如此，AstroNvim做到了方便配置和功能足够多，开箱即用这两点。

先前使用的LazyVim是极简的配置，但是对于我这种仅仅是使用Neovim作为主要编辑器的用户还是有点过于简单了。

## How AstroNvim Work

在这一节我会简单的介绍以下AstroNvim客制化的一些东西（以我自己粗浅的理解

在安装之后会得到这么个目录结构

```shell
./lua
├── astronvim
│   ├── icons
│   └── utils
│       └── status
├── plugins
│   └── configs
└── resession
    └── extensions
```

`astronvim` 目录下的是AstroNvim客制化的东西，`plugins` 目录下是默认的插件配置。 这里主要介绍以下AstroNvim是如何加载我们用户的配置的。

首先在`astronvim/lazy.lua`文件中有如下代码来加载user config，

```lua
local user_plugins = astronvim.user_opts "plugins"
for _, config_dir in ipairs(astronvim.supported_configs) do
  if vim.fn.isdirectory(config_dir .. "/lua/user/plugins") == 1 then user_plugins = { import = "user.plugins" } end
end

local spec = astronvim.updater.options.pin_plugins and { { import = astronvim.updater.snapshot.module } } or {}
vim.list_extend(spec, { { import = "plugins" }, user_plugins })
```

再来看`user_opts函数`

```lua
--- User configuration entry point to override the default options of a configuration table with a user configuration file or table in the user/init.lua user settings
---@param module string The module path of the override setting
---@param default? any The default value that will be overridden
---@param extend? boolean # Whether extend the default settings or overwrite them with the user settings entirely (default: true)
---@return any # The new configuration settings with the user overrides applied
function astronvim.user_opts(module, default, extend)
  -- default to extend = true
  if extend == nil then extend = true end
  -- if no default table is provided set it to an empty table
  if default == nil then default = {} end
  -- try to load a module file if it exists
  local user_module_settings = load_module_file("user." .. module)
  -- if no user module file is found, try to load an override from the user settings table from user/init.lua
  if user_module_settings == nil then user_module_settings = user_setting_table(module) end
  -- if a user override was found call the configuration engine
  if user_module_settings ~= nil then default = func_or_extend(user_module_settings, default, extend) end
  -- return the final configuration table with any overrides applied
  return default
end
```

再向上看`load_module_file`, `user_setting_table`, `func_or_extend`

```lua
--- Looks to see if a module path references a lua file in a configuration folder and tries to load it. If there is an error loading the file, write an error and continue
---@param module string The module path to try and load
---@return table|nil # The loaded module if successful or nil
local function load_module_file(module)
  -- placeholder for final return value
  local found_file = nil
  -- search through each of the supported configuration locations
  for _, config_path in ipairs(astronvim.supported_configs) do
    -- convert the module path to a file path (example user.init -> user/init.lua)
    local module_path = config_path .. "/lua/" .. module:gsub("%.", "/") .. ".lua"
    -- check if there is a readable file, if so, set it as found
    if vim.fn.filereadable(module_path) == 1 then found_file = module_path end
  end
  -- if we found a readable lua file, try to load it
  local out = nil
  if found_file then
    -- try to load the file
    local status_ok, loaded_module = pcall(require, module)
    -- if successful at loading, set the return variable
    if status_ok then
      out = loaded_module
    -- if unsuccessful, throw an error
    else
      vim.api.nvim_err_writeln("Error loading file: " .. found_file .. "\n\n" .. loaded_module)
    end
  end
  -- return the loaded module or nil if no file found
  return out
end
```

```lua
--- Search the user settings (user/init.lua table) for a table with a module like path string
-- @param module the module path like string to look up in the user settings table
-- @return the value of the table entry if exists or nil
local function user_setting_table(module)
  -- get the user settings table
  local settings = user_settings or {}
  -- iterate over the path string split by '.' to look up the table value
  for tbl in string.gmatch(module, "([^%.]+)") do
    settings = settings[tbl]
    -- if key doesn't exist, keep the nil value and stop searching
    if settings == nil then break end
  end
  -- return the found settings
  return settings
end
```

```lua
--- Main configuration engine logic for extending a default configuration table with either a function override or a table to merge into the default option
-- @param overrides the override definition, either a table or a function that takes a single parameter of the original table
-- @param default the default configuration table
-- @param extend boolean value to either extend the default or simply overwrite it if an override is provided
-- @return the new configuration table
local function func_or_extend(overrides, default, extend)
  -- if we want to extend the default with the provided override
  if extend then
    -- if the override is a table, use vim.tbl_deep_extend
    if type(overrides) == "table" then
      local opts = overrides or {}
      default = default and vim.tbl_deep_extend("force", default, opts) or opts
    -- if the override is  a function, call it with the default and overwrite default with the return value
    elseif type(overrides) == "function" then
      default = overrides(default)
    end
  -- if extend is set to false and we have a provided override, simply override the default
  elseif overrides ~= nil then
    default = overrides
  end
  -- return the modified default table
  return default
end
```

其实这些函数注释写的也很清楚，只需要在`user/plugins`目录创建对应于`lua/plugins`目录中插件相对应的文件 这里就可以自动寻找这些文件并且将其中的内容覆盖在默认的配置中。

## Make AstroNvim More Powerful

安装几个插件让AstroNvim更加强大

### markdown-preview

source : [https://github.com/iamcco/markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim)

`user/plugins/markdown-preview.lua`

```lua
return { -- install without yarn or npm { "iamcco/markdown-preview.nvim", cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" }, ft = { "markdown" }, build = function() vim.fn["mkdp#util#install"]() end, } }
```

### ToggleTerm

source : [https://github.com/akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)

虽然AstroNvim已经内置了ToggleTerm作为默认的Ternimal工具，但是并没有对其做custom config 因为我平时使用fish作为自己的shell（但是系统默认的shell还是bash，所以这里就只做了shell的更改。

`user/plugins/toggleterm.lua`

```lua
return{ "akinsho/toggleterm.nvim", opts = { shell = "/bin/fish", } }
```

## Make AstroNvim More Beautiful

### lualine

source : [https://github.com/nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)

AstroNvim默认的状态栏是使用[heirline](https://github.com/rebelot/heirline.nvim)构建的， 但是lualine更加好看和方便配置。

`user/plugins/ui.lua`

```lua
{ 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, event = "BufEnter", config = function() require('lualine').setup { options = { theme = "auto" } } end, },
```

### mini.indentscope

source : [https://github.com/echasnovski/mini.indentscope](https://github.com/echasnovski/mini.indentscope)

缩进的高亮显示

`user/plugins/ui.lua`

```lua
-- Active indent guide and indent text objects. When you're browsing -- code, this highlights the current level of indentation, and animates -- the highlighting. { "echasnovski/mini.indentscope", version = false, -- wait till new 0.7.0 release to put it back on semver event = "User AstroFile", opts = { -- symbol = "▏", symbol = "│", options = { try_as_border = true }, }, init = function() vim.api.nvim_create_autocmd("FileType", { pattern = { "help", "startify", "aerial", -- "alpha", "dashboard", "lazy", "neogitstatus", "NvimTree", "neo-tree", "Trouble", }, callback = function() vim.b.miniindentscope_disable = true end, }) end, },
```

### heirline-winbar

类似vscode里winbar的效果。

`user/plugins/heirline.lua`

```lua
return { { "rebelot/heirline.nvim", opts = function(_, opts) local status = require "astronvim.utils.status" opts.winbar = { -- create custom winbar -- store the current buffer number init = function(self) self.bufnr = vim.api.nvim_get_current_buf() end, fallthrough = false, -- pick the correct winbar based on condition -- inactive winbar { condition = function() return not status.condition.is_active() end, -- show the path to the file relative to the working directory status.component.separated_path { path_func = status.provider.filename { modify = ":.:h" } }, -- add the file name and icon status.component.file_info { file_icon = { hl = status.hl.file_icon "winbar", padding = { left = 0 } }, file_modified = false, file_read_only = false, hl = status.hl.get_attributes("winbarnc", true), surround = false, update = "BufEnter", }, }, -- active winbar { -- show the path to the file relative to the working directory status.component.separated_path { path_func = status.provider.filename { modify = ":.:h" } }, -- add the file name and icon status.component.file_info { -- add file_info to breadcrumbs file_icon = { hl = status.hl.filetype_color, padding = { left = 0 } }, file_modified = false, file_read_only = false, hl = status.hl.get_attributes("winbar", true), surround = false, update = "BufEnter", }, -- show the breadcrumbs status.component.breadcrumbs { icon = { hl = true }, hl = status.hl.get_attributes("winbar", true), prefix = true, padding = { left = 0 }, }, }, } return opts end, }, }
```
