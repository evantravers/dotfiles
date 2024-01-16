{
  description = "Evan's darwin system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }: {
    darwinConfigurations = {
      "Evans-Macbook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [ ./configuration.nix ];
        nixpkgs.hostPlatform = "x86_64-darwin";
      };
    };
  };
}
