{ config, lib, pkgs, ... }:
let
  cfg = config.programs.workmux;
  yaml' = pkgs.formats.yaml { };

  # Generate key table bindings
  mkTableBind = key: cmd: "bind-key -T workmux ${lib.replaceStrings [";"] ["\\;"] key} run-shell \"${cmd}\"";

  tmuxConfig = lib.concatStringsSep "\n" ([
    "# Workmux key table"
  ] ++ (lib.mapAttrsToList mkTableBind cfg.tmux.keybindings) ++ [
    ""
    "# Enter workmux mode"
    "bind-key ${cfg.tmux.enterKey} switch-client -T workmux"
  ]);
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
      enterKey = lib.mkOption {
        description = "Key to enter workmux mode (with prefix).";
        type = lib.types.str;
        default = "C-w";
      };

      keybindings = lib.mkOption {
        description = "Keybindings active in workmux mode (no prefix needed).";
        type = lib.types.attrsOf lib.types.str;
        default = {
          "s" = "workmux sidebar";
          "a" = ''workmux add "$(gum input --placeholder 'Worktree title')"'';
          "d" = ''tmux display-popup -E -w 80% -h 80% workmux dashboard'';
          "n" = "workmux sidebar next";
          "p" = "workmux sidebar prev";
          "l" = "workmux last-done";
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

    programs.tmux.extraConfig = lib.mkIf config.programs.tmux.enable tmuxConfig;
  };
}
