# Packages
> The ultra-extensible narrowing framework for Neovim. Originally inspired by the Emacs mode, Ido aims to make interactive matching a pleasure.

Ido is a narrowing *framework*, a library if you will. Therefore it can be used to create packages. A package is defined as a plugin which leverages the Ido library for creating useful functionality.

There are some helper functions in `ido.lua` for helping users to create packages, however those are just syntactic sugar. You can create packages without them also. Both ways are discussed in this manual. It's up to you to decide which approach you wish to take.

First of all load the packages API

```lua
local pkg = require("ido").pkg
```

## Package structure
A package is in essence a table consisting of 4 items

- `opts` The table of Ido options applied. Table, (`{}`) by default

- `bind` The table of options which decide how the package is bound to a key. Table, (`{}`) by default

- `disable` Disable certain options from being changed in the package by the `setup` function. Table, (`{}`) by default

- `main` The entry point of the package, like `main()` in C. Function, (`function () end`) by default

## Helper functions
## `pkg.new(NAME, OPTS)`
Create a new package.

- `name` The name of the package

- `opts` The table of options related to the package. See [Package structure](#package-structure) above.

If a package with that name exists already, it will throw an error.

## `pkg.setup(NAME, OPTS)`
Configure an existing package. It will change the options related to the package

- `name` The name of the package

- `opts` The table of options related to the package except `disable` and `main`. See [Package structure](#package-structure) above.

If a package with that name does not exist, it will throw an error.

## `pkg.run(NAME)`
Run a package. Basically it runs the `main` function defined in the package

- `name` The name of the package

## `pkg.start(OPTS)`
Syntactic sugar over the `ido.start()` function. Use this when creating a package instead of `ido.start()`

## `pkg.bind(NAME, OPTS)`
Bind the package with the name to a keybinding.

- `name` The name of the package

- `opts` The options related to the keybinding

A keybinding consists of 5 options.
- `key` The key in Vim notation (`:h key-notation`). **String**. Mandatory

- `mode` The mode in `vim.api.nvim_set_keymap()` notation. **String**. Defaults to `n`

- `noremap` Whether the mapping should be non-recursive. **Boolean**. Defaults to `true`

- `silent` Whether the mapping is silent or not. **Boolean**. Defaults to `true`

- `buffer` Whether the mapping is local to the current buffer. **Boolean**. Defaults to `false`

## Example
Let's create a package to open any git file

The entry point for the package

```lua
local function git_files()

   -- Check if the current directory is a git repo
   if os.execute("git rev-parse --is-inside-work-tree 2>/dev/null") ~= 0 then
      vim.cmd("echohl ErrorMsg | echo 'Not a git repository!' | echohl Normal")
      return ""
   end

   -- Get the file
   -- Try to use `pkg.start()` in packages as shown here instead of `ido.start()`
   local file = pkg.start({
      prompt = "Git files: ",
      items = vim.fn.systemlist("git ls-files")
   })

   -- If the file name not empty, edit it
   if #file > 0 then
      file = vim.loop.cwd():gsub("/$", "").."/"..file

      vim.cmd("edit"..file:gsub("'", "\\'"))
   end
end
```

Finally create the package

```lua
pkg.new("git_files", {

   -- The entry point of the function. MANDATORY
   main = git_files,

   -- To not disable anything just don't pass the disable table in the options
   -- This is optional
   disable = {

      -- Disable the prompt from being changed by `pkg.setup()`
      -- BTW if you enter an invalid option here, `pkg.new()` will complain
      "prompt",
   },

   -- Ido options to set in the sandbox. Optional
   opts = {

      -- Custom layout you created
      -- BTW if you enter an invalid layout here, `pkg.new()` will complain
      layout = "vertical",
   },

   -- To not bind it to anything just don't pass the bind table in the options
   -- This is optional
   bind = {

      -- Bind it to <Leader>gf
      key = "<Leader>gf",

      -- The following settings are optional. Here the default values are given
      mode = "n",
      noremap = true,
      silent = true,
      buffer = true,
   },
})
```

Press `<Leader>gf` in Normal mode or whatever mode you set it to.

What does this package do? It checks if the current directory is in a git repo.
- If it isn't, it will just output an error message
- If it is, it will start Ido with the output of `git ls-files` as the items
- On selecting an item, it will open the file in a new buffer

Now let's customize this package a bit *without* changing the package itself.

```lua
pkg.setup("git_files", {
   bind = {

      -- Make it an insert mode binding also
      mode = "i",

      -- Changed the insert mode binding, defaults to the binding set
      -- earlier, a.k.a `<Leader>gf`

      bind = "<C-x><M-g><C-f>", -- RMS is proud of you
   },

   opts = {

      -- Use the default layout, not vertical
      layout = "default",
   },
})
```

Try it now. Press `<Leader>gf` in insert mode.

Remember when we set `prompt` to be a disabled option? Let's find out what it means to be a disabled option.

```
pkg.setup("git_files", {
   opts = {
      prompt = "Git: ",
   },
})
```

You tried to change a disabled option, `pkg.setup()` complained. As simple as that.

## Manual approach
Let's create a package without the helper functions

The main function remains the same.

```lua

-- Every single option which can be present in a package is mandatory here
pkg.list.git_files = {
   main = git_files,

   -- To not bind it to any key just leave it empty: {}
   bind = {

      -- All the keybinding options are mandatory here, no automatic fallback
      key = "<Leader>gf",
      mode = "n",
      noremap = true,
      silent = true,
      buffer = true,
   },

   -- Empty table means no disabled options: {}
   disable = {
      "prompt",
   },

   -- Empty table means no package options: {}
   opts = {
      layout = "vertical",
   },
}
```

Now set the keybinding. There are two ways you can do this

```lua
-- With `pkg.bind()`

pkg.bind("git_files", pkg.git_files.bind)
```

```lua
-- Without `pkg.bind()`

vim.api.nvim_set_keymap(
   pkg.git_files.opts.mode,
   pkg.git_files.opts.key,

   "<Esc>:lua require('ido').pkg.run('"..name:gsub("'", "\\'").."')<CR>",

   {
      noremap = pkg.git_files.opts.noremap,
      silent = pkg.git_files.opts.silent,
   })
```

Customize the package

You can use `pkg.setup()` or the manual approach

```lua
-- Disabled settings have no effect this way
pkg.list.git_files.opts = { prompt = "File: " }

-- Change anything you wish
-- For example the main entry point. `pkg.setup()` does not allow this
pkg.list.git_files.main = function () end
```

## What about `ido.start()`
Use `ido.start()` when you wish to do something quick or you can't be bothered to use the packages API. Packages are optional. They merely provide an integrated and uniform experience when using custom Ido functions.
