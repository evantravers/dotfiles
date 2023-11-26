{ config, pkgs, lib, ... }:

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

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.ripgrep
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # git
    ".cvsignore".source = git/.cvsignore;
    ".gitconfig".source = git/.gitconfig;
    # vim
    ".config/nvim/.vimrc".source = nvim/.config/nvim/.vimrc;
  };

  home.activation.mkdirNvimFolders = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/.config/nvim/backups $HOME/.config/nvim/swaps $HOME/.config/nvim/undo
  '';

  home.activation.installWeztermProfile = lib.hm.dag.entryAfter ["writeBoundary"] ''
    tempfile=$(mktemp) \
    && ${pkgs.curl}/bin/curl -o $tempfile https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo \
    && tic -x -o ~/.terminfo $tempfile \
    && rm $tempfile
  '';

  home.sessionVariables = {
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Use fish
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting # N/A
    '';

    plugins = [
      {
        # TODO: Remove this
        name = "fish-asdf";
        src = pkgs.fetchFromGitHub {
          owner = "rstacruz";
          repo = "fish-asdf";
          rev = "5869c1b1ecfba63f461abd8f98cb21faf337d004";
          sha256 = "39L6UDslgIEymFsQY8klV/aluU971twRUymzRL17+6c=";
        };
      }
    ];
  };

  programs.starship = {
    enable = true;

    settings = {
      command_timeout = 100;
      format = "[$all](dimmed white)";

      character = {
        success_symbol = "[❯](dimmed green)";
        error_symbol = "[❯](dimmed red)";
      };

      git_status = {
        style = "bold yellow";
        format = "([$all_status$ahead_behind]($style) )";
      };

      jobs.disabled = true;
    };
  };

  programs.git = {
    enable = true;

    lfs.enable = true;
  };

  programs.tmux = {
    enable = true;
    sensibleOnTop = false;
    prefix = "C-space";
    escapeTime = 0;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "wezterm";

    extraConfig = ''
    # use vi keys in search mode
    set-window-option -g mode-keys vi

    # status bar
    set-option -g status-left " #S "
    set-option -g status-right "#[bold]%-l:%M ⋮ #[default italics]%a, %b %d #[default]"
    set-option -g set-titles-string "tmux:#I #W"

    # window status (tab selected/unselected)
    set-window-option -g window-status-current-format "#[fg=colour7] ■ #I:#W#{?window_zoomed_flag, ,}"
    set-window-option -g window-status-format " □ #I:#W"

    # options from tmux-sensible

    # address vim mode switching delay (http://superuser.com/a/252717/65504)
    set -s escape-time 0

    # increase scrollback buffer size
    set -g history-limit 50000

    # tmux messages are displayed for 4 seconds
    set -g display-time 4000

    # refresh 'status-left' and 'status-right' more often
    set -g status-interval 5

    # emacs key bindings in tmux command prompt (prefix + :) are better than
    # vi keys, even for vim users
    set -g status-keys emacs

    # focus events enabled for terminals that support them
    set -g focus-events on

    # super useful when using "grouped sessions" and multi-monitor setup
    setw -g aggressive-resize on

    # more colors and themes
    set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
    set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0
    set -g message-style bg="colour0",fg="colour3"
    set -g pane-active-border-style fg="colour8"
    set -g pane-border-style fg="colour8"
    set -g status-position "top"
    set -g status-style bg="default",fg="colour15"
    set-window-option -g window-status-current-style fg="colour15"

    # dim inactive window text
    set -g window-style fg=colour15
    set -g window-active-style fg=colour7
    '';

    plugins = with pkgs.tmuxPlugins; [
      tmux-thumbs
      logging
      pain-control
      sessionist
      yank
    ];
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;

    extraLuaConfig = lib.fileContents nvim/.config/nvim/init.lua;

    plugins = [
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
    ];
  };
}
