{ config, lib, pkgs, ... }:

let
  cfg = config.programs.pi;
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
      example = [ "npm:pi-web-access" "git:github.com/user/repo@v1" ];
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

    xdg.configFile."pi/agent/models.json" = lib.mkIf (cfg.providers != { }) {
      text = builtins.toJSON { providers = cfg.providers; };
    };

    xdg.configFile."pi/agent/settings.json" = lib.mkIf (cfg.settings != { } || cfg.packages != [ ]) {
      text = builtins.toJSON (cfg.settings // lib.optionalAttrs (cfg.packages != [ ]) {
        packages = cfg.packages;
      });
    };
  };
}
