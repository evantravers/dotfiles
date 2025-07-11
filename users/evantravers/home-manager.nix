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
  xdg.configFile."ghostty/config".source = .config/ghostty/config;
  xdg.configFile."moxide/settings.toml".text = ''
    title_headings = false
  '';

  home = {
    stateVersion = "24.05"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      _1password-cli
      amber
      unstable.devenv
      gum
      harper
      lua-language-server
      markdown-oxide
      nixd
      nixfmt-rfc-style
      opencode
      ripgrep
      sesh
      smartcat
    ];

    sessionVariables = {
      OPENROUTER_KEY = "op://Private/Open Router/credential";
      ANTHROPIC_API_KEY = "op://Private/Claude/credential";
      GITHUB_TOKEN = "op://Private/Github Copilot/credential";
    };
  };

  programs = {
    # get nightly
    neovim.package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # N/A
      '';
      functions = {
        _1password_agent_wsl = {
          description = "Creates socat npiperelay with windows-based 1Password";
          body = ''
          set -gx SSH_AUTH_SOCK $HOME/.1password/agent.sock
          # need `ps -ww` to get non-truncated command for matching
          # use square brackets to generate a regex match for the process we want but that doesn't match the grep command running it!
          set ALREADY_RUNNING (
                  ps -auxww | grep -q "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent"
            echo $status)
          if test $ALREADY_RUNNING != "0"
                  if test -S $SSH_AUTH_SOCK
                          # not expecting the socket to exist as the forwarding command isn't running (http://www.tldp.org/LDP/abs/html/fto.html)
                          echo "removing previous socket..."
                          rm $SSH_AUTH_SOCK
            end
                  echo "Starting SSH-Agent relay..."
                  # setsid to force new session to keep running
                  # set socat to listen on $SSH_AUTH_SOCK and forward to npiperelay which then forwards to openssh-ssh-agent on windows
            set agent (setsid socat "UNIX-LISTEN:$SSH_AUTH_SOCK,fork" "EXEC:/mnt/c/Users/Tower/scoop/shims/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) &>/dev/null
            disown
          end
          '';
        };
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
      clean.enable = true;
      flake = ./.;
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
