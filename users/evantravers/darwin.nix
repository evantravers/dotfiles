{ pkgs, ... }:
{
  # Workaround for fish build failure on Apple Silicon due to upstream nixpkgs issue.
  # See: https://github.com/NixOS/nixpkgs/issues/507531
  nixpkgs.overlays = [
    (_final: prev: {
      fish = prev.fish.overrideAttrs (_old: {
        NIX_FORCE_LOCAL_REBUILD = "darwin-codesign-fix";
      });
    })
  ];

  imports = [
    ./aerospace.nix
    ./kanata.nix
    ./omniwm.nix
    ./orbstack.nix
  ];

  services.aerospace.enable = false;
  kanata.enable = true;
  programs.orbstack.enable = true;

  # Enable fish and zsh
  programs.zsh.enable = true;
  programs.fish.enable = true;
  programs._1password.enable = true;
  programs.omniwm.enable = true;

  users.users.evantravers = {
    home = "/Users/evantravers";
    shell = pkgs.fish;
  };

  environment.systemPackages = with pkgs; [
    defaultbrowser
    firefox
    hidden-bar
    keycastr
    libation
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
