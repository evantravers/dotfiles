# Dotfiles

## Install Nix and/or NixOS

- I've used the default OSX installer, I'd probably use the determinite systems
installer now.

## Clone this repo

1. git clone git@github.com:evantravers/dotfiles.git ~/.dotfiles

## NixOS

1. `ln configuration.nix /etc/nixos/configuration.nix`

## MacOS

1. Install Nix
2. Install nix-darwin[^darwin]
3. `rm ~/.nixpkgs/darwin-configuration.nix && ln nix-darwin/.nixpkgs/darwin-configuration.nix ~/.nixpkgs/darwin-configuration.nix`
4. `darwin-rebuild switch`

## Home Manager

The dotfiles are structured so that you can use `stow` as a backup.

1. `ln -s ~/.dotfiles/ ~/.config/home-manager`
2. `cp ~/.dotfiles/local.nix.tmp ~/.dotfiles/local.nix`
3. Edit `~/.dotfiles/local.nix` to be correct (TODO: this should be automated)
4. `home-manager switch`

[^darwin]: https://daiderd.com/nix-darwin/#Installing

        ```
        nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
        ./result/bin/darwin-installer
        ```
