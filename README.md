# Dotfiles

This is to describe the barebones development system I use. Supports NixOS on WSL, Intel and Silicon Macs.

## Install Nix

On OSX: [Determinate Systems Installer](https://github.com/DeterminateSystems/nix-installer).
On WSL2: [WSL2 Nix](https://github.com/nix-community/NixOS-WSL?tab=readme-ov-file)

## Clone this repo

(Use `nix-shell - git` if you don't have git in your path yet.)

`git clone git@github.com:evantravers/dotfiles.git ~/src/github.com/evantravers/dotfiles`

## NixOS

`sudo nixos-rebuild switch --flake ~/src/github.com/evantravers/dotfiles/nixos-configuration --impure` (currently impure because of wsl stuff I haven't fixed.)
Maybe: `sudo nix run github:evantravers/dotfiles?dir=nixos-configuration`

## MacOS

`nix run nix-darwin -- switch --flake ~/src/github.com/evantravers/`
Maybe: `sudo nix run github:evantravers/dotfiles#darwinConfiguration`

To update:
`darwin-rebuild switch --flake ~/src/github.com/evantravers/dotfiles/nix-darwin-configuration`

## Home Manager

The dotfiles are structured so that you can use `stow` as a backup. You could technically use `home-manager` separately from Nix to manage them, but the NixOS or nix-darwin flakes should manage it for you.

`home-manager switch --flake ~/src/github.com/evantravers/dotfiles/home-manager`

[^darwin]: https://daiderd.com/nix-darwin/#Installing

        ```
        nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
        ./result/bin/darwin-installer
        ```
