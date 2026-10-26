{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rex;

  # rmx — git worktrees / jj workspaces + agent, rex multiplexer edition.
  #
  # Port of wmx with no tmux or workmux dependency: same gum UI, same
  # worktree layout (<repo>__worktrees/<branch>), and the devenv binding
  # from the main checkout is copied into the new worktree when one
  # exists. Windows and sessions live in rex. The script is shared
  # verbatim with users/evantravers/bin/rmx for iteration outside the
  # nix store.
  rmx = pkgs.writeShellApplication {
    name = "rmx";
    runtimeInputs = with pkgs; [
      gum
      sesh
      jq
      git
      jujutsu
      devenv
      coreutils
      gnugrep
      gnused
      gawk
      llm-agents.pi
      # rex defaults panes to the macOS account shell (zsh); rmx passes
      # the preferred shell explicitly (overridable via RMX_SHELL)
      config.programs.fish.package
    ];
    text = builtins.readFile ./bin/rmx;
  };

  # Run a command (an agent) inside the project's devenv environment.
  # rmx copies the main checkout's devenv binding into the worktree at
  # create time; here we resolve that binding (the same one the fish
  # hook uses) and run the command with `devenv shell --from <source>`.
  # The main checkout's env is already built and trusted, so this is
  # warm (~seconds), and the command still runs with the worktree as
  # its cwd.
  rmxAgent = pkgs.writeShellApplication {
    name = "rmx-agent";
    runtimeInputs = with pkgs; [
      devenv
      jq
      git
      coreutils
    ];
    text = ''
      set -euo pipefail

      allowed="''${XDG_DATA_HOME:-$HOME/.local/share}/devenv/allowed"

      # Main checkout for this worktree/workspace: RMX_MAIN from rmx,
      # else git's common dir (git worktrees), else this directory
      main="''${RMX_MAIN:-}"
      if [ -z "$main" ]; then
        common=$(git rev-parse --git-common-dir 2>/dev/null || true)
        [ -n "$common" ] && main=$(cd "$common/.." && pwd)
      fi
      [ -n "$main" ] || main=$PWD

      # Binding lookup: the worktree itself first (rmx copies bindings
      # into new worktrees), then the main checkout
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
in
{
  options.programs.rex = {
    enable = lib.mkEnableOption "rex integration (rmx worktree agent launcher)";
  };

  config = lib.mkIf cfg.enable {
    # The rex CLI itself is app-managed and expected on PATH.
    home.packages = [
      rmx
      rmxAgent
    ];
  };
}
