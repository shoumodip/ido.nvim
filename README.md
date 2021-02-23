# Ido.nvim
The ultra-extensible narrowing framework for Neovim. Originally inspired by the Emacs mode, Ido aims to make interactive matching a pleasure.

![Ido](img/ido.png)

## Basic usage
```lua
require("ido").start({items = {"red", "green", "blue"}})
```

## Default Keybindings
- `<Right>` Move the cursor forward a character
- `<Left>` Move the cursor backward a character

- `<C-f>` Move the cursor forward a character
- `<C-b>` Move the cursor backward a character

- `<C-Right>` Move the cursor forward a word
- `<C-Left>` Move the cursor backward a word

- `<M-f>` Move the cursor forward a word
- `<M-b>` Move the cursor backward a word

- `<C-a>` Move the cursor to the beginning of the line
- `<C-e>` Move the cursor to the end of the line

- `<C-n>` Select next item
- `<C-p>` Select previous item

- `<Down>` Select next item
- `<Up>` Select previous item

- `<BS>` Delete a character backward
- `<Del>` Delete a character forward

- `<Tab>` Accept the suggestion
- `<CR>` Accept the selected item (if any)
- `<Esc>` Exit ido

## Advanced Usage
Ido is extensible to the point where you can literally break it. The following documentation files will explain the API of Ido mode.

- [Variables and options](wiki/settings.md)
- [Layouts and UX](wiki/ux.md)
- [Advices](wiki/advices.md)
- [Main module](wiki/main.md)
- [Standard Library of Ido](wiki/stdlib.md)
