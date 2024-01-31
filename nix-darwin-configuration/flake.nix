{
  description = "Evan's darwin system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs }: {
    darwinConfigurations = {
      "G2157QVFX1" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              users.etravers = import ../home-manager/home.nix;
            };
            users.users.etravers.home = "/Users/etravers";
          }
        ];
        specialArgs = { inherit inputs; };
      };
      "Evans-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              users.evan = import ../home-manager/home.nix;
            };
            users.users.evan.home = "/Users/evan";
          }
        ];
        specialArgs = { inherit inputs; };
      };
    };
  };
}
