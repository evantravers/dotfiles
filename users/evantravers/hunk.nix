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
    home.packages = [ pkgs.llm-agents.hunk ];

    # link skills
    home.file = 
      lib.genAttrs
        [
          ".claude/skills/hunk-review"
          ".config/pi/agent/skills/hunk-review"
        ]
        (_: {
          source = "${pkgs.llm-agents.hunk}/skills/hunk-review";
        });
  };
}
