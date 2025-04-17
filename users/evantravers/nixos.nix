{ pkgs, inputs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.11";

  # Since we're using fish as our shell
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  time.timeZone = "America/Chicago";

  users.users.evantravers = {
    isNormalUser = true;
    home = "/home/evantravers";
    # extraGroups = [ "docker" "lxd" "wheel" ];
    shell = pkgs.fish;
  };
}

