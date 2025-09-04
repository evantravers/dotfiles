{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./git.nix
    ./helix.nix
    ./himalaya.nix
    ./nvim.nix
    ./starship.nix
    ./tmux.nix
  ];

  xdg.enable = true;
  # TODO: move this to ./home-manager/modules/darwin or something
  xdg.configFile."hammerspoon" = lib.mkIf pkgs.stdenv.isDarwin {
    source = .config/hammerspoon;
  };
  xdg.configFile."kanata" = lib.mkIf pkgs.stdenv.isDarwin {
    source = .config/kanata;
  };
  xdg.configFile."ghostty".source = .config/ghostty;
  xdg.configFile."moxide/settings.toml".text = ''
    title_headings = false
  '';
  xdg.configFile."opencode/opencode.json".text = ''
  {
    "$schema": "https://opencode.ai/config.json",
    "provider": {
      "ollama": {
        "npm": "@ai-sdk/openai-compatible",
        "name": "Ollama (local)",
        "options": {
          "baseURL": "http://localhost:11434/v1"
        },
        "models": {
          "gpt-oss:20b": {
            "name": "GPT OSS:20b"
          }
        }
      }
    },
    "model": "anthropic/claude-sonnet-4-20250514",
    "small_model": "anthropic/claude-3-5-haiku-20241022"
  }
  '';

  home = {
    stateVersion = "25.05"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      amber
      unstable.claude-code
      unstable.devenv
      gh
      gum
      harper
      lua-language-server
      markdown-oxide
      nixd
      nixfmt-rfc-style
      unstable.opencode
      ripgrep
      sesh
      smartcat
    ];

    sessionVariables = {
      ANTHROPIC_API_KEY = "op://Private/Claude/credential";
    };
  };

  programs = {
    # get nightly
    # neovim.package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # N/A
      '';
      shellAliases = {
        opencode = "op run --no-masking -- opencode";
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    jujutsu = {
      enable = true;
      package = pkgs.unstable.jujutsu;
      settings = {
        user = {
          name = "Evan Travers";
          email = "evantravers@gmail.com";
        };
        ui.default-command = "log";
        fix.tools.nixfmt = {
          command = ["${lib.getExe pkgs.nixfmt-rfc-style}" "$path"];
          patterns = ["glob:'**/*.nix'"];
        };
        templates.draft_commit_description = ''
          concat(
            coalesce(description, default_commit_description, "\n"),
            surround(
              "\nJJ: This commit contains the following changes:\n", "",
              indent("JJ:     ", diff.stat(72)),
            ),
            "\nJJ: ignore-rest\n",
            diff.git(),
          )
        '';
      };
    };

    nh = {
      enable = true;
      package = pkgs.unstable.nh;
      clean.enable = true;
      flake = ../../.;
    };

    yazi = {
      enable = true;
      enableFishIntegration = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };

  # services.ollama.enable = true;
}
