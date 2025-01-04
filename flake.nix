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
    helix-master = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    nixpkgs,
    darwin,
    home-manager,
    nixos-wsl,
    helix-master,
    ...
  } @ inputs: let
    darwinSystem = {user, arch ? "aarch64-darwin"}:
      darwin.lib.darwinSystem {
        system = arch;
        modules = [
          ./darwin/darwin.nix
          home-manager.darwinModules.home-manager
          {
            _module.args = { inherit inputs; };
            home-manager = {
              users.${user} = import ./home-manager;
              extraSpecialArgs = {
                helix-master = helix-master;
              };
            };
            users.users.${user}.home = "/Users/${user}";
            nix.settings.trusted-users = [ user ];
          }
        ];
      };
  in
  {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.wsl
          ./nixos/configuration.nix
          ./.config/wsl
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              users.nixos = import ./home-manager;
              extraSpecialArgs = {
                helix-master = helix-master;
              };
            };
            nix.settings.trusted-users = [ "nixos" ];
          }
        ];
      };
    };
    darwinConfigurations = {
      "G2157QVFX1" = darwinSystem {
        user = "etravers";
      };
      "Evans-MacBook-Pro" = darwinSystem {
        user = "evan";
        arch = "x86_64-darwin";
      };
    };
  };
}
