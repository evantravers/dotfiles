# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{pkgs, ... }:

{
  imports = [
    # include NixOS-WSL modules
  ];

  nixpkgs.config.allowUnfree = true;

  environment = {
    systemPackages = with pkgs; [
      wslu
      wsl-open
    ];
  };

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  system.stateVersion = "24.11";

  time.timeZone = "America/Chicago";

  wsl = {
    enable = true;
    defaultUser = "nixos";
    interop.includePath = true;
  };

  # home-manager.users.nixos = { ... }: {
  #   services.ollama.acceleration = "cuda";
  # };
}
