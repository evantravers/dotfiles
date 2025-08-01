{ pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [
      pkgs.home-manager
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  environment.darwinConfig = "$HOME/dotfiles/darwin";

  # Auto upgrade nix package and the daemon service.
  nix.enable = false;

  # nix.gc.automatic = true;
  # nix.gc.options = "--delete-older-than 30d";

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs = {
    gnupg.agent.enable = true;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  fonts.packages = [
    pkgs.jetbrains-mono
  ];

  services = {

  };

  homebrew = {
    # enable = true;

    casks = [
      # "1password-cli"
      "supabase"
    #   "1password"
    #   "bartender"
    #   "fantastical"
    #   "firefox"
    #   "ghostty"
    #   "google-chrome"
    #   "hammerspoon"
    #   "karabiner-elements"
    #   "keycastr"
    #   "librewolf"
    #   "obsidian"
    #   "raycast"
    ];

  };

  system = {
    # defaults = {
    #   dock = {
    #     autohide = true;
    #     orientation = "left";
    #     show-process-indicators = false;
    #     show-recents = false;
    #     static-only = true;
    #   };
    #   finder = {
    #     AppleShowAllExtensions = true;
    #     FXDefaultSearchScope = "SCcf";
    #     FXEnableExtensionChangeWarning = false;
    #     ShowPathbar = true;
    #   };
    #   NSGlobalDomain = {
    #     AppleKeyboardUIMode = 3;
    #     "com.apple.keyboard.fnState" = true;
    #     NSAutomaticWindowAnimationsEnabled = false;
    #     NSWindowShouldDragOnGesture = true;
    #   };
    # };
    # keyboard = {
    #   enableKeyMapping = true;
    #   remapCapsLockToControl = true;
    # };
  };
}
