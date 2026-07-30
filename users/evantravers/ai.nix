{ config, lib, ... }:

let
  cfg = config.ai;
in
{
  # Single source of truth for the AI models available to tooling.
  #
  # Consumers:
  #   - nvim-ai.nix    builds one codecompanion adapter per model
  #   - llama-cpp.nix  serves models carrying `llamaCpp` GGUF details
  #                    and exposes them to pi
  options.ai = {
    default = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Name of the default model (must match an entry in ai.models).";
      example = "moonshot";
    };

    models = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Short identifier for this model (e.g. moonshot, gemma, qwen).";
            };
            label = lib.mkOption {
              type = lib.types.str;
              description = "Human-readable label used in status messages and UIs.";
            };
            baseUrl = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Base URL of the OpenAI-compatible endpoint. Not required for ACP-based models.";
              example = "http://localhost:8080";
            };
            model = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Model identifier sent to the API. Not required for ACP-based models.";
            };
            apiKey = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "API key for the endpoint (may be a cmd: string). Null for keyless local servers.";
            };
            reasoning = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether this model supports reasoning.";
            };
            contextWindow = lib.mkOption {
              type = lib.types.int;
              default = 65536;
              description = "Context window size in tokens.";
            };
            maxTokens = lib.mkOption {
              type = lib.types.int;
              default = 8192;
              description = "Maximum output tokens.";
            };
            acp = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    command = lib.mkOption {
                      type = lib.types.str;
                      description = "ACP command to run (e.g. 'opencode acp').";
                    };
                  };
                }
              );
              default = null;
              description = "When set, use ACP (Claude Code / Agent Client Protocol) instead of HTTP. The model's baseUrl/model are ignored.";
            };
            llamaCpp = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
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
                  };
                }
              );
              default = null;
              description = "Hugging Face GGUF source for serving locally with llama-server. Null for remote models.";
            };
          };
        }
      );
      default = [ ];
      description = "Models available to AI tools (codecompanion, pi, llama-server).";
    };
  };

  config = lib.mkIf (cfg.models != [ ]) (
    let
      acpOffenders = builtins.filter (
        m: m.acp == null && ((m.baseUrl == null && m.llamaCpp == null) || m.model == null)
      ) cfg.models;
    in
    {
      assertions = [
        {
          assertion = cfg.default == null || lib.any (m: m.name == cfg.default) cfg.models;
          message = "ai.default (${toString cfg.default}) must match the name of an entry in ai.models.";
        }
        {
          assertion = acpOffenders == [ ];
          message =
            "Every ai.models entry without 'acp' must have 'model' set, and 'baseUrl' unless it has 'llamaCpp' (llama-cpp.nix supplies that). Offending entries: "
            + builtins.concatStringsSep ", " (builtins.map (m: m.name) acpOffenders);
        }
      ];
    }
  );
}
