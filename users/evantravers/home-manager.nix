{ pkgs, ... }:

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
  xdg.configFile."ghostty".source = .config/ghostty;
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
