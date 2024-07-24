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
        {
          name = "nix-env";
          src = pkgs.fetchFromGitHub {
            owner = "lilyball";
            repo = "nix-env.fish";
            rev = "7b65bd228429e852c8fdfa07601159130a818cfa";
            hash = "sha256-RG/0rfhgq6aEKNZ0XwIqOaZ6K5S4+/Y5EEMnIdtfPhk=";
          };
        }
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
      settings = {
        theme = "mellow";
        editor = {
          color-modes = true;
          cursorline = true;
          line-number = "relative";
          lsp = { display-inlay-hints = true; };
          rulers = [ 80 ];
          true-color = true;
          soft-wrap.wrap-at-text-width = true;
        };
      };
    };
  };
}
