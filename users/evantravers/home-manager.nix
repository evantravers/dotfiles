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
    stateVersion = "26.05";

    packages = with pkgs; [
      llm-agents.antigravity-cli
      llm-agents.claude-code
      llm-agents.claude-agent-acp
      llm-agents.opencode
      llm-agents.openspec
      llm-agents.pi
      llm-agents.showboat
      amber
      devenv
      gh
      gum
      harper
      lua-language-server
      markdown-oxide
      nil
      nixd
      nixfmt
      rainfrog
      ripgrep
      sesh
    ];
  };

  programs = {
    git.enable = true;
    helix.enable = true;
    tiny.enable = true;
    jujutsu.enable = true;
    neovim = {
      enable = true;
      ai.enable = true;
      dap.enable = true;
      prose.enable = true;
    };
    starship.enable = true;
    tmux.enable = true;
    llama-cpp.enable = true;
    email.enable = true;

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

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = lib.mkIf pkgs.stdenv.isDarwin {
          IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
        };
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    nh = {
      enable = true;
      clean.enable = true;
      flake = builtins.path { path = ../../.; name = "source"; };
    };

    yazi = {
      enable = true;
      enableFishIntegration = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    man.generateCaches = false;
  };
}
