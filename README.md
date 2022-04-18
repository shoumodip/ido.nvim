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

**NOTE:** `:Ido <file>.<function>` is the same as `:lua require('ido.<file>').<function>()`

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

| Option         | Type                      | Description                                           | Default                            |
| -------------- | ------------------------- | ----------------------------------------------------- | ---------------------------------- |
| `prompt`       | `string`                  | The prompt of the ido selector                        | `>>>`                              |
| `ignorecase`   | `boolean`                 | Whether matching should be case insensitive           | `ignorecase` setting of Neovim     |
| `accept_query` | `boolean`                 | If no items match, accept the query on pressing enter | false                              |
| `render`       | `function`                | The function used for rendering Ido                   | `ido.internal.render`              |
| `mappings`     | `table[string]{function}` | The keybindings of Ido                                | As described [above](#Keybindings) |
| `hooks`        | `table[string]{function}` | The [hooks](#Hooks)                                   | `{}`                               |

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

## Hooks
Hooks are like `autocmd` in Vim. They get executed on certain events.

| Event                     | Description                                                    |
| ------------------------- | -------------------------------------------------------------- |
| `delete_forward_nothing`  | If a forward delete operation was made with nothing to delete  |
| `delete_backward_nothing` | If a backward delete operation was made with nothing to delete |
| `filter_items`            | Just before filtering the items                                |
| `event_start`             | Just before the event loop starts                              |
| `event_stop`              | Just after the event loop stops                                |

## API
```lua
local ido = require("ido")
```

This section describes the variables and functions exposed through the `ido`
module.

### `ido.state.active`
Whether the filtering is active.

```lua
ido.state.active = false
```

### `ido.state.items`
The items being filtered upon.

```lua
ido.state.items = {"red", "green", "blue"}
```

### `ido.state.query.lhs`
The part of the query on the left side of the cursor.

```lua
ido.state.query.lhs = "~"
```

### `ido.state.query.rhs`
The part of the query on the right side of the cursor.

```lua
ido.state.query.rhs = "/"
```

### `ido.state.modified`
Whether the filtered results need to be re-filtered.

```lua
ido.state.modified = true
```

### `ido.state.results`
The items which match the query.

```lua
ido.state.results = vim.split(vim.fn.glob("**"), "\n")
```

### `ido.state.current`
The current selected item in the results.

```lua
print(ido.state.results[ido.state.current])
```

### `ido.state.options`
The temporary options.

```lua
ido.state.options = {
    prompt = "Browse: "
}
```

### `ido.internal.get(option)`
Get the value of the option named `option`.

```lua
print(ido.internal.get("prompt"))
```

### `ido.internal.set(option, value)`
Set the value of the option named `option` to `value`.

```lua
ido.internal.set("prompt", "Filter: ")
```

### `ido.internal.key(key)`
Get the function associated with `key`.

```lua
ido.internal.key("<esc>")()
```

### `ido.internal.hook(name)`
Execute the hook named `name`.

```lua
ido.internal.hook("event_start")
```

### `ido.internal.query()`
Get the current query.

```lua
if ido.internal.query() == "yes" then
    ido.internal.done() -- Same as pressing enter
end
```

### `ido.internal.insert(char)`
Insert a character into the query.

```lua
ido.internal.insert('a')
```

### `ido.motion.define(name, action)`
Define motion and delete operations called `name` with a forward action of
`action.forward` and backward action of `action.backward`.

The following operations will be generated.

| Operation                    | Description                                           |
| ---------------------------- | ----------------------------------------------------- |
| `ido.motion.<name>.forward`  | The forward motion, basically `action.forward`        |
| `ido.motion.<name>.backward` | The backward motion, basically `action.backward`      |
| `ido.delete.<name>.forward`  | Delete the query range covered by the forward motion  |
| `ido.delete.<name>.backward` | Delete the query range covered by the backward motion |

```lua
ido.motion.define("two_char", {
    forward = function ()
        if ido.state.query.rhs:len() > 1 then
            ido.state.query.lhs = ido.state.query.lhs..ido.state.query.rhs:sub(1, 2)
            ido.state.query.rhs = ido.state.query.rhs:sub(3)
        end
    end,

    backward = function ()
        if ido.state.query.lhs:len() > 1 then
            ido.state.query.rhs = ido.state.query.lhs:sub(-2)..ido.state.query.rhs
            ido.state.query.lhs = ido.state.query.lhs:sub(1, -3)
        end
    end
})

ido.motion.two_char.forward()
ido.delete.two_char.backward()
```

### `ido.internal.match(query, item)`
Get the fuzzy match positions and the score for finding `query` in `item`.

```lua
local positions, score = ido.internal.match("foo", "foobar")
```

### `ido.internal.filter()`
Filter the results from the items.

```lua
ido.internal.filter()
```

### `ido.internal.keystring(key, inside)`
Convert `key` in format of `getchar()`, into string representing vim mapping
syntax.

If optional argument `inside` is truthy, it means this function has been called
recursively.

```lua
print(ido.internal.keystring(112))
```

### `ido.internal.render()`
The default renderer of Ido.

```lua
ido.internal.render()
```

### `ido.stop()`
Stop the Ido event loop. Same as pressing `<esc>`.

```lua
ido.internal.stop()
```

### `ido.done()`
Stop the Ido event loop and accept the selected item. Same as pressing `<cr>`.

```lua
ido.internal.done()
```

### `ido.next()`
Select the next result. If there is no next item, wrap around to the first
result.

```lua
ido.internal.next()
```

### `ido.prev()`
Select the previous result. If there is no previous item, wrap around to the
last result.

```lua
ido.internal.prev()
```

### `ido.start(items, init)`
Start the Ido selector with items from `items` and optional argument `init`
providing the temporary configuration.

- Returns `nil` if `<esc>` was pressed (ie, `ido.action.quit()` was called).
- Returns the selected item if `<cr>` was pressed (ie, `ido.action.done()` was called).

```lua
local file = require("ido").start(vim.split(vim.fn.glob("**"), "\n"))
if file then
    vim.cmd("edit "..file)
end
```
