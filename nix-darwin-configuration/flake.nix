{
  description = "Evan's darwin system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }: {
    darwinConfigurations = {
      "G2157QVFX1" = nix-darwin.lib.darwinSystem {
        # localSettings = {
        #   home = {
        #     username = "etravers";
        #     homeDirectory = "/Users/etravers/";
        #   };
        #   hostPlatform = "aarch64-darwin";
        # };
        modules = [ ./configuration.nix ];
        specialArgs = { inherit inputs; };
      };
      "Evans-Macbook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [ ./configuration.nix ];
        specialArgs = { inherit inputs; };
      };
    };
  };
}
