{
  description = "Evan's Nix System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
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
    self,
    darwin,
    nixos-wsl,
    flake-utils,
    home-manager,
    ...
  } @ inputs: {
    nixosConfigurations = {
      "nixos" = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.wsl
          ./nixos/configuration.nix
          ./config/wsl
          home-manager.nixosModules.home-manager
          {
            home-manager.users.nixos = import ./home/home.nix;
          }
        ];
      };
    };

    darwinConfigurations = {
      "G2157QVFX1" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./darwin/darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              users.etravers = import ./home/home.nix;
            };
            users.users.etravers.home = "/Users/etravers";
          }
        ];
        specialArgs = { inherit inputs; };
      };
      "Evans-MacBook-Pro" = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [
          ./darwin/darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              users.evan = import ./home/home.nix;
            };
            users.users.evan.home = "/Users/evan";
          }
        ];
        specialArgs = { inherit inputs; };
      };
    };
  };
}
