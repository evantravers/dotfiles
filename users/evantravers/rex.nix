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
      findutils
      gnugrep
      gnused
      gawk
      llm-agents.pi
      # rex defaults panes to the macOS account shell (zsh); rmx makes
      # this fish the panes' shell (overridable via RMX_SHELL)
      config.programs.fish.package
    ];
    text = builtins.readFile ./bin/rmx;
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
    ];
  };
}
