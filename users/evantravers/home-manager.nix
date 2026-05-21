{ pkgs, lib, ... }:

{
  imports = [
    ./email.nix
    ./git.nix
    ./helix.nix
    ./irc.nix
    ./jujutsu.nix
    ./llama-cpp.nix
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
    stateVersion = "25.05";

    packages = with pkgs; [
      llm-agents.claude-code
      llm-agents.claude-agent-acp
      llm-agents.opencode
      llm-agents.openspec
      llm-agents.pi
      llm-agents.showboat
      amber
      # unstable.devenv
      devenv
      gh
      gum
      harper
      lua-language-server
      markdown-oxide
      nil
      nixd
      nixfmt-rfc-style
      unstable.rainfrog
      ripgrep
      sesh
    ];
  };

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # N/A
        devenv hook fish | source
      '';
      shellAliases = {
        opencode = "op run --no-masking -- opencode";
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
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
}
