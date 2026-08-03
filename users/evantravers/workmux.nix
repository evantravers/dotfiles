{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.workmux;
  yaml' = pkgs.formats.yaml { };

  # Generate key table bindings
  mkTableBind =
    key: cmd: "bind-key -T workmux ${lib.replaceStrings [ ";" ] [ "\\;" ] key} run-shell \"${cmd}\"";

  tmuxConfig = lib.concatStringsSep "\n" (
    [
      "# Workmux key table"
    ]
    ++ (lib.mapAttrsToList mkTableBind cfg.tmux.keybindings)
    ++ [
      ""
      "# Enter workmux mode"
      "bind-key ${cfg.tmux.enterKey} switch-client -T workmux"
    ]
  );

  # Replicate a devenv 2.2+ out-of-tree binding (`devenv allow --from ...`)
  # from the main checkout into a new worktree. Bindings live in
  # ~/.local/share/devenv/allowed keyed by absolute project path, so a
  # worktree (a different path) has no environment without this.
  devenvRebind = pkgs.writeShellApplication {
    name = "workmux-devenv-rebind";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      allowed="''${XDG_DATA_HOME:-$HOME/.local/share}/devenv/allowed"
      root="''${WM_PROJECT_ROOT:?}"

      [ -f "$allowed" ] || exit 0
      command -v devenv >/dev/null || exit 0

      entry=$(jq -c --arg root "$root" 'select(.path == $root and .from != null)' "$allowed" | head -n1)
      [ -n "$entry" ] || exit 0

      from=$(jq -r '.from' <<<"$entry")
      case "$from" in
        *:*) ;;                                            # flake ref or path:/abs
        /*)  from="path:$from" ;;                          # absolute path
        *)   from="path:$(cd "$root/$from" && pwd)" ;;     # relative to main checkout
      esac

      args=(--from "$from")
      while IFS= read -r profile; do
        args+=(--profile "$profile")
      done < <(jq -r '.profiles[]? // empty' <<<"$entry")

      devenv allow "''${args[@]}"
    '';
  };

  # Drop the worktree's devenv binding when the worktree is removed.
  devenvUnbind = pkgs.writeShellApplication {
    name = "workmux-devenv-unbind";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      allowed="''${XDG_DATA_HOME:-$HOME/.local/share}/devenv/allowed"
      wt="''${WM_WORKTREE_PATH:?}"

      [ -f "$allowed" ] || exit 0

      tmp=$(mktemp)
      jq -c --arg wt "$wt" 'select(.path != $wt)' "$allowed" > "$tmp"
      mv "$tmp" "$allowed"
    '';
  };
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
      default = {
        wm = "workmux";
      };
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
          "d" = "tmux display-popup -E -w 80% -h 80% workmux dashboard";
          "n" = "workmux sidebar next";
          "p" = "workmux sidebar prev";
          "l" = "workmux last-done";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      devenvRebind
      devenvUnbind
    ];

    xdg.configFile."workmux/config.yaml" = lib.mkIf (cfg.settings != { }) {
      source = yaml'.generate "workmux-config" cfg.settings;
    };

    programs.fish.shellAliases = cfg.shellAliases;

    programs.tmux.extraConfig = lib.mkIf config.programs.tmux.enable tmuxConfig;
  };
}
