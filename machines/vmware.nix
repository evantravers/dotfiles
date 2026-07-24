{ pkgs, ... }:
{
  # VMware guest tools/support
  virtualisation.vmware.guest.enable = true;

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "vmware";

  # Standard NixOS settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "24.11";

  # We'll use fish as well to stay consistent
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  # Users config will be handled by mksystem.nix via userOSConfig
}
