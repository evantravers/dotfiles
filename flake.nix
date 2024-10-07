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
    home-manager,
    ...
  } @ inputs: let
      darwinSystem = {host, user, arch ? "aarch64-darwin"}: {
        ${host} = darwin.lib.darwinSystem {
          system = ${arch};
          modules = [
            ./darwin/darwin.nix
            home-manager.darwinModules.home-manager
            {
              _module.args = { inherit inputs; };
              home-manager = {
                users.${user} = import ./home-manager;
              };
              # FIXME: feels like the below could be two lines above
              users.users.${user}.home = "/Users/${user}";
              nix.settings.trusted-users = [ user ];
            }
          ];
        };
      };
  in
  {
    nixosConfigurations = {
      "nixos" = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.wsl
          ./nixos/configuration.nix
          ./.config/wsl
          home-manager.nixosModules.home-manager
          {
            home-manager.users.nixos = import ./home-manager;
          }
        ];
      };
      nix.settings.trusted-users = [ "nixos" ];
    };


    darwinConfigurations = {
      darwinSystem({
        host = "G2157QVFX1";
        user = "etravers";
      });
      darwinSystem({
        host = "Evans-MacBook-Pro";
        user = "evan";
        arch = "x86_64-darwin";
      });
    };
  };
}
