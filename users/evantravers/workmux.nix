{ config, lib, pkgs, ... }:
let
  cfg = config.programs.workmux;
  yaml' = pkgs.formats.yaml { };

  mkTmuxBind = key: cmd: "bind-key ${lib.replaceStrings [";"] ["\\;"] key} run-shell \"${cmd}\"";

  tmuxBindings = lib.concatStringsSep "\n" (
    lib.mapAttrsToList mkTmuxBind cfg.tmux.keybindings
  );
in
{
  options.programs.workmux = {
    enable = lib.mkEnableOption "workmux - parallel development in tmux with git worktrees";

    package = lib.mkPackageOption pkgs "workmux" { };

    settings = lib.mkOption {
      description = ''
        Configuration written to {file}`~/.config/workmux/config.yaml`.
        See <https://workmux.raine.dev/guide/configuration> for all options.
      '';
      type = lib.types.submodule { freeformType = yaml'.type; };
      default = { };
      example = lib.literalExpression ''
        {
          nerdfont = true;
          merge_strategy = "rebase";
          agent = "claude";
          panes = [
            { command = "<agent>"; focus = true; }
            { split = "horizontal"; }
          ];
        }
      '';
    };

    shellAliases = lib.mkOption {
      description = "Shell aliases for workmux.";
      type = lib.types.attrsOf lib.types.str;
      default = { wm = "workmux"; };
    };

    tmux = {
      keybindings = lib.mkOption {
        description = "Tmux keybindings (with prefix) for workmux commands.";
        type = lib.types.attrsOf lib.types.str;
        default = {
          "W" = "workmux sidebar";
          ";" = "workmux last-done";
          "C-n" = "workmux sidebar next";
          "C-p" = "workmux sidebar prev";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."workmux/config.yaml" = lib.mkIf (cfg.settings != { }) {
      source = yaml'.generate "workmux-config" cfg.settings;
    };

    programs.fish.shellAliases = cfg.shellAliases;

    programs.tmux.extraConfig = lib.mkIf config.programs.tmux.enable tmuxBindings;
  };
}
