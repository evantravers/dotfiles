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
      ai-tools.claude-code
      ai-tools.claude-code-acp
      unstable.devenv
      gh
      gum
      harper
      lua-language-server
      markdown-oxide
      nixd
      nixfmt-rfc-style
      ai-tools.opencode
      ripgrep
      sesh
    ];

    sessionVariables = {
      # ANTHROPIC_API_KEY = "op://Private/Claude/credential";
    };
  };

  accounts.email.accounts.gmail = {
    primary = true;
    aerc.enable = true;
    himalaya.enable = true;

    address = "evantravers@gmail.com";
    userName = "evantravers@gmail.com";
    realName = "Evan Travers";
    folders = { inbox = "INBOX"; sent = "\[Gmail\]/Sent\ Mail"; trash = "\[Gmail\]/Trash"; };
    passwordCommand = "op read op://Private/a3v65jhzsq4lpiunlcf6fceesa/password";
    flavor = "gmail.com";
  };

  programs = {
    aerc = {
      enable = true;
      extraConfig = {
        general.unsafe-accounts-conf = true;
        viewer = {pager = "${pkgs.less}/bin/less -R";};
        filters = {
          "text/plain" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
          "text/calendar" = "${pkgs.aerc}/libexec/aerc/filters/calendar";
          "text/html" = "${pkgs.aerc}/libexec/aerc/filters/html";
          "message/delivery-status" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
          "message/rfc822" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
        };
        ui = {
          threading-enabled = true;
          show-thread-context = true;
          styleset-name = "dracula";
          border-char-vertical = "┃";
          spinner = "[ ⡿ ],[ ⣟ ],[ ⣯ ],[ ⣷ ],[ ⣾ ],[ ⣽ ],[ ⣻ ],[ ⢿ ]";
        };
      };
    };
    himalaya.enable = true;

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
          command = [
            "${lib.getExe pkgs.nixfmt-rfc-style}"
            "--strict"
            "--filename=$path"
          ];
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

    tiny = {
      enable = true;
      settings = {
        servers = [
          {
            addr = "irc.libera.chat";
            port = 6697;
            tls = true;
            realname = "Evan";
            nicks = [ "evantravers" ];
            join = [ "#nethack" "#nixos" "#neovim" ];
          }
        ];
        defaults = {
          nicks = [ "evantravers" ];
          realname = "Evan";
          join = [ ];
          tls = true;
        };
      };
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
