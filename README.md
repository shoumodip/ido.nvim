# ido.nvim
An Emacs inspired narrowing system for Neovim

![Ido Browse](img/browse.jpeg)

## Install
Use your plugin manager of choice to install this plugin

| Plugin manager                                    | Command                                |
| ------------------------------------------------- | -------------------------------------- |
| [Vim Plug](https://github.com/junegunn/vim-plug)  | `Plug 'ido-nvim/ido.nvim'`             |
| [Vundle](https://github.com/VundleVim/Vundle.vim) | `Plugin 'shoumodip/ido.nvim'`          |
| [Dein](https://github.com/Shougo/dein.vim)        | `call dein#add('ido-nvim/ido.nvim')`   |
| [Minpac](https://github.com/k-takata/minpac)      | `call minpac#add('ido-nvim/ido.nvim')` |

Or use the builtin packages feature

```console
$ cd ~/.config/nvim/pack/plugins/start
$ git clone https://github.com/ido-nvim/ido.nvim
$ git submodule update --init --recursive
```

## Usage
```vim
:lua print(require("ido").start({"red", "green", "blue"}))
```

## Keybindings
| Key                 | Description               |
| ------------------- | ------------------------- |
| <kbd>\<bs\></kbd>   | Delete character backward |
| <kbd>\<del\></kbd>  | Delete character forward  |
| <kbd>\<esc\></kbd>  | Quit                      |
| <kbd>\<cr\></kbd>   | Accept the selection      |
| <kbd>\<c-d\></kbd>  | Delete character forward  |
| <kbd>\<c-k\></kbd>  | Delete character backward |
| <kbd>\<c-f\></kbd>  | Move character forward    |
| <kbd>\<c-b\></kbd>  | Move character backward   |
| <kbd>\<a-f\></kbd>  | Move word forward         |
| <kbd>\<a-b\></kbd>  | Move word backward        |
| <kbd>\<a-d\></kbd>  | Delete word forward       |
| <kbd>\<a-k\></kbd>  | Delete word backward      |
| <kbd>\<a-bs\></kbd> | Delete word backward      |
| <kbd>\<c-a\></kbd>  | Move line backward        |
| <kbd>\<c-e\></kbd>  | Move line forward         |
| <kbd>\<c-n\></kbd>  | Select next item          |
| <kbd>\<c-p\></kbd>  | Select previous item      |

## Quick Start
| Command               | Description                                                                           |
| --------------------- | ------------------------------------------------------------------------------------- |
| `:Ido std.browse`     | Browse the filesystem                                                                 |
| `:Ido std.buffer`     | Switch buffers                                                                        |
| `:Ido std.filetypes`  | Switch filetypes for the current buffer                                               |
| `:Ido std.find_files` | Find files recursively under the current directory                                    |
| `:Ido std.git_files`  | Find files in a git repository                                                        |
| `:Ido std.git_diff`   | Find files with changes                                                               |
| `:Ido std.git_log`    | Open log for a commit, requires [vim-fugitive](https://github.com/tpope/vim-fugitive) |
| `:Ido std.git_status` | Find files with git changes                                                           |

**NOTE:** `:Ido <file>.<function>` is shorthand for `:lua require('ido.<file>').<function>()`

## Ido Browse
The `std.browse` function is a beast of a selector. It can traverse the
filesystem, create and open files. It makes use of a few extra keybindings to
achieve this.

| Key                | Description                                                                               |
| ------------------ | ----------------------------------------------------------------------------------------- |
| <kbd>\<bs\></kbd>  | If the query is empty, go back a directory. Otherwise normal behaviour                    |
| <kbd>/</kbd>       | If the query is empty, go to root. Otherwise enter the selected item if it is a directory |
| <kbd>~</kbd>       | If the query is empty, go to home. Otherwise normal behaviour                             |

The current directory of the browse function is displayed in the prompt.

**INFO:** The image at the top of this document is actually the `std.browse`
function in action

## Configuration
Ido is configured through a dedicated `setup` function. It accepts a table of
options.

| Option       | Type                      | Description                                 | Default                            |
| ------------ | ------------------------- | ------------------------------------------- | ---------------------------------- |
| `prompt`     | `string`                  | The prompt of the ido selector              | `>>>`                              |
| `ignorecase` | `boolean`                 | Whether matching should be case insensitive | `ignorecase` setting of Neovim     |
| `render`     | `function`                | The function used for rendering Ido         | `ido.internal.render`              |
| `mappings`   | `table[string]{function}` | The keybindings of Ido                      | As described [above](#Keybindings) |
| `hooks`      | `table[string]{function}` | The [hooks](#Hooks)                         | `{}`                               |

**NOTE:** The key to be bound to in the `mappings` option ***MUST BE ALL LOWER-CASE***

### Configuration Demo
```lua
local ido = require("ido")
ido.setup {
    prompt = "Ido: ",
    ignorecase = false,
    mappings = {
        ["<c-k>"] = ido.delete.line.backward
    }
}
```

**INFO:** Ido API described [here](#API).

## Temporary Configuration
Ido also supports temporary configuration, wherein the configuration lasts for
a single run of the selector. Such configuration are passed via the optional
second argument of `ido.start()`

### Temporary Configuration Demo
```lua
local ido = require("ido")
ido.start(vim.split(vim.fn.glob("**"), "\n"), {
    prompt = "Find Files: ",
    mappings = {
        ["<c-k>"] = ido.delete.line.backward
    }
})
```

## API
TBD
