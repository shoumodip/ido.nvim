# Core
The core of [Ido](https://github.com/ido-nvim), the ultra-extensible narrowing framework for Neovim.

## Basic usage
```vim
:lua require("ido").start{items = {"red", "green", "blue"}}
```

In place of `{"red", "green", "blue"}`, place the items you wish to narrow.

## Install
Install this like any other NeoVim plugin. Run `git submodule update --init --recursive` after installing the plugin, to clone the [fzy-lua-native](https://github.com/romgrk/fzy-lua-native) dependency.

## Documentation
Learn how to break Ido [here](https://github.com/ido-nvim/docs).
