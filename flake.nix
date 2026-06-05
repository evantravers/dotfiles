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

    # Overlays
    # neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay?sha=a49f9d17bcaa684b81fc4322fbcbfc3ba501d40e"; # 2026-03-30
    jujutsu.url = "github:jj-vcs/jj?tag=v0.42.0";
    devenv.url = "github:cachix/devenv?tag=v2.1.2";
  };
  outputs =
    { nixpkgs, ... }@inputs:
    let
      overlays = builtins.attrValues (import ./overlays { inherit inputs; });

      mkSystem = import ./lib/mksystem.nix { inherit overlays nixpkgs inputs; };
    in
    {
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
