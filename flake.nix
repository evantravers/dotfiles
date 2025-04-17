{
  description = "Evan's Nix System Configuration";

  inputs = {
    nixpkgs.url ="github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix-master = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
  outputs = { nixpkgs, ...}@inputs: let
    overlays = [
      # This overlay makes unstable packages available through pkgs.unstable
      (final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = prev.system;
          config.allowUnfree = true;
        };
      })
    ];

    mkSystem = import ./lib/mksystem.nix {
      inherit overlays nixpkgs inputs;
    };
  in {
    nixosConfigurations.wsl = mkSystem "wsl" {
      system = "x86_64-linux";
      user   = "evantravers";
      wsl    = true;
    };

    darwinConfigurations.G2157QVFX1 = mkSystem "macbook-pro-m1" {
      system = "aarch64-darwin";
      user   = "etravers";
      darwin = true;
    };
  };
}
