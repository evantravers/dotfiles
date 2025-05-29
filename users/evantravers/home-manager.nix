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
      amber
      unstable.devenv
      gum
      harper
      lua-language-server
      markdown-oxide
      nixd
      nixfmt-rfc-style
      ripgrep
      sesh
      smartcat
    ];

    sessionVariables = {
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
