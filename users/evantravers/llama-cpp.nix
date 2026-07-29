{ config, lib, options, pkgs, ... }:

let
  cfg = config.programs.llama-cpp;

  zeroCost = {
    input = 0;
    output = 0;
    cacheRead = 0;
    cacheWrite = 0;
  };

  defaultModel = lib.head cfg.models;

  modelNames = lib.concatMapStringsSep "|" (m: m.name) cfg.models;

  helpArgs = lib.concatStrings (map (m:
    "  ${m.name}${lib.optionalString (m.name == defaultModel.name) " (default)"}\n" +
    "    Start ${m.label} with image support\n"
  ) cfg.models);

  caseArgs = lib.concatStrings (map (m:
    "    ${m.name})\n" +
    "      MODEL=\"${m.name}\"\n" +
    "      shift\n" +
    "      ;;\n"
  ) cfg.models);

  modelVars = lib.concatStrings (map (m:
    "  ${m.name})\n" +
    "    LABEL=\"${m.label}\"\n" +
    "    REPO=\"${m.repo}\"\n" +
    "    QUANT=\"${m.quant}\"\n" +
    "    DRAFT_QUANT=\"${lib.optionalString (m.draftQuant != null) m.draftQuant}\"\n" +
    "    ;;\n"
  ) cfg.models);

  piProvider = {
    baseUrl = "http://localhost:8080/v1";
    api = "openai-completions";
    apiKey = "local";
    authHeader = false;
    compat = {
      supportsDeveloperRole = false;
      supportsReasoningEffort = false;
    };
    models = map (m: {
      id = m.modelId;
      name = "${m.label} ${m.quant} + MTP";
      reasoning = m.reasoning;
      input = [ "text" "image" ];
      contextWindow = 65536;
      maxTokens = 8192;
      cost = zeroCost;
    }) cfg.models;
  };

  llama-server-start = pkgs.writeShellScriptBin "llama-server-start" ''
#!/usr/bin/env bash
set -euo pipefail

MODEL="${defaultModel.name}"
SPEC="false"

show_help() {
  cat <<EOF
Usage: llama-server-start [${modelNames}] [options]

Start a local llama-server tuned for coding-agent workloads using Hugging Face files.

Arguments:
${helpArgs}
Options:
  --spec        Enable speculative decoding (MTP).
                Note: Requires a very recent llama.cpp build supporting the
                gemma4-assistant architecture.
  -h, --help    Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    ${caseArgs}
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

case "''${MODEL}" in
  ${modelVars}
esac

ARGS=()

if [[ "''${SPEC}" == "true" ]]; then
  echo "Starting llama-server with ''${LABEL} + Speculative MTP + Projector (in background tmux)..."
  ARGS+=(-hf "''${REPO}:''${QUANT}")
  [[ -n "''${DRAFT_QUANT}" ]] && ARGS+=(-hfd "''${REPO}:''${DRAFT_QUANT}")
  ARGS+=(
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
  echo "Starting llama-server with ''${LABEL} + Projector (Speculation disabled, in background tmux)..."
  ARGS+=(
    -hf "''${REPO}:''${QUANT}"
    -ngl 999
    -fa on
    -c 65536
    --parallel 1
    --host 127.0.0.1
    --port 8080
  )
fi

tmux new-session -d -s llama "exec ${pkgs.llama-cpp}/bin/llama-server ''${ARGS[*]}"
tmux set-option -t llama remain-on-exit on
echo "Server started in background tmux session 'llama'."
echo "To monitor:  tmux attach-session -t llama"
echo "To stop:     tmux kill-session -t llama"
  '';
in
{
  options.programs.llama-cpp = {
    enable = lib.mkEnableOption "llama-cpp configurations";

    models = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Short CLI identifier for this model (e.g. gemma, qwen).";
          };
          label = lib.mkOption {
            type = lib.types.str;
            description = "Human-readable label used in status messages.";
          };
          repo = lib.mkOption {
            type = lib.types.str;
            description = "Hugging Face repository containing the GGUF files.";
          };
          quant = lib.mkOption {
            type = lib.types.str;
            description = "Quantization variant to fetch from the repo.";
          };
          draftQuant = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional draft model quantization for speculative decoding.";
          };
          modelId = lib.mkOption {
            type = lib.types.str;
            description = "Model identifier reported by llama-server (the GGUF filename).";
          };
          reasoning = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this model supports reasoning.";
          };
        };
      });
      default = [ ];
      description = "List of local models to expose via llama-server and pi.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.models != [ ];
          message = "programs.llama-cpp.models must contain at least one model.";
        }
      ];

      home.packages = with pkgs; [
        llama-cpp
        llama-server-start
      ];
    }

    (lib.optionalAttrs (options.programs ? pi) {
      programs.pi.providers = lib.mkIf (config.programs.pi.enable or false) {
        "llama-cpp" = piProvider;
      };
    })
  ]);
}
