{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.llama-cpp;
in
{
  options.programs.llama-cpp = {
    enable = lib.mkEnableOption "llama-cpp router server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port the local llama.cpp router listens on.";
    };

    modelsDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/models";
      description = "Directory of GGUF model files served by the router. Supports env vars like $HOME.";
    };

    contextWindow = lib.mkOption {
      type = lib.types.int;
      default = 32768;
      description = "Context window (tokens) applied to each loaded model (-c).";
    };

    gpuLayers = lib.mkOption {
      type = lib.types.int;
      default = 999;
      description = "Number of layers to offload to the GPU (-ngl).";
    };

    models = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Short identifier for this model (e.g. gemma, qwen).";
            };
            label = lib.mkOption {
              type = lib.types.str;
              description = "Human-readable label used in status messages and UIs.";
            };
            file = lib.mkOption {
              type = lib.types.str;
              description = "GGUF filename for this model (as discovered under modelsDir).";
            };
          };
        }
      );
      default = [ ];
      description = "Local GGUF models served by the router. The router discovers and downloads the files itself; this catalog supplies labels and filenames to consumers like the editor adapters.";
    };
  };

  config = lib.mkIf cfg.enable (
    let
      llama-server-start = pkgs.writeShellScriptBin "llama-server-start" ''
        #!/usr/bin/env bash
        set -euo pipefail

        MODELS_DIR="''${MODELS_DIR:-${cfg.modelsDir}}"
        PORT="''${PORT:-${toString cfg.port}}"
        CTX="''${CTX:-${toString cfg.contextWindow}}"

        if tmux has-session -t llama 2>/dev/null; then
          echo "llama router already running (tmux session 'llama')."
          echo "  attach: tmux attach-session -t llama"
          echo "  stop:   tmux kill-session -t llama"
          exit 0
        fi

        tmux new-session -d -s llama \
          "exec ${pkgs.llama-cpp}/bin/llama-server \
            --models-dir '$MODELS_DIR' \
            --no-models-autoload \
            --host 127.0.0.1 \
            --port '$PORT' \
            -ngl ${toString cfg.gpuLayers} \
            -c '$CTX'"

        tmux set-option -t llama remain-on-exit on
        echo "Started llama router on http://127.0.0.1:$PORT (tmux session 'llama')."
        echo "  In pi: /login llama.cpp  then /llama to load/unload/download models, /model to select."
      '';
    in
    {
      home.packages = with pkgs; [
        llama-cpp
        llama-server-start
      ];

      # Let pi reach the router without an interactive /login (docs: llama-cpp.md).
      home.sessionVariables = {
        LLAMA_BASE_URL = "http://127.0.0.1:${toString cfg.port}";
      };
    }
  );
}
