{
  description = "NixOS Configuration for WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, nixos-wsl, ...}: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.wsl
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.users.nixos = import ../home-manager/home.nix;
          }
        ];
      };
    };
  };
}
