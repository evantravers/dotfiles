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

    # Overlays
    llm-agents.url = "github:numtide/llm-agents.nix";
    devenv.url = "github:cachix/devenv/v2.2.2";
    workmux.url = "github:raine/workmux";
    # Tracks upstream main directly (rev pinned in flake.lock; `nix flake
    # update hunk` to move) so freshly-merged features can be tested without
    # waiting for llm-agents.nix releases.
    hunk.url = "github:modem-dev/hunk";
  };
  outputs =
    { nixpkgs, ... }@inputs:
    let
      overlays = builtins.attrValues (import ./overlays.nix { inherit inputs; });

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
