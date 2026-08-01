{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.pi;
in
{
  options.programs.pi = {
    enable = lib.mkEnableOption "pi coding agent configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.pi ];

    home.sessionVariables = {
      PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi/agent/";
    };
  };
}
