{ config, pkgs, ... }:

{
  # contains username and homeDirectory
  imports = [ ./local.nix ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.neovim
    pkgs.tmux
    pkgs.git
    pkgs.ripgrep
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # git
    ".cvsignore".source = git/.cvsignore;
    ".gitconfig".source = git/.gitconfig;
    # nvim
    ".config/nvim/.vimrc".source = nvim/.config/nvim/.vimrc;
    ".config/nvim/init.lua".source = nvim/.config/nvim/init.lua;
    # tmux
    ".config/tmux/shared.conf".source = tmux/.config/tmux/shared.conf;
    ".config/tmux/tmux.conf".source = tmux/.config/tmux/tmux.conf;
    # starship?
    ".config/starship/starship.toml".source = starship/.config/starship.toml;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Use fish
  programs.fish = {
    enable = true;
  };

  programs.starship = {
    enable = true;
  };
}
