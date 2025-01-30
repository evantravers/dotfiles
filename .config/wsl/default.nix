# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{pkgs, ... }:

{
  imports = [
    # include NixOS-WSL modules
  ];

  nixpkgs.config.allowUnfree = true;

  wsl = {
    enable = true;
    defaultUser = "nixos";
    nativeSystemd = true;
    interop.includePath = true;
  };

  environment = {
    systemPackages = with pkgs; [
      wslu
      wsl-open
    ];
  };

  home-manager.users.nixos = { ... }: {
    services.ollama.acceleration = "cuda";
  };
}
