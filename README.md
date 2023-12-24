# Dotfiles

## Install Nix and/or NixOS

- I've used the default OSX installer, I'd probably use the determinite systems
installer now.

## NixOS

- basically enables flakes

`ln configuration.nix /etc/nixos/configuration.nix`

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

[^home]: https://nix-community.github.io/home-manager/index.html#sec-install-standalone

        ```
        nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
        nix-channel --update
        ```

        `nix-shell '<home-manager>' -A install`

[^darwin]: https://daiderd.com/nix-darwin/#Installing

        ```
        nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
        ./result/bin/darwin-installer
        ```
