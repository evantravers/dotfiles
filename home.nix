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

  programs.direnv = {
    enable = true;

    nix-direnv.enable = true;
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

    extraConfig = lib.fileContents tmux/.config/tmux/tmux.conf;

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
      {
        plugin = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
        type = "lua";
        config = ''
          vim.cmd [[packadd nvim-treesitter]]
          require'nvim-treesitter.configs'.setup {
            highlight = { enable = true, },
            indent = { enable = true },
          }
        '';
      }
    ];
  };
}
