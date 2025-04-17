{ pkgs, inputs, ... }:

{
  # Since we're using fish as our shell
  programs.fish.enable = true;

  users.users.evantravers = {
    isNormalUser = true;
    home = "/home/evantravers";
    # extraGroups = [ "docker" "lxd" "wheel" ];
    shell = pkgs.fish;
  };

}

