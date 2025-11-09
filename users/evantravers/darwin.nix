{ pkgs, lib, ... }:

{
  # Enable fish and zsh
  programs.zsh.enable = true;
  programs.fish.enable = true;
  programs._1password.enable = true;

  users.users.evantravers = {
    home = "/Users/evantravers";
    shell = pkgs.fish;
  };

  environment.systemPackages = [
    pkgs.defaultbrowser
    pkgs.firefox
    pkgs.kanata
    pkgs.karabiner-elements.driver
    pkgs.keycastr
    pkgs.unstable.notion-app
    pkgs.unstable.obsidian
  ];

  environment.extraInit = ''
  export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
  '';

  environment.variables = {
    HOMEBREW_AUTO_UPDATE_SECS = "86400";
  };

  services = {
    aerospace = {
      enable = false;
      settings = {
        accordion-padding = 0;
        on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
        on-window-detected = [
          {
            "if" = {
              app-id = "com.flexibits.fantastical2.mac";
            };
            run = "move-node-to-workspace 2";
          }
        ];
        workspace-to-monitor-force-assignment = {
          "1" = [ "main" ];
          "2" = [
            "secondary"
            "main"
          ];
        };
        mode = {
          main = {
            binding = {
              alt-y = "layout tiles horizontal vertical";
              alt-t = "layout accordion horizontal vertical";
              alt-h = "focus left";
              alt-j = "focus down";
              alt-k = "focus up";
              alt-l = "focus right";
              alt-shift-h = "move left";
              alt-shift-j = "move down";
              alt-shift-k = "move up";
              alt-shift-l = "move right";
              alt-ctrl-h = "join-with left";
              alt-ctrl-j = "join-with down";
              alt-ctrl-k = "join-with up";
              alt-ctrl-l = "join-with right";
              alt-minus = "resize smart -100";
              alt-equal = "resize smart +100";
              alt-1 = "workspace 1";
              alt-2 = "workspace 2";
              alt-3 = "workspace 3";
              alt-shift-1 = "move-node-to-workspace 1";
              alt-shift-2 = "move-node-to-workspace 2";
              alt-shift-3 = "move-node-to-workspace 3";
              alt-tab = "workspace-back-and-forth";
              alt-shift-tab = "move-node-to-monitor --wrap-around next";
              alt-shift-semicolon = "mode service";
            };
          };
          service = {
            binding = {
              esc = [
                "reload-config"
                "mode main"
              ];
              r = [
                "flatten-workspace-tree"
                "mode main"
              ];
              f = [
                "layout floating tiling"
                "mode main"
              ];
              backspace = [
                "close-all-windows-but-current"
                "mode main"
              ];
            };
          };
        };
      };
    };
    jankyborders = {
      enable = false;
      blur_radius = 5.0;
      hidpi = true;
      active_color = "0xAAB279A7";
      inactive_color = "0x33867A74";
    };
  };

  homebrew = {
    enable = true;

    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    onActivation.cleanup = "zap";

    casks =
      [
        "1password"
        "calibre"
        "cardhop"
        "deskpad"
        "discord"
        "docker-desktop"
        "fantastical"
        "figma"
        "ghostty"
        "hammerspoon"
        "homerow"
        "karabiner-elements"
        "macwhisper"
        "mouseless"
        "obs"
        "ollama-app"
        "pop-app"
        "raycast"
        "signal"
        "slack"
        "steam"
        "telegram"
        "vlc"
        "zoom"
      ];

    masApps = {
      "Parcel" = 375589283;
      "Reeder" = 1529448980;
      "Timery" = 1425368544;
      "Toggl" = 1291898086;
    };
  };

  fonts.packages = [
    pkgs.atkinson-hyperlegible
    pkgs.jetbrains-mono
    pkgs.recursive
  ];
  system = {
    primaryUser = "evantravers";
    defaults = {
      dock = {
        autohide = true;
        orientation = "left";
        show-process-indicators = false;
        show-recents = false;
        static-only = true;
      };
      finder = {
        AppleShowAllExtensions = true;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        ShowPathbar = true;
      };
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
      };
      NSGlobalDomain = {
        AppleKeyboardUIMode = 3;
        "com.apple.keyboard.fnState" = true;
        NSAutomaticWindowAnimationsEnabled = false;
        NSWindowShouldDragOnGesture = true;
      };
      CustomUserPreferences."org.hammerspoon.Hammerspoon" = {
        MJConfigFile = "~/.config/hammerspoon/init.lua";
      };
    };
    # karabiner-elements.enable = true;
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
