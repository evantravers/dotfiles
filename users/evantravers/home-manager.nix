{ pkgs, lib, ... }:

{
  imports = [
    ./email.nix
    ./git.nix
    ./helix.nix
    ./hunk.nix
    ./irc.nix
    ./jujutsu.nix
    ./llama-cpp.nix
    ./nvim.nix
    ./pi.nix
    ./starship.nix
    ./tmux.nix
    ./workmux.nix
  ];

  xdg.enable = true;
  # TODO: move this to ./home-manager/modules/darwin or something
  xdg.configFile."hammerspoon" = lib.mkIf pkgs.stdenv.isDarwin { source = .config/hammerspoon; };
  xdg.configFile."kanata" = lib.mkIf pkgs.stdenv.isDarwin { source = .config/kanata; };
  xdg.configFile."ghostty".source = .config/ghostty;
  # Zenbones fish theme: basic ANSI colors only (no hex), so it follows the
  # ghostty zenbones light/dark palette flip automatically. Installed so the
  # built-in configurator can pick it; activate once (not per shell) with:
  #   fish_config theme save zenbones
  # which persists it as universal variables in ~/.config/fish/fish_variables,
  # loaded automatically by fish at startup. Re-run the save after changing
  # this file to pick up edits.
  xdg.configFile."fish/themes/zenbones.theme".source = .config/fish/themes/zenbones.theme;
  xdg.configFile."moxide/settings.toml".text = ''
    title_headings = false
  '';

  home = {
    stateVersion = "26.05";

    packages = with pkgs; [
      llm-agents.antigravity-cli
      llm-agents.claude-code
      llm-agents.opencode
      llm-agents.openspec
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
    # Shell
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

    starship.enable = true;

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
      flake = builtins.path {
        path = ../../.;
        name = "source";
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

    man.generateCaches = false;

    # Multiplexer
    tmux.enable = true;

    workmux = {
      enable = true;
      settings = {
        nerdfont = true;
        merge_strategy = "rebase";
        base_branch = "auto";
        post_create = [ "workmux-devenv-rebind" ];
        pre_remove = [ "workmux-devenv-unbind" ];
      };
    };

    # Source control
    git.enable = true;
    hunk.enable = true;
    jujutsu.enable = true;

    # Editors
    neovim = {
      enable = true;
      ai.enable = true;
      dap.enable = true;
      prose.enable = true;
    };

    helix.enable = true;

    # AI
    llama-cpp = {
      enable = true;
      models = [
        {
          name = "gemma";
          label = "Gemma 4 26B-A4B";
          file = "gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf";
        }
        {
          name = "qwen";
          label = "Qwen 3.6 35B-A3B";
          file = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
        }
      ];
    };

    pi.enable = true;

    # Comms
    email.enable = true;
    tiny.enable = true;
  };
}
