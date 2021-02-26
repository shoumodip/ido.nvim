# Variables and Options
This can be divided into two groups -- the **variables** and the **options**.

- Variables are used by Ido internally and are not meant to be changed permanently
- Options on the other hand are supposed to be changed by the user

Even this can be divided into two groups -- temporary or *sandboxed* and permanent.

## How it is documented
`NAME` `DOCUMENTATION`. `TYPE` (`DEFAULT VALUE`)

## Variables
- `before_cursor` The query text before the cursor. String (`""`)

- `after_cursor` The query text after the cursor. String (`""`)

- `items` The list of items to filter from. Table (`{}`)

- `results` The list of results, a.k.a items which match the pattern. Table (`{}`)

- `selected` The index of the selected item. Number (`0`)

- `suggestion` The suggestion text. String (`""`)

- `bindings` The key bindings converted to keycodes. Table (`{}`)

- `looping` Whether the event loop of Ido is on. Boolean (`false`)

## Options
- `layout` The layout used by Ido. Table (`ido.layouts.default`)

- `prompt` The prompt of Ido. String (`>>>`)

- `keys` The keybindings of Ido in `key-notation` format, *NO KEYCHORDS ALLOWED*. Table

```lua
{
   ["<Right>"] = "stdlib.cursor.forward",
   ["<Left>"] = "stdlib.cursor.backward",

   ["<C-f>"] = "stdlib.cursor.forward",
   ["<C-b>"] = "stdlib.cursor.backward",

   ["<C-Right>"] = "stdlib.cursor.forward_word",
   ["<C-Left>"] = "stdlib.cursor.backward_word",

   ["<M-f>"] = "stdlib.cursor.forward_word",
   ["<M-b>"] = "stdlib.cursor.backward_word",

   ["<C-a>"] = "stdlib.cursor.line_start",
   ["<C-e>"] = "stdlib.cursor.line_end",

   ["<C-n>"] = "stdlib.items.next",
   ["<C-p>"] = "stdlib.items.prev",

   ["<Down>"] = "stdlib.items.next",
   ["<Up>"] = "stdlib.items.prev",

   ["<BS>"] = "stdlib.delete.backward",
   ["<Del>"] = "stdlib.delete.forward",

   ["<Tab>"] = "main.accept_suggestion",
   ["<CR>"] = "main.accept_selected",
   ["<Esc>"] = "main.exit",
}
```

- `case_sensitive` Whether Ido should match case-sensitively. Boolean (`false`)

- `fuzzy_matching` Whether Ido should match fuzzily. Boolean (`true`)

- `word_separators` Characters which behave as word separators. String (`"|/?,.;: "`)

- `strict_match` Whether Ido should return "" if no results found, instead of the search query. Boolean (`false`)

## Sandboxed
When Ido starts it sandboxes all the options and variables. This is done to prevent weird errors (eg: User pressed `<C-c>`).

- `sandbox.vars` The variables
- `sandbox.opts` The options

### Permanent vs sandboxed
The decision should be simple.

- If you wish to make a permanent change to the default value as shown above, change the permanent variables and options.
- If you wish to make a temporary change for the current running Ido, change the sandboxed variables.

Both permanent and sandboxed variables and options have the same name and the same effect. So it's just a matter of
- `ido.vars.VAR_NAME` or `ido.opts.OPT_NAME` for permanent changes
- `ido.sandbox.vars.VAR_NAME` or `ido.sandbox.opts.OPT_NAME` for sandboxed changes

***NOTE:*** When Ido has started running, it will sandbox all the variables and options. So even if you make changes to the permanent versions, they will be ignored until the currently running Ido exits.

## How to use
Load the ido module into the variable `ido`

```lua
local ido = require("ido")
```

The aforementioned variables and options can now be accessed by

- `ido.vars` The permanent variables
- `ido.opts` The permanent options
- `ido.sandbox.vars` The sandboxed variables
- `ido.sandbox.opts` The sandboxed options

## `ido.opts.setup()`
If you wish to change `ido.opts` manually, go right ahead. However there is a helper function for doing just that with type checks to prevent errors. Here are the comparisons between the two approaches, use whatever way you wish to use.

```lua
-- With ido.opts.setup()
ido.opts.setup({
   prompt = "Match: ",
   keys = {
      ["<Right>"] = "stdlib.cursor.forward_word"
      ["<Left>"] = "stdlib.cursor.backward_word"
   },
})
```

```lua
-- Without ido.opts.setup()
ido.opts.prompt = "Match: "
ido.opts.keys["<Right>"] = "stdlib.cursor.forward_word"
ido.opts.keys["<Left>"] = "stdlib.cursor.backward_word"
```

## Keybindings
Keybindings are stored in `ido.opts.keys`. It is a table of mappings in the format

```
KEY = MAPPING
```

### `KEY`
Keybinding as described in `:h key-notation`. Note that keychords are **NOT ALLOWED**. All keybindings must consist of one key and one key only.

### `MAPPING`
- `stdlib.*` Execute a standard library function
- `main.*` Execute a ido main module function
- Anything else: Lua code

### Examples
- `stdlib.cursor.forward_word`
- `main.get_results`
- `require("ido.core.fzy").filter("yeah", {"awesome", "nice", "yeah"})`

### Functions
Keys can also be bound to functions

```lua
ido.opts.setup({
   keys = {

      -- Re-render on <C-b> because why not
      ["<C-b>"] = require("ido.core.ui").render
   },
})
```

Functional programming and the concept of functions as first-class citizens are game-changing, aren't they?

## Supplementary information
The information of options should be enough for most people. But if you **really** want to make the Ido experience *your own*, I would recommend you to take a look at the documentations for the [Standard library of Ido](stdlib.md) and the [main module](main.md).

## Also note
`require("ido.core.main").start()` can take variables and options as input. These will get stored in the sandbox.

```lua
require("ido.core.main").start({
   prompt = "Match: ",
   items = {"red", "green", "blue"}
})
```

This will start the ido interface with the items `red`, `green` and `blue`, with the prompt set to `Match: `.
