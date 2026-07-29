{ config, lib, options, pkgs, ... }:

let
  cfg = config.programs.llama-cpp;

  # Models are defined centrally in ai.nix; llama-cpp serves the ones
  # carrying Hugging Face GGUF details.
  models = builtins.filter (m: m.llamaCpp != null) (config.ai.models or [ ]);

  zeroCost = {
    input = 0;
    output = 0;
    cacheRead = 0;
    cacheWrite = 0;
  };

  defaultModel = lib.head models;

  modelNames = lib.concatMapStringsSep "|" (m: m.name) models;

  helpArgs = lib.concatStrings (map (m:
    "  ${m.name}${lib.optionalString (m.name == defaultModel.name) " (default)"}\n" +
    "    Start ${m.label} with image support\n"
  ) models);

  caseArgs = lib.concatStrings (map (m:
    "    ${m.name})\n" +
    "      MODEL=\"${m.name}\"\n" +
    "      shift\n" +
    "      ;;\n"
  ) models);

  modelVars = lib.concatStrings (map (m:
    "  ${m.name})\n" +
    "    LABEL=\"${m.label}\"\n" +
    "    REPO=\"${m.llamaCpp.repo}\"\n" +
    "    QUANT=\"${m.llamaCpp.quant}\"\n" +
    "    DRAFT_QUANT=\"${lib.optionalString (m.llamaCpp.draftQuant != null) m.llamaCpp.draftQuant}\"\n" +
    "    ;;\n"
  ) models);

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
      id = m.model;
      name = "${m.label} ${m.llamaCpp.quant} + MTP";
      reasoning = m.reasoning;
      input = [ "text" "image" ];
      contextWindow = m.contextWindow;
      maxTokens = m.maxTokens;
      cost = zeroCost;
    }) models;
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
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = models != [ ];
          message = "programs.llama-cpp is enabled but no entry in ai.models has llamaCpp GGUF details.";
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
