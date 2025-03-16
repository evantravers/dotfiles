{
  description = "Samuel's Nix System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  outputs = {
    nixpkgs,
    nix-darwin,
    home-manager,
    ...
  } @ inputs: let
    darwinSystem = {user, arch ? "aarch64-darwin"}:
      nix-darwin.lib.darwinSystem {
        system = arch;
        modules = [
          ./darwin/darwin.nix
          home-manager.darwinModules.home-manager
          {
            _module.args = { inherit inputs; };
            home-manager = {
              users.${user} = import ./home-manager;
              extraSpecialArgs = {
              };
            };
            users.users.${user}.home = "/Users/${user}";
            nix.settings.trusted-users = [ user ];
          }
        ];
      };
  in
  {
    darwinConfigurations = {
      "mbp" = darwinSystem {
        user = "samuelcotterall";
      };
    };
  };
}
