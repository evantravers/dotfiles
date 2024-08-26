{ pkgs, lib, ... }:

{
  imports = [
    ./nvim.nix
    ./tmux.nix
    ./git.nix
    ./wezterm.nix
  ];

  home = {
    stateVersion = "24.05"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = [
      pkgs.amber
      pkgs.devenv
      pkgs.ltex-ls
      pkgs.markdown-oxide
      pkgs.nixd
      pkgs.ripgrep
    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
      hammerspoon = lib.mkIf pkgs.stdenvNoCC.isDarwin {
        source = ./../.config/hammerspoon;
        target = ".hammerspoon";
        recursive = true;
      };
    };

    sessionVariables = {
    };
  };

  programs = {
    # Use fish
    fish = {
      enable = true;

      interactiveShellInit = ''
        set fish_greeting # N/A
      '';

      plugins = [
      ];
    };

    direnv = {
      enable = true;

      nix-direnv.enable = true;
    };

    starship = {
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

    jujutsu = {
      enable = true;
    };

    helix = {
      enable = true;
      defaultEditor = true;
      languages = {
        language = [
          {
            name = "nix";
            language-servers = [ "nixd" ];
          }
          {
            name = "markdown";
            language-servers = [
              "markdown-oxide"
              "ltex-ls"
            ];
          }
        ];
        language-server = {
          nixd.command = "${pkgs.nixd}/bin/nixd";
          markdown-oxide.command = "${pkgs.markdown-oxide}/bin/markdown-oxide";
          ltex-ls.command = "${pkgs.ltex-ls}/bin/ltex-ls";
        };
      };
      settings = {
        theme = "kanagawa-dragon";
        editor = {
          color-modes = true;
          cursorline = true;
          file-picker = {
            hidden = false;
          };
          line-number = "relative";
          lsp = { display-inlay-hints = true; };
          rulers = [ 80 ];
          soft-wrap = {
            enable = false;
            wrap-at-text-width = true;
          };
          true-color = true;
        };
        keys = {
          normal.space.W = ":toggle-option soft-wrap.enable";
          insert.C-c = "normal_mode";
        };
      };
    };
  };
}
