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
  rebind = pkgs.writeShellApplication {
    name = "workmux-devenv-rebind";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      allowed="''${XDG_DATA_HOME:-$HOME/.local/share}/devenv/allowed"
      root="''${WM_PROJECT_ROOT:?}"

      [ -f "$allowed" ] || exit 0
      command -v devenv >/dev/null || exit 0

      # Latest entry for the main checkout wins, whether it's a plain
      # auto-activation trust or an out-of-tree (--from) binding
      entry=$(jq -c --arg root "$root" 'select(.path == $root)' "$allowed" | tail -n1)
      [ -n "$entry" ] || exit 0

      from=$(jq -r '.from // empty' <<<"$entry")
      if [ -z "$from" ]; then
        # In-tree devenv.nix is checked out in the worktree; just grant trust
        devenv allow
        exit 0
      fi
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

  # amx-style launcher: pick a project (default: current repo, or any sesh),
  # write a prompt, and let workmux spin up a worktree + agent window.
  # The agent is workmux's configured default (global config: pi; projects
  # can override with `agent:` in .workmux.yaml).
  wmx = pkgs.writeShellApplication {
    name = "wmx";
    runtimeInputs = with pkgs; [
      gum
      sesh
      jq
      tmux
      git
      coreutils
    ];
    text = ''
      set -euo pipefail

      if [ "''${1:-}" = "-h" ] || [ "''${1:-}" = "--help" ]; then
        echo "Usage: wmx [prompt…]"
        echo
        echo "Pick a project, describe a task, and launch a workmux worktree"
        echo "with an agent working on it. With a prompt argument, skips the"
        echo "pickers and uses the current repo."
        exit 0
      fi

      # Non-interactive: `wmx "fix the flaky test"` uses the current repo
      prompt="''${*:-}"

      current_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      current_name=$(basename "$current_root")

      path="$current_root"
      session=""

      # User aborts (Esc/ctrl-c in gum) are not errors: exit 0 quietly so
      # tmux doesn't report "wmx returned 1". Real failures (e.g. from
      # workmux add) still exit non-zero and get flagged.
      if [ -z "$prompt" ]; then
        choice=$(gum choose --header "Where should the agent work?" \
          "Current project: $current_name" \
          "Pick another project…") || exit 0
        if [ "$choice" = "Pick another project…" ]; then
          # Session name: authoritative for existing/configured sessions,
          # directory basename otherwise (matches how sesh names new ones)
          selection=$(sesh list --json -dH \
            | jq -r '.[] | (if .Src == "tmux" or .Src == "config" then .Name else (.Path | sub("/$";"") | split("/") | last) end) as $s | "\($s)\t\(.Path)\t\(.Icon // "")"' \
            | gum filter --placeholder "Pick a project…") || exit 0
          session=$(printf '%s' "$selection" | cut -f1)
          path=$(printf '%s' "$selection" | cut -f2)
        fi

        prompt=$(gum write --header "Task for the agent" \
          --placeholder "Describe the task… (ctrl-d when done)" \
          --char-limit 0 --height 8) || exit 0
      fi

      args=()
      if [ -n "$prompt" ]; then
        # Branch name auto-generated from the prompt
        args=(-A -p "$prompt")
      else
        # No task: plain worktree, titled by hand (old `wm add` habit)
        title=$(gum input --placeholder "Worktree title (empty to abort)") || exit 0
        [ -n "$title" ] || exit 0
        args=("$title")
      fi

      cd "$path"

      add_args=(--background)
      if [ -n "''${TMUX:-}" ]; then
        # Panes open as plain shells; wmx launches the agent itself once
        # the shell is ready. workmux send-keys's pane commands the
        # instant the window opens, and in devenv projects fish + the
        # devenv hook take 10s+ to reach a prompt — the keystrokes get
        # echoed but flushed before fish ever reads them.
        add_args+=(--no-pane-cmds)
        [ -n "$prompt" ] && add_args+=(--prompt-file-only)
      fi
      if [ -n "$session" ]; then
        # Another project: the worktree window belongs in that project's
        # sesh session, creating it first if needed.
        # (has-session's -t parsing chokes on names containing . or :,
        # so match exactly against list-sessions instead)
        tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -Fxq "$session" \
          || tmux new-session -d -s "$session" -c "$path"
        add_args+=(--parent-session "$session")
        where="session '$session'"
      else
        where="this session"
      fi

      # Stream output live (workmux can ask interactive confirms, e.g.
      # installing agent status-tracking skills), but also capture it so
      # name collisions can be detected and retried
      output_file=$(mktemp)
      trap 'rm -f "$output_file"' EXIT

      try_add() {
        workmux add "''${add_args[@]}" "$@" 2>&1 | tee "$output_file"
      }

      if ! try_add "''${args[@]}"; then
        if ! grep -qi 'already exists' "$output_file"; then
          # Genuine failure: output already shown, exit non-zero (tmux
          # -EE keeps the popup open so the error stays visible)
          exit 1
        fi
        # The LLM-generated name collided with an existing worktree:
        # let the user name it explicitly, keeping the prompt
        gum style --foreground 1 "That name is already taken by another worktree."
        while :; do
          title=$(gum input --header "Name it yourself" \
            --placeholder "branch/worktree name (empty to abort)") || exit 0
          [ -n "$title" ] || exit 0
          retry=("$title")
          [ -n "$prompt" ] && retry+=(-p "$prompt")
          : > "$output_file"
          if try_add "''${retry[@]}"; then
            break
          elif grep -qi 'already exists' "$output_file"; then
            gum style --foreground 1 "Also taken, try another."
          else
            exit 1
          fi
        done
      fi

      # Stay where we are; confirm via the status line (the popup closes
      # on success, so an echo would never be seen there)
      if [ -n "''${TMUX:-}" ]; then
        tmux display-message "wmx: worktree created in $where, agent starting…"
      fi

      # Launch the agent ourselves, now that the window exists. Find the
      # focused pane of the new window by its cwd, wait for the shell to
      # reach a prompt, then send the command.
      if [ -n "''${TMUX:-}" ]; then
        branch=$(sed -n "s/.*worktree and tmux window for '\([^']*\)'.*/\1/p" "$output_file" | tail -1)
        wt_path=$(sed -n 's/^ *Worktree: //p' "$output_file" | tail -1 | tr -d '[:space:]')

        agent_name=pi
        if [ -f .workmux.yaml ]; then
          a=$(sed -n 's/^agent:[[:space:]]*//p' .workmux.yaml | head -1)
          [ -n "$a" ] && agent_name="$a"
        fi

        pane=""
        for _ in $(seq 1 30); do
          pane=$(tmux list-panes -a -F '#{pane_id} #{pane_active} #{pane_current_path}' \
            | awk -v p="$wt_path" '$2 == 1 && $3 == p {print $1; exit}')
          [ -n "$pane" ] && break
          sleep 1
        done

        if [ -n "$pane" ]; then
          # Wait for the first prompt (starship ❯) — i.e. fish init and
          # any devenv hook activation have finished. On timeout, send
          # anyway: a late command is better than none.
          for _ in $(seq 1 90); do
            tmux capture-pane -p -t "$pane" 2>/dev/null | grep -q '❯' && break
            sleep 2
          done

          if [ -n "$prompt" ]; then
            case "$agent_name" in
              # Match workmux's per-agent prompt-passing conventions
              claude) launch="wmx-agent claude -- \"\$(cat .workmux/PROMPT-$branch.md)\"" ;;
              *)      launch="wmx-agent $agent_name \"\$(cat .workmux/PROMPT-$branch.md)\"" ;;
            esac
          else
            launch="wmx-agent $agent_name"
          fi
          tmux send-keys -t "$pane" "$launch" Enter
        fi
      fi
    '';
  };

  # Run a command (an agent) inside the project's devenv environment.
  # Rather than activating devenv in the worktree itself (gitignored
  # devenv.nix files are missing there, and a fresh worktree can trigger
  # a multi-minute env build), resolve the project's devenv binding —
  # the same one the fish hook uses — and run the command with
  # `devenv shell --from <source>`. The main checkout's env is already
  # built and trusted, so this is warm (~seconds), and the command still
  # runs with the worktree as its cwd.
  wmx-agent = pkgs.writeShellApplication {
    name = "wmx-agent";
    runtimeInputs = with pkgs; [
      devenv
      jq
      git
      coreutils
    ];
    text = ''
      set -euo pipefail

      allowed="''${XDG_DATA_HOME:-$HOME/.local/share}/devenv/allowed"

      # Main checkout for this worktree (git-common-dir is <main>/.git)
      common=$(git rev-parse --git-common-dir 2>/dev/null || true)
      [ -n "$common" ] || exec "$@"
      main=$(cd "$common/.." && pwd)

      # Binding lookup: the worktree itself first (workmux-devenv-rebind
      # copies bindings into new worktrees), then the main checkout
      entry=""
      if [ -f "$allowed" ]; then
        for p in "$PWD" "$main"; do
          entry=$(jq -c --arg p "$p" 'select(.path == $p)' "$allowed" | tail -n1)
          [ -n "$entry" ] && break
        done
      fi

      if [ -n "$entry" ]; then
        from=$(jq -r '.from // empty' <<<"$entry")
        case "$from" in
          "")  from="path:$main" ;;                        # plain in-tree trust
          *:*) ;;                                          # flake ref or path:/abs
          /*)  from="path:$from" ;;                        # absolute path
          *)   from="path:$(cd "$main/$from" && pwd)" ;;   # relative to main checkout
        esac
        args=(--from "$from")
        while IFS= read -r profile; do
          args+=(--profile "$profile")
        done < <(jq -r '.profiles[]? // empty' <<<"$entry")
        exec devenv shell "''${args[@]}" -- "$@"
      fi

      # No binding, but the project has an in-tree devenv: reuse the main
      # checkout's (already built, already trusted) environment
      if [ -f "$main/devenv.nix" ] || [ -f "$main/devenv.yaml" ]; then
        exec devenv shell --from "path:$main" -- "$@"
      fi

      exec "$@"
    '';
  };

  # Drop the worktree's devenv binding when the worktree is removed.
  unbind = pkgs.writeShellApplication {
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
          "a" = "tmux display-popup -EE -w 72 -h 20 wmx";
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
      rebind
      unbind
      wmx
      wmx-agent
    ];

    xdg.configFile."workmux/config.yaml" = lib.mkIf (cfg.settings != { }) {
      source = yaml'.generate "workmux-config" cfg.settings;
    };

    programs.fish.shellAliases = cfg.shellAliases;

    programs.tmux.extraConfig = lib.mkIf config.programs.tmux.enable tmuxConfig;
  };
}
