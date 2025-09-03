{
  description = "Evan's Nix System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
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

    nix-rv = {
      url = "github:evantravers/nix-rv";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
  outputs =
    { nixpkgs, ... }@inputs:
    let
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
