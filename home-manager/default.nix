{ pkgs, config, lib, ... }:

{
  imports = [
    # ./git.nix
  ];

  home = {

    stateVersion = "24.05"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      nodejs_20
    ];

    sessionVariables = {
    };
  };

  programs = {


  };

}
