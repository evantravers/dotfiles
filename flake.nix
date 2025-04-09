{
  description = "Samuel's Nix System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    _1password-shell-plugins.url = "github:1Password/shell-plugins";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
     rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  outputs = {
    nixpkgs,
    nix-darwin,
    home-manager,
    rust-overlay,
    ...
  } @ inputs: let
    allowed-unfree-packages = [
      "1password-cli"
    ];
    darwinSystem = {user, arch ? "aarch64-darwin"}:
      nix-darwin.lib.darwinSystem {
        system = arch;
        modules = [
          ./darwin/darwin.nix
          home-manager.darwinModules.home-manager
          {
            _module.args = { inherit inputs; };
            # home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit allowed-unfree-packages user inputs;};
            home-manager.backupFileExtension = "backup";
            home-manager.users.${user} = import ./home-manager;
            users.users.${user}.home = "/Users/${user}";
            nix.settings.trusted-users = [ user ];
          }
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ rust-overlay.overlays.default ];
            environment.systemPackages = [ pkgs.rust-bin.stable.latest.default ];
          })
        ];
        specialArgs = {inherit allowed-unfree-packages user;};
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
