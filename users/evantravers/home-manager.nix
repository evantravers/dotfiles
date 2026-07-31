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
  xdg.configFile."moxide/settings.toml".text = ''
    title_headings = false
  '';

  home = {
    stateVersion = "26.05";

    packages = with pkgs; [
      llm-agents.antigravity-cli
      llm-agents.claude-code
      llm-agents.hunk
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
        agent = "claude";
        panes = [
          {
            command = "<agent>";
            focus = true;
          }
          { split = "horizontal"; }
        ];
      };
    };

    # Source control
    git.enable = true;
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
          model = "gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf";
          repo = "unsloth/gemma-4-26B-A4B-it-GGUF";
          quant = "Q4_K_XL";
          draftQuant = "Q8_0-MTP";
        }
        {
          name = "qwen";
          label = "Qwen 3.6 35B-A3B";
          model = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
          reasoning = true;
          repo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
          quant = "Q4_K_XL";
        }
      ];
    };

    pi = {
      enable = true;
    };

    # Comms
    email.enable = true;
    tiny.enable = true;
  };
}
