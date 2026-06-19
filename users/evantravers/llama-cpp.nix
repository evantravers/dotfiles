{ config, lib, pkgs, ... }:

let
  gemmaRepo = "unsloth/gemma-4-26B-A4B-it-GGUF";
  gemmaQuant = "Q4_K_XL";
  gemmaModelId = "gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf";
  gemmaDraftQuant = "Q8_0-MTP";

  qwenRepo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
  qwenQuant = "Q4_K_XL";
  qwenModelId = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";

  llama-server-start = pkgs.writeShellScriptBin "llama-server-start" ''
        #!/usr/bin/env bash
        set -euo pipefail

        MODEL="gemma"
        SPEC="false"

        show_help() {
          cat <<EOF
    Usage: llama-server-start [gemma|qwen] [options]

    Start a local llama-server tuned for coding-agent workloads using Hugging Face files.

    Arguments:
      gemma   Start Google Gemma 4 26B-A4B with image support (default)
      qwen    Start Alibaba Qwen 3.6 35B-A3B with image support

    Options:
      --spec        Enable speculative decoding (MTP).
                    Note: Requires a very recent llama.cpp build supporting the
                    gemma4-assistant architecture.
      -h, --help    Show this help message
    EOF
        }

        while [[ $# -gt 0 ]]; do
          case "$1" in
            gemma)
              MODEL="gemma"
              shift
              ;;
            qwen)
              MODEL="qwen"
              shift
              ;;
            --spec)
              SPEC="true"
              shift
              ;;
            -h|--help)
              show_help
              exit 0
              ;;
            *)
              echo "Error: Unknown argument '$1'" >&2
              show_help
              exit 1
              ;;
          esac
        done

        if tmux has-session -t llama 2>/dev/null; then
          echo "Tmux session 'llama' is already running!"
          echo "To attach:   tmux attach-session -t llama"
          echo "To stop:     tmux kill-session -t llama"
          exit 0
        fi

        ARGS=()

        if [[ "''${MODEL}" == "gemma" ]]; then
          if [[ "''${SPEC}" == "true" ]]; then
            echo "Starting llama-server with Gemma 4 26B-A4B + Speculative MTP + Projector (in background tmux)..."
            ARGS=(
              -hf "${gemmaRepo}:${gemmaQuant}"
              -hfd "${gemmaRepo}:${gemmaDraftQuant}"
              --spec-type draft-mtp
              --spec-draft-n-max 3
              -ngl 999
              -fa on
              -c 65536
              --parallel 1
              --host 127.0.0.1
              --port 8080
            )
          else
            echo "Starting llama-server with Gemma 4 26B-A4B + Projector (Speculation disabled, in background tmux)..."
            ARGS=(
              -hf "${gemmaRepo}:${gemmaQuant}"
              -ngl 999
              -fa on
              -c 65536
              --parallel 1
              --host 127.0.0.1
              --port 8080
            )
          fi

        elif [[ "''${MODEL}" == "qwen" ]]; then
          if [[ "''${SPEC}" == "true" ]]; then
            echo "Starting llama-server with Qwen 3.6 35B-A3B + Speculative MTP + Projector (in background tmux)..."
            ARGS=(
              -hf "${qwenRepo}:${qwenQuant}"
              --spec-type draft-mtp
              --spec-draft-n-max 3
              -ngl 999
              -fa on
              -c 65536
              --parallel 1
              --host 127.0.0.1
              --port 8080
            )
          else
            echo "Starting llama-server with Qwen 3.6 35B-A3B + Projector (Speculation disabled, in background tmux)..."
            ARGS=(
              -hf "${qwenRepo}:${qwenQuant}"
              -ngl 999
              -fa on
              -c 65536
              --parallel 1
              --host 127.0.0.1
              --port 8080
            )
          fi
        fi

        tmux new-session -d -s llama "exec ${pkgs.llama-cpp}/bin/llama-server ''${ARGS[*]}"
        # Keep the pane open if llama-server exits/crashes so the error is visible
        # instead of the session silently disappearing.
        tmux set-option -t llama remain-on-exit on
        echo "Server started in background tmux session 'llama'."
        echo "To monitor:  tmux attach-session -t llama"
        echo "To stop:     tmux kill-session -t llama"
  '';
in
{
  options.programs.llama-cpp.enable = lib.mkEnableOption "llama-cpp configurations";

  config = lib.mkIf config.programs.llama-cpp.enable {
    home.packages = with pkgs; [
      llama-cpp
      llama-server-start
    ];

    home.sessionVariables = {
      PI_AGENT_DIR = "${config.xdg.configHome}/pi";
      PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi/agent/";
    };

    xdg.configFile."pi/agent/models.json".text = ''
      {
        "providers": {
          "llama-cpp": {
            "baseUrl": "http://localhost:8080/v1",
            "api": "openai-completions",
            "apiKey": "local",
            "authHeader": false,
            "compat": {
              "supportsDeveloperRole": false,
              "supportsReasoningEffort": false
            },
            "models": [
              {
                "id": "${gemmaModelId}",
                "name": "Gemma 4 26B-A4B Q4 + MTP",
                "reasoning": false,
                "input": ["text", "image"],
                "contextWindow": 65536,
                "maxTokens": 8192,
                "cost": {
                  "input": 0,
                  "output": 0,
                  "cacheRead": 0,
                  "cacheWrite": 0
                }
              },
              {
                "id": "${qwenModelId}",
                "name": "Qwen3.6 35B-A3B Q4 + MTP",
                "reasoning": true,
                "input": ["text", "image"],
                "contextWindow": 65536,
                "maxTokens": 8192,
                "cost": {
                  "input": 0,
                  "output": 0,
                  "cacheRead": 0,
                  "cacheWrite": 0
                }
              }
            ]
          }
        }
      }
    '';

    xdg.configFile."pi/agent/settings.json".text = ''
      {
        "defaultProvider": "llama-cpp",
        "defaultModel": "${gemmaModelId}",
        "defaultThinkingLevel": "minimal"
      }
    '';
  };
}
