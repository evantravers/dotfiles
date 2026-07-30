{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.pi;

  # ── Auto-derive pi providers from the central ai model registry ────────────
  aiModels = config.ai.models;
  aiDefault = config.ai.default;

  # Remote models (those without llamaCpp GGUF details) get a pi provider entry.
  # Local models are handled by llama-cpp.nix.
  # ACP-based models (e.g. opencode) are excluded since they use a different protocol.
  remoteModels = builtins.filter (m: m.llamaCpp == null && m.acp == null) aiModels;

  # Build one pi provider per remote model, keyed by the model's short name.
  remoteProviders = lib.listToAttrs (
    map (m: {
      name = m.name;
      value = {
        baseUrl = m.baseUrl + "/v1";
        api = "openai-completions";
        apiKey = m.apiKey;
        authHeader = m.apiKey != null;
        compat = {
          supportsDeveloperRole = true;
          supportsReasoningEffort = m.reasoning;
        };
        models = [
          {
            id = m.model;
            name = m.label;
            reasoning = m.reasoning;
            input = [ "text" ];
            contextWindow = m.contextWindow;
            maxTokens = m.maxTokens;
          }
        ];
      };
    }) remoteModels
  );

  # User-specified and llama-cpp.nix providers take precedence over auto-derived.
  allProviders = remoteProviders // cfg.providers;

  # ── Derive default provider and model from ai.default ──────────────────────
  defaultFromAi =
    let
      model = lib.findFirst (m: m.name == aiDefault) null aiModels;
    in
    if model != null then
      {
        defaultProvider = model.name;
        defaultModel = model.model;
      }
    else
      null;

  # Base defaults from ai.default, overridable via cfg.settings.
  resolvedSettings =
    (lib.optionalAttrs (defaultFromAi != null) {
      defaultProvider = defaultFromAi.defaultProvider;
      defaultModel = defaultFromAi.defaultModel;
    })
    // cfg.settings;
in
{
  options.programs.pi = {
    enable = lib.mkEnableOption "pi coding agent configuration";

    providers = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Provider definitions written to pi's models.json.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Settings written to pi's settings.json.";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "npm:pi-web-access"
        "git:github.com/user/repo@v1"
      ];
      description = ''
        Pi packages to install, written to settings.json.
        Since settings.json is a read-only nix store symlink, `pi install`
        cannot persist packages — declare them here instead.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.pi ];

    home.sessionVariables = {
      PI_AGENT_DIR = "${config.xdg.configHome}/pi";
      PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi/agent/";
    };

    xdg.configFile."pi/agent/models.json" = lib.mkIf (allProviders != { }) {
      text = builtins.toJSON { providers = allProviders; };
    };

    xdg.configFile."pi/agent/settings.json" =
      lib.mkIf (resolvedSettings != { } || cfg.packages != [ ])
        {
          text = builtins.toJSON (
            resolvedSettings
            // lib.optionalAttrs (cfg.packages != [ ]) {
              packages = cfg.packages;
            }
          );
        };
  };
}
