{ pkgs, config, lib, inputs, ... }:

{
  imports = [
    ./git.nix
    inputs._1password-shell-plugins.hmModules.default
  ];

  nixpkgs.config.allowUnfree = true;

  home = {

    username = "samuelcotterall";
    homeDirectory = "/Users/samuelcotterall";
    stateVersion = "24.05"; # Please read the comment before changing.

    packages = with pkgs; [
      starship
      zsh-history-substring-search
      pyenv
      nodejs_22
      mkcert
      cmake
      gh
      yarn
      _1password-cli
      (python3.withPackages (ps: [ps.pip]))
    ];
  };


  programs._1password-shell-plugins = {
    enable = true;
    plugins = with pkgs; [ gh ];
  };
  programs.home-manager.enable = true;

  programs.zsh = {
      enable = true;
      sessionVariables = {
        OP_PLUGIN_ALIASES_SOURCED = 1;
        GITHUB_TOKEN = "op://Private/Github/token";
      };

      shellAliases = {
        gh = "op plugin run -- gh";
        h2 = "$(npm prefix -s)/node_modules/.bin/shopify hydrogen";
      };
      initExtra = ''
        setopt completealiases
        eval "$(starship init zsh)"
        # Enable zsh-history-substring-search
        source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        # Initialize pyenv
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        if command -v pyenv 1>/dev/null 2>&1; then
          eval "$(pyenv init -)"
        fi
        clear
      '';
    };

}
