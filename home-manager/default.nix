{ pkgs, config, lib, ... }:

{
  imports = [
    # ./git.nix
  ];

  home = {
    username = "samuelcotterall";
    homeDirectory = "/Users/samuelcotterall";
    stateVersion = "24.05"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      nodejs_20
    ];
  };

  programs.home-manager.enable = true;

  programs.zsh = {
      enable = true;
      initExtra = ''
        eval "$(oh-my-posh init zsh)"
        clear
      '';
    };

}
