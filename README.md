# Dotfiles

Going to track some dotfiles that may not need security or generation.

## Quickstart

1. `xcode-select --install`
2. `git clone git@github.com:evantravers/dotfiles.git ~/.dotfiles`
3. `cd ~/.dotfiles`
4. `make install`

## Behavior

- modify a bunch of OSX settings
- [Homebrew](https://brew.sh/)
- Everything in my [Brewfile](https://github.com/evantravers/dotfiles/blob/master/Brewfile)
- set up all my dotfile configs via `stow`
- [Paq.nvim](https://github.com/savq/paq-nvim)
- [asdf](https://github.com/asdf-vm/asdf)
- [tpm (tmux plugin manager)](https://github.com/tmux-plugins/tpm)
- LSP server for Elixir
- Doom Emacs for funsies

## Warnings

I have only tested this on OSX. I tend to live on the edge with my dotfiles
these days, so be warned. This setup is deeply personal to my work, but feel
free to fork it and change the brewfile or whatever you want to have your own
just-add-brew dev environment.
