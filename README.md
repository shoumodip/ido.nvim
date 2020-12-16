# Ido Neovim
For those of you who have been in touch with Emacsland, know of a certain feature called *Ido*. It is essentially a narrowing framework for Emacs. Well guess what, due to recent API changes in Neovim nightly, it need not be confined to Emacs any more!

![Ido mode](img/ido.png)

# Installation
Using Neovim's builtin package system.
```sh
git clone https://github.com/shoumodip/ido.nvim ~/.config/nvim/pack/plugins/start/ido.nvim
```

You can also use any package manager of your choice.

# How to use
Ido is invoked using `ido_completing_read(PROMPT, {ITEMS})` which takes a table as an input. The table can contain four items / subtables --

`prompt` The prompt to be used. If left blank, then `ido_default_prompt` will be used.

`items` The list of items to match on.

`keybinds` Custom keybindings to be used. If left default, then `ido_keybindings` will be used.

`on_enter` The function which will be executed on returning the value.

For example.

```lua
print(ido_complete({prompt = 'Choose: ', items = {'red', 'green', 'blue'}}))
```

Or just use the default prompt.
```lua
print(ido_complete({items = {'red', 'green', 'blue'}}))
```

Maybe a custom function.

```lua
print(ido_complete({items = {'red', 'green', 'blue'}, on_enter = function(s) print(s) end}))
```

Particular order does not matter here. The options can be placed in whatsoever way you want. There is no specification on whether prompt should be placed at the first or something like that.

For a more "complex" example, check out `ido_find_files()` in *menus.lua*. (Bound to `<Leader>.`)\
***Note:*** These are lua functions. So when calling these from a VimL file, you need to put the `lua` keyword at the beginning.

Also check out the Api section in the `README` to fully understand the ways of extending Ido mode.

# Colors
Most probably, Ido will look horrible on your terminal. The reason being Ido uses some weird emulation techniques in order to enable *returning* of the selected item. So most probably you will need to change these highlight settings.

`IdoCursor` The virtual cursor emulation used in Ido.

`IdoSelectedMatch` The color for the selected match.

`IdoPrefix` The color used for the prefix.

`IdoSeparator` The color used for the separator, the match start character and the match end character.

`IdoPrompt` The color used for the prompt.

# Settings
Just like the Ido mode of Emacs, the Ido mode of Neovim is perfectly extensible. The settings are lua variables, so its a simple
```vim
lua VARNAME = VALUE
```

`ido_fuzzy_matching` (**Boolean**) Whether Ido should match fuzzily or not. Set to `true` by default.

`ido_case_senstive` (**Boolean**) Whether Ido should match case-senstively or not. Set to `false` by default.

`ido_overlap_statusline` (**Boolean**) Whether the Ido floating window should overlap the statusline or not. Set to `false` by default.

`ido_min_lines` (**Number**) The minimum boundary of the Ido minibuffer. Only important if `ido_limit_lines` is `true`.

`ido_max_lines` (**Number**) The maximum boundary of the Ido minibuffer. Only has any effect if `ido_limit_lines` is `false`.

`ido_limit_lines` (**Boolean**) If the number of lines in the Ido minibuffer exceeds `ido_min_lines`, decides whether to show the `more_items` symbol or make the minibuffer `ido_max_lines` tall. `true` by default.

# Ido Decorations
The various symbolifiers of Ido, like match separator, prefix start, etc. This is a lua dictionary so `lua ido_decorations[ITEM] = VALUE`, where `ITEM` is one of the following --

`prefixstart` The character shown before the *prefix*. See below for stuff about the *prefix*. By default, it is `[`.

`prefixend` The character shown after the prefix. By default, it is `]`.

`matchstart` The character shown before the available matches. (if any) By default it is empty.

`matchend` The character shown after the matches. By default it is empty.

`separator` The separator between matches. By default it is ` | `.

`marker` The indicator for the current item. By default it is empty.

`moreitems` The character which denotes there are more matches which are not being rendered. Has no effect if `ido_limit_lines` is `false`. By default it is `...`.

Some examples of Ido decorations --

## Vertical layout
Execute these as lua commands.

```lua
ido_decorations['separator']   = '\n    '
ido_decorations['matchstart']  = '\n'
ido_decorations['marker']      = ' -> '
ido_decorations['moreitems']   = ''
ido_limit_lines                = false
```

This will create a vertical layout for Ido --

![Ido vertical](img/ido_vertical.png)

# Prefix
*prefix* - The most awesome feature in existence. When using Ido, it will provide the least common prefix substring as a *suggestion*. Pressing `<Tab>` will do what you expect - **tab completion**! If there is only one item as a match, the entire match will become the prefix and on pressing `<Tab>`, it will complete the prefix and accept the item like `<Return>`.

    Find files: d[o] {documents | downloads}

Here `[o]` is the prefix being suggested as the substring `do` is present at the beginning of all the available matches.

    >>> mus[music]

Here `[music]` is the only available match. Therefore the entire item is the suggestion.

# Hotkeys
`<C-n>`    The next item\
`<C-p>`    The previous item

`<C-f>`    Forward a character\
`<C-b>`    Backward a character

`<C-a>`    Start of line\
`<C-e>`    End of line

`<Right>`  Forward a character\
`<Left>`   Backward a character

`<Tab>`    Prefix completion\
`<Return>` Accept the selected item, else accept the pattern text\
`<Escape>` Escape Ido, duh

# API
Ido mode was originally from Emacsland. Therefore not provinding an API would be sacriligeous. Since Ido mode is near enough infinitely extensible, therefore this is divided into 3 parts.

## Keybindings
It is divided into two parts -- the global keybindings and the temporary keybindings.

Keybindings consist of `["KEYNAME"] = 'FUNCTION'`

where `KEYNAME` is the key binding in standard vim notation (see `key-notation`).

And `FUNCTION` is a global Lua function, emphasis on global. I could'nt find a way to make it work with local functions, so unless you have a solution and create a pull request, global functions it is. Also the functions must ***not*** have the `'(<args>)'` part. There can be no parenthesis at the end used for calling a function.

### Global
These are the keybindings used in every single instance of Ido. This is set in the `ido_keybindings` table. For example this is something a psychopath would put in the keybindings.

```lua
ido_keybindings = {
  ["\\<Right>"] = 'ido_cursor_move_begin',
  ["\\<Left>"]  = 'ido_cursor_move_end',
}
```

***Note:*** After changing the global keybindings, you have to execute the `ido_load_keys()` lua function in order to, you know, load the keys. Otherwise they won't take effect.

### Temporary
These are keybindings used in only one instance of Ido, and are defined in the table of options supplied to `ido_complete`.

```lua
ido_complete({items = {'red', 'green', 'blue'}, keybinds = {["\\<Right>"] = 'ido_cursor_move_end'}})
```

## Variables
The variables used in Ido mode.

`ido_matched_items` The table of the items matched.

`ido_window` The floating window belonging to Ido.

`ido_buffer` The buffer used by Ido.

`ido_before_cursor` The text present before the virtual cursor position in Ido.

`ido_after_cursor` The text present after the virtual cursor position in Ido.

`ido_prefix` The prefix

`ido_prefix_text` The complete prefix, containing the pattern and the prefix.

`ido_current_item` The current selected item in Ido.

`ido_render_text` The text being rendered in Ido.

`ido_default_prompt` The default prompt of Ido. ('>>> ')

`ido_cursor_position` The virtual cursor position of Ido.

`ido_more_items` Whether there are more items which are not being rendered.

`ido_pattern_text` The pattern being matched in the items.

`ido_match_list` The list of items on which the pattern is being matched.

`ido_prompt` The prompt being used.

## Functions
The functions defined in Ido are.

`ido_close_window` Close the Ido window and stop the character input loop.

`ido_get_matches` Get the items which match with the pattern. Also find out the prefix.

`ido_insert_char` Insert the character you last pressed. Does |not| take any argument.

`ido_key_backspace` Emulate the backspace key in Ido.

`ido_key_delete` Emulate the delete key in Ido.

`ido_cursor_move_left` Move the virtual cursor left a character.

`ido_cursor_move_right` Move the virtual cursor right a character.

`ido_cursor_move_begin` Move the virtual cursor to the beginning of the pattern.

`ido_cursor_move_end` Move the virtual cursor to the endning of the pattern.

`ido_next_item` Select the next match.

`ido_prev_item` Select the previous match.

`ido_complete_prefix` Complete the prefix.

## Special Functions
The functions which aren't really functions but are recognised by Ido by an `if-else` statement. Meant to be used **only** in keybindings. I repeat, *"Do not try to use this in your function or whatever!"*

`ido_accept` Accept the current item.

`ido_complete_prefix` Complete the prefix. If there is only one matching item, then behaves the same as `ido_accept`.

# Help in Neovim
`:h ido` Main help file.

`:h FUNCTION_NAME` Get help on a specific ido function.

`:h VARIABLE_NAME` Get help on a specific ido variable.

# License
MIT
