{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.hunk;
in
{
  options.programs.hunk = {
    enable = lib.mkEnableOption "the hunk terminal diff viewer";
  };

  config = lib.mkIf cfg.enable {
    # pkgs.hunk comes from the upstream modem-dev/hunk flake (see the `hunk`
    # overlay in overlays.nix), not llm-agents.nix release builds.
    home.packages = [ pkgs.hunk ];

    # link skills
    home.file = 
      lib.genAttrs
        [
          ".claude/skills/hunk-review"
          ".config/pi/agent/skills/hunk-review"
        ]
        (_: {
          source = "${pkgs.hunk}/skills/hunk-review";
        });
  };
}
