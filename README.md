# Dotfiles

## TODO:
- [ ] write a warning
- [ ] make some pretty pictures
- [ ] detail the setup

## Bootstrap

Install [Determinite Systems Installer](https://github.com/DeterminateSystems/nix-installer) or [WSL2 Nix](https://github.com/nix-community/NixOS-WSL)

WSL:
`sudo nixos-rebuild switch --flake github:evantravers/dotfiles#wsl`

Darwin:
`nix run nix-darwin -- switch --flake github:evantravers/dotfiles#macbook-pro-[intel m1]`

## Update
WSL:
`sudo nixos-rebuild switch --flake ./`

Darwin:
`darwin-rebuild switch --flake ./`

## References
- Mainly copying mitchellm's incredible work, especially mksystem.nix
