# Dotfiles

## NixOS

- basically enables flakes

`ln configuration.nix /etc/nixos/configuration.nix`

## Home Manager

The dotfiles are structured so that you can use `stow` as a backup.

1. `ln -s ~/.dotfiles/ ~/.config/home-manager`
2. Install home-manager[^home]:
3. `nix-shell '<home-manager>' -A install`

Optional:

Install wezterm's terminfo
```
tempfile=$(mktemp) \
&& curl -o $tempfile https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo \
&& tic -x -o ~/.terminfo $tempfile \
&& rm $tempfile
```

[^home]: https://nix-community.github.io/home-manager/index.html#sec-install-standalone

        ```
        nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
        nix-channel --update
        ```

        `nix-shell '<home-manager>' -A install`
