# zeal.nvim

Query and open Zeal docsets without leaving Neovim.

<image here>

# Requirements

- sqlite3
- [Zeal](https://zealdocs.org/) (docsets should be downloaded from the Zeal gui)
- lynx, w3m or any other terminal browser

## Optional Dependencies

- [snacks.nvim](https://github.com/folke/snacks.nvim) (for picker)
- [toggleterm](https://github.com/akinsho/toggleterm.nvim) (`:term` will be used otherwise)

> [!note]
> If opting not to use snacks, the standard `vim.ui.select()` function will be used
> 
> If this is true, a helper plugin like dressing.nvim is recommended

# Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "paradoxical-dev/zeal.nvim",
    event = "VeryLazy",
    opts = {
      -- config here
    }
}
```

>[!note]
> If using lazy, `opts` must at least be an empty table


# Configuration

Default options:

```lua
{
  docsets_path = vim.fn.expand("~/.local/share/Zeal/Zeal/docsets"), -- zeal docset locations
  browser = "w3m", -- can be any terminal browser
  split = "vsplit", -- used when use_toggleterm = false
  use_toggleterm = false,
  -- toggleterm specifc options
  -- see https://github.com/akinsho/toggleterm.nvim/tree/main
  toggleterm = {
  	direction = "vertical",
  	split_size = vim.o.columns * 0.5, -- when direction != float
    toggle_map = "<M-h>" -- toggle last opened zeal terem
  },
  picker = {
	type = "default", -- default | snacks
    -- snacks picker specific options.
    -- see https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
	snacks = {
	  layout = "default",
	},
  },
}
```

>[!tip]
> When setting the `toggle_map` option, it is necessary that the mapping also be accessible from within a terminal window

# Usage

## Commands

### `:Zeal`

Searches accross all available docsets, or a specific docset if supplied as an argument.

### `:ZealToggle`

Toggles the last opened zeal terminal

## Functions

### `require("zeal").search(docset)`

Same as the `:Zeal` command

## Advanced Usage

TODO
