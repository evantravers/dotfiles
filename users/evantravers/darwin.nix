{ pkgs, config, ... }:
{
  imports = [
    ./kanata.nix
    ./orbstack.nix
  ];

  kanata.enable = true;
  programs.orbstack.enable = true;

  # Enable fish and zsh
  programs.zsh.enable = true;
  programs.fish.enable = true;
  programs._1password.enable = true;

  users.users.evantravers = {
    home = "/Users/evantravers";
    shell = pkgs.fish;
  };

  home-manager.users.evantravers = {
    xdg.configFile."hammerspoon".source = .config/hammerspoon;
    xdg.configFile."kanata".source = .config/kanata;

    programs.ssh.settings."*" = {
      IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
    };
  };

  environment.systemPackages = with pkgs; [
    # On macOS 27+, Firefox not signed by Mozilla is denied access to the
    # default data dir (~/Library/Application Support/Firefox). Point the
    # wrapper at a new location; existing profiles must be migrated manually:
    #   mv ~/Library/Application\ Support/Firefox \
    #      ~/Library/Application\ Support/org.nixos.firefox
    # https://github.com/NixOS/nixpkgs/pull/556611
    (firefox.override (old: {
      appDataDir = "${config.users.users.evantravers.home}/Library/Application Support/org.nixos.firefox";
    }))
    keycastr
    obsidian
  ];

  environment.extraInit = ''
    export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
  '';

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";

    casks = [
      "1password"
      "bartender"
      "calibre"
      "cardhop"
      "deskpad"
      "discord"
      "fantastical"
      "figma"
      "ghostty"
      "hammerspoon"
      "homerow"
      "macwhisper"
      "marked-app"
      "mouseless"
      "obs"
      "pop-app"
      "raycast"
      "signal"
      "slack"
      "telegram"
      "vlc"
      "zoom"
    ];
  };

  fonts.packages = [
    pkgs.atkinson-hyperlegible
    pkgs.nerd-fonts.jetbrains-mono
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
      ".GlobalPreferences"."com.apple.mouse.scaling" = 0.6875;
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
