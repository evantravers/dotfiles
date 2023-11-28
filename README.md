# Dotfiles

## NixOS

- basically enables flakes

`ln configuration.nix /etc/nixos/configuration.nix`

## Home Manager

The dotfiles are structured so that you can use `stow` as a backup.

1. `ln -s ~/.dotfiles/ ~/.config/home-manager`
2. Install home-manager[^home]:
3. `cp ~/.dotfiles/local.nix.tmp ~/.dotfiles/local.nix`
4. Edit `~/.dotfiles/local.nix` to be correct (TODO: this should be automated)
5. `nix-shell '<home-manager>' -A install`

[^home]: https://nix-community.github.io/home-manager/index.html#sec-install-standalone

        ```
        nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
        nix-channel --update
        ```

        `nix-shell '<home-manager>' -A install`
