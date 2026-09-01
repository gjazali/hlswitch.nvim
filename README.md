# HlSwitch

A light switch for syntax highlighting in Neovim.

This plugin offers three modes:

| Mode      | What is highlighted            |
| --------- | ------------------------------ |
| `on`      | everything                     |
| `off`     | nothing                        |
| `comment` | comments, and nothing else     |

## Requirements

Requires Neovim 0.10 or newer. Developed and tested against 0.11.

Treesitter is optional. If a Treesitter parser exists, HlSwitch will drive it.

## Installation

With [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'gjazali/hlswitch.nvim'
```

Or from a local checkout:

```vim
Plug '~/Downloads/hlswitch.nvim'
```

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ 'gjazali/hlswitch.nvim', opts = {} }
```

No `setup()` call is needed.

## Commands

| Command             | Effect                                             |
| ------------------- | -------------------------------------------------- |
| `:HlSwitchOn`       | Highlight everything in this buffer                |
| `:HlSwitchOff`      | Highlight nothing in this buffer                   |
| `:HlSwitchComment`  | Highlight comments in this buffer and nothing else |
| `:HlSwitch {mode}`  | Set this buffer to `off`, `on` or `comment`        |
| `:HlSwitchTSOn`     | Start the Treesitter highlighter, mode unchanged   |
| `:HlSwitchTSOff`    | Stop the Treesitter highlighter, mode unchanged    |

These abbreviations can go in your Neovim config:

```vim
cnoreabbrev <expr> hn ((getcmdtype() is# ':' && getcmdline() is#
      \ 'hn')?('HlSwitchOn'):('hn'))
cnoreabbrev <expr> hf ((getcmdtype() is# ':' && getcmdline() is#
      \ 'hf')?('HlSwitchOff'):('hf'))
cnoreabbrev <expr> hc ((getcmdtype() is# ':' && getcmdline() is#
      \ 'hc')?('HlSwitchComment'):('hc'))
```

## Configuration

Either through `setup()`:

```lua
require('hlswitch').setup({
  default = 'on',
  default_by_filetype = { checkhealth = 'on', log = 'off' },
  no_filetype_default = 'off',
})
```

Or through `g:hlswitch`, read at `VimEnter` when `setup()` is not called:

```vim
let g:hlswitch = #{
  \ default: 'on',
  \ default_by_filetype: #{ checkhealth: 'on' },
  \ no_filetype_default: 'off',
\ }
```

Modes can be numbers (`0`, `1`, `2`) or names (`'off'`, `'on'`,
`'comment'`).

## Statusline

```lua
sections = {
  lualine_x = { function() return require('hlswitch').status() end },
}
```

The mode is also in `b:hlswitch_mode` as a number, for Vimscript.

See `:help hlswitch` for full documentation.
