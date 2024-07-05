{
  description = "Evan's Nix System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    darwin,
    nixos-wsl,
    home-manager,
    ...
  } @ inputs: {
    nixosConfigurations = {
      "nixos" = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.wsl
          ./modules/nixos/configuration.nix
          ./modules/wsl
          home-manager.nixosModules.home-manager
          {
            home-manager.users.nixos = import ./modules/home-manager;
          }
        ];
      };
    };

    darwinConfigurations = {
      "G2157QVFX1" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./modules/darwin
          home-manager.darwinModules.home-manager
          {
            _module.args = { inherit inputs; };
            home-manager = {
              users.etravers = import ./modules/home-manager;
            };
            users.users.etravers.home = "/Users/etravers";
          }
        ];
      };
      "Evans-MacBook-Pro" = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [
          ./modules/darwin
          home-manager.darwinModules.home-manager
          {
            _module.args = { inherit inputs; };
            home-manager = {
              users.evan = import ./modules/home-manager;
            };
            users.users.evan.home = "/Users/evan";
          }
        ];
      };
    };
  };
}
