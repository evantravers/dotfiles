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

      # Prompt-less launch: fall back to a hand-typed worktree title
      title=""
      if [ -z "$prompt" ]; then
        title=$(gum input --placeholder "Worktree title (empty to abort)") || exit 0
        [ -n "$title" ] || exit 0
      fi

      # Everything after this point — branch naming, provisioning, hooks,
      # agent launch — happens in the background. The user only hears
      # back via tmux notifications: an issue, or "created".
      prompt_file=$(mktemp)
      printf '%s' "$prompt" > "$prompt_file"

      if [ -n "''${TMUX:-}" ]; then
        nohup ${wmxCreate}/bin/wmx-create "$path" "$session" "$prompt_file" "$title" \
          </dev/null >/dev/null 2>&1 &
        tmux display-message "wmx: creating worktree in the background…"
      else
        ${wmxCreate}/bin/wmx-create "$path" "$session" "$prompt_file" "$title"
      fi
    '';
  };

  # Detached worker spawned by wmx: runs workmux add (auto-naming via pi,
  # provisioning, hooks), reports outcome via tmux display-message, and
  # hands off to wmx-launch for the agent start. Name collisions are
  # retried with a numeric suffix since there is no user to ask.
  wmxCreate = pkgs.writeShellApplication {
    name = "wmx-create";
    runtimeInputs = with pkgs; [
      cfg.package
      tmux
      coreutils
      gnugrep
      gnused
    ];
    text = ''
      set -uo pipefail

      path=$1
      session=$2
      prompt_file=$3
      title=''${4:-}

      trap 'rm -f "$prompt_file"' EXIT

      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/wmx"
      mkdir -p "$state_dir"
      log="$state_dir/last-create.log"
      : > "$log"

      notify() {
        if [ -n "''${TMUX:-}" ]; then
          tmux display-message -d 8000 "wmx: $1"
        else
          echo "wmx: $1"
        fi
      }

      fail() {
        detail=$(grep -m1 -E '^(Error|Caused by:)' "$log" || true)
        notify "failed: $1 ''${detail:+— $detail}"
        exit 1
      }

      cd "$path" || fail "cd $path"

      args=(--background)
      if [ -n "''${TMUX:-}" ]; then
        # Panes open as plain shells; wmx-launch delivers the agent
        # command once the shell is ready (workmux send-keys's pane
        # commands before fish is initialized and they get flushed)
        args+=(--no-pane-cmds)
        [ -s "$prompt_file" ] && args+=(--prompt-file-only)
      fi

      if [ -n "$session" ]; then
        # Another project: the worktree window belongs in that project's
        # sesh session, creating it first if needed.
        # (has-session's -t parsing chokes on names containing . or :,
        # so match exactly against list-sessions instead)
        tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -Fxq "$session" \
          || tmux new-session -d -s "$session" -c "$path"
        args+=(--parent-session "$session")
        where="session '$session'"
      else
        where="this session"
      fi

      add_args=()
      if [ -s "$prompt_file" ]; then
        # Branch name auto-generated from the prompt (pi; no project env
        # needed)
        add_args=(-A -P "$prompt_file")
      elif [ -n "$title" ]; then
        add_args=("$title")
      else
        fail "no prompt or title"
      fi

      run_add() {
        if [ -n "''${TMUX:-}" ]; then
          workmux add "''${args[@]}" "$@" >>"$log" 2>&1
        else
          workmux add "''${args[@]}" "$@" 2>&1 | tee -a "$log"
        fi
      }

      suffix_note=""
      if ! run_add "''${add_args[@]}"; then
        # Auto-named branch already exists? Retry with numeric suffixes
        generated=$(sed -n "s/.*A worktree for branch '\([^']*\)' already exists.*/\1/p" "$log" | tail -1)
        if [ -z "$generated" ] || [ ! -s "$prompt_file" ]; then
          fail "workmux add"
        fi
        ok=""
        for n in 2 3 4 5; do
          : > "$log"
          if run_add "$generated-$n" -P "$prompt_file"; then
            ok="$generated-$n"
            break
          fi
          grep -q 'already exists' "$log" || break
        done
        [ -n "$ok" ] || fail "name kept colliding"
        suffix_note=" (renamed $ok)"
      fi

      branch=$(sed -n "s/.*worktree and tmux window for '\([^']*\)'.*/\1/p" "$log" | tail -1)
      wt_path=$(sed -n 's/^ *Worktree: //p' "$log" | tail -1 | tr -d '[:space:]')

      agent_name=pi
      if [ -f .workmux.yaml ]; then
        a=$(sed -n 's/^agent:[[:space:]]*//p' .workmux.yaml | head -1)
        [ -n "$a" ] && agent_name="$a"
      fi

      if [ -n "''${TMUX:-}" ]; then
        has_prompt=""
        [ -s "$prompt_file" ] && has_prompt=1
        nohup ${wmxLaunch}/bin/wmx-launch "$wt_path" "$agent_name" "$branch" "$has_prompt" \
          </dev/null >/dev/null 2>&1 &
      fi

      notify "created '$branch' in $where$suffix_note — agent starting"
    '';
  };

  # Spawned detached by wmx after the worktree exists: finds the new
  # window's focused pane, waits for its shell to reach a prompt (fish
  # init + devenv hook can take 10s+ in devenv projects), then sends the
  # agent command. Runs in the background so wmx — and its popup — can
  # exit immediately instead of blocking on worktree setup.
  wmxLaunch = pkgs.writeShellApplication {
    name = "wmx-launch";
    runtimeInputs = with pkgs; [
      tmux
      coreutils
      gnugrep
      gawk
    ];
    text = ''
      set -euo pipefail

      wt_path=$1
      agent_name=$2
      branch=$3
      has_prompt=''${4:-}

      # The agent pane is the focused one in the new window; find it by cwd
      pane=""
      for _ in $(seq 1 30); do
        pane=$(tmux list-panes -a -F '#{pane_id} #{pane_active} #{pane_current_path}' \
          | awk -v p="$wt_path" '$2 == 1 && $3 == p {print $1; exit}')
        [ -n "$pane" ] && break
        sleep 1
      done
      [ -n "$pane" ] || exit 1

      # Wait for the first prompt (starship ❯). On timeout, send anyway:
      # a late command is better than none.
      for _ in $(seq 1 90); do
        tmux capture-pane -p -t "$pane" 2>/dev/null | grep -q '❯' && break
        sleep 2
      done

      if [ -n "$has_prompt" ]; then
        case "$agent_name" in
          # Match workmux's per-agent prompt-passing conventions
          claude) launch="wmx-agent claude -- \"\$(cat .workmux/PROMPT-$branch.md)\"" ;;
          *)      launch="wmx-agent $agent_name \"\$(cat .workmux/PROMPT-$branch.md)\"" ;;
        esac
      else
        launch="wmx-agent $agent_name"
      fi
      tmux send-keys -t "$pane" "$launch" Enter
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
