# Dotfiles

Going to track some dotfiles that may not need security or generation.

If you have gnu `stow`, just clone this to `~/.dotfiles/`, then run `stow
[name]` to install a dotfile.

## Installation

You ought to be able to run `make install` and it'll install:

- Xcode CLI Tools (if you haven't already)
- [Homebrew](https://brew.sh/)
- Everything in my [Brewfile](https://github.com/evantravers/dotfiles/blob/master/Brewfile)
- [Plug.vim](https://github.com/junegunn/vim-plug) to `~/.config/nvim`
- [tpm (tmux plugin manager)](https://github.com/tmux-plugins/tpm)
- [asdf](https://github.com/asdf-vm/asdf)

## Warnings

I have only tested this on OSX. I tend to live on the edge with my dotfiles
these days, so be warned. This setup is deeply personal to my work, but feel
free to fork it and change the brewfile or whatever you want to have your own
just-add-brew dev environment.
