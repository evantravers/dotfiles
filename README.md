# Dotfiles

This repository contains my Nix-based dotfiles for setting up a reproducible development environment on macOS (Darwin), NixOS (including WSL), and Linux. It uses Nix Flakes, home-manager, and (on macOS) nix-darwin for system and user configuration.

## Structure

- `flake.nix` / `flake.lock`: Flake entrypoint and dependency lock file.
- `devenv.nix` / `devenv.yaml`: Optional development shell configuration.
- `darwin/`: macOS-specific system configuration (e.g., `darwin.nix`).
- `nixos/`: NixOS system configuration (e.g., `configuration.nix`).
- `home-manager/`: User-level configuration, imported by both Darwin and NixOS setups. Main file: `home-manager/default.nix`.

## Key Features

- Declarative package management for user and system.
- Home-manager for user environment (shell, aliases, packages, etc).
- macOS support via nix-darwin.
- Secure secrets and plugin management with 1Password shell plugins.
- Python 3 with pip included by default (see below).

## Install Nix

- **macOS:** [Determinate Systems Installer](https://github.com/DeterminateSystems/nix-installer)
- **WSL2:** [WSL2 Nix](https://github.com/nix-community/NixOS-WSL?tab=readme-ov-file)

## Bootstrap

> [!WARNING]
> Bootstrapping is not fully tested on all hosts. Review and adapt as needed.

### NixOS (including WSL)

```sh
sudo nixos-install --flake github:samuelcotterall/dotfiles#nixos
```

### macOS/Linux (Darwin)

```sh
nix run nix-darwin -- switch --flake github:samuelcotterall/dotfiles
```

## Update

### NixOS

```sh
sudo nixos-rebuild switch --flake ~/src/github.com/samuelcotterall/dotfiles
```

### Darwin

```sh
darwin-rebuild switch --flake ~/src/github.com/samuelcotterall/dotfiles
```

## Home Manager

You can import the home-manager configuration standalone like this:

```nix
{ config, pkgs, ... }: {
  home-manager.users.samuelcotterall = import ./home-manager/default.nix;
}
```

## How it fits together

- **System-level config** (NixOS or Darwin) imports the user-level config from `home-manager/default.nix`.
- **User-level config** sets up your shell, environment variables, aliases, and packages.
- **Secrets/plugins**: 1Password shell plugins are enabled for secure secrets and CLI integration.
- **Python**: Python 3 with pip is included by default. You can add more Python packages in `home-manager/default.nix`:

```nix
home.packages = with pkgs; [
  # ...other packages...
  (python3.withPackages (ps: [ps.pip ps.numpy ps.requests]))
];
```

## Customization

- Edit `home-manager/default.nix` to add or remove packages, shell aliases, or environment variables.
- For system-level changes, edit `darwin/darwin.nix` or `nixos/configuration.nix` as appropriate.

---

For more details, see the [NixOS Wiki: Python](https://wiki.nixos.org/wiki/Python) and [Home Manager manual](https://nix-community.github.io/home-manager/).
