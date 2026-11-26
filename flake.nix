{
  description = "Evan's Nix System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents.url = "github:numtide/llm-agents.nix";
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    mini-nvim = {
      url = "github:nvim-mini/mini.nvim";
      flake = false;
    };
    # raine/workmux#59: jj support, not yet merged to main
    workmux-jj = {
      url = "github:raine/workmux/jj";
      flake = false;
    };
  };
  outputs =
    { nixpkgs, ... }@inputs:
    let
      overlaySet = import ./overlays.nix { inherit inputs; };
      overlays = builtins.attrValues overlaySet;

      mkSystem = import ./lib/mksystem.nix { inherit overlays nixpkgs inputs; };

      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system}.extend overlaySet.local-packages;
        in
        {
          inherit (pkgs) jjc wt;
        }
      );

      # `nix fmt`: same nixfmt settings as `jj fix` (see jujutsu.nix)
      formatter = forAllSystems (
        system:
        nixpkgs.legacyPackages.${system}.nixfmt-tree.override {
          settings.formatter.nixfmt.options = [ "--strict" ];
        }
      );

      nixosConfigurations.wsl = mkSystem "wsl" {
        system = "x86_64-linux";
        user = "evantravers";
        wsl = true;
      };

      darwinConfigurations.Theseus = mkSystem "macbook-pro" {
        system = "aarch64-darwin";
        user = "evantravers";
        darwin = true;
      };
    };
}
