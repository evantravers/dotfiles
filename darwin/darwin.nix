{ pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [
      pkgs.home-manager
    ];

  # Set up environment variables for Homebrew
  environment.variables = {
    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
    HOMEBREW_REPOSITORY = "/opt/homebrew";
    PATH = "/opt/homebrew/bin:/opt/homebrew/sbin:$PATH";
    MANPATH = "/opt/homebrew/share/man:$MANPATH";
    INFOPATH = "/opt/homebrew/share/info:$INFOPATH";
  };

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
    zsh.enable = true;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  fonts.packages = [
    pkgs.jetbrains-mono
  ];

  services = {};

  homebrew = {
    enable = true;
    brews = [ "supabase/tap/supabase" "postgresql" "pnpm" ];
    casks = [];
    # Add homebrew to PATH
    onActivation.cleanup = "zap";
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
