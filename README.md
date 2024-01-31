# Dotfiles

## Install Nix

I've used the default OSX installer, I'd probably use the [Determinate Systems Installer](https://github.com/DeterminateSystems/nix-installer) now.

## Clone this repo

(Use `nix-shell - git` if you don't have git in your path yet.)

`git clone git@github.com:evantravers/dotfiles.git ~/src/github.com/evantravers/dotfiles`

## NixOS

`sudo nixos-rebuild switch --flake nixos-configuration --impure` (currently impure because of wsl stuff I haven't fixed.)

## MacOS

`nix run nix-darwin -- switch --flake ~/src/github.com/evantravers/dotfiles/nix-darwin-configuration/`

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
