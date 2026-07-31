{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.pi;

  # llama-cpp.nix injects the local provider via cfg.providers; remote
  # providers are configured interactively via `pi /login`.
  allProviders = cfg.providers;

in
{
  options.programs.pi = {
    enable = lib.mkEnableOption "pi coding agent configuration";

    providers = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Provider definitions written to pi's models.json.";
    };

  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.pi ];

    home.sessionVariables = {
      PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi/agent/";
    };

    xdg.configFile."pi/agent/models.json" = lib.mkIf (allProviders != { }) {
      text = builtins.toJSON { providers = allProviders; };
    };

  };
}
