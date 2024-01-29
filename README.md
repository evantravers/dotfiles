# Dotfiles

## Install Nix

I've used the default OSX installer, I'd probably use the [Determinate Systems Installer](https://github.com/DeterminateSystems/nix-installer) now.

## Clone this repo

1. `git clone git@github.com:evantravers/dotfiles.git ~/src/github.com/evantravers/dotfiles`

## NixOS

1. `sudo nixos-rebuild switch --flake .#`

## MacOS

1. Install nix-darwin[^darwin]
2. `darwin-rebuild switch --flake ~/src/github.com/evantravers/dotfiles/nix-darwin-configuration`

## Home Manager

The dotfiles are structured so that you can use `stow` as a backup.

1. `ln -s ~/src/github.com/evantravers/dotfiles/ ~/.config/home-manager`
2. `cp ~/src/github.com/evantravers/dotfiles/local.nix.tmp ~/.dotfiles/local.nix`
3. Edit `~/src/github.com/evantravers/dotfiles/local.nix` to be correct (TODO: this should be automated)
4. `home-manager switch`

[^darwin]: https://daiderd.com/nix-darwin/#Installing

        ```
        nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
        ./result/bin/darwin-installer
        ```
