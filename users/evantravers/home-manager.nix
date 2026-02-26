{ pkgs, lib, ... }:
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
  xdg.configFile."hammerspoon" = lib.mkIf pkgs.stdenv.isDarwin { source = .config/hammerspoon; };
  xdg.configFile."kanata" = lib.mkIf pkgs.stdenv.isDarwin { source = .config/kanata; };
  xdg.configFile."ghostty".source = .config/ghostty;
  xdg.configFile."moxide/settings.toml".text = ''
    title_headings = false
  '';

  home = {
    stateVersion = "25.05"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      llm-agents.beads
      llm-agents.claude-code
      llm-agents.claude-code-acp
      llm-agents.opencode
      llm-agents.openspec
      llm-agents.pi
      amber
      unstable.devenv
      gh
      gum
      harper
      lua-language-server
      markdown-oxide
      nil
      nixfmt-rfc-style
      ripgrep
      sesh
    ];
  };

  accounts.email.accounts.gmail = {
    primary = true;
    aerc.enable = true;
    himalaya.enable = true;

    address = "evantravers@gmail.com";
    userName = "evantravers@gmail.com";
    realName = "Evan Travers";
    folders = {
      inbox = "INBOX";
      sent = "\[Gmail\]/Sent\ Mail";
      trash = "\[Gmail\]/Trash";
    };
    passwordCommand = "op read op://Private/a3v65jhzsq4lpiunlcf6fceesa/password";
    flavor = "gmail.com";
  };

  programs = {
    aerc = {
      enable = true;
      extraConfig = {
        general.unsafe-accounts-conf = true;
        viewer = {
          pager = "${pkgs.less}/bin/less -R";
        };
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
          patterns = [ "glob:'**/*.nix'" ];
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
            join = [
              "#nethack"
              "#nixos"
              "#neovim"
            ];
            sasl = {
              username = "evantravers";
              password = {
                command = "op read op://Private/7ftnywolnvbyska745tklaayqe/password";
              };
            };
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
