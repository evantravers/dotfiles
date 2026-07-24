{ lib, config, ... }:

{
  options.programs.omniwm.enable = lib.mkEnableOption "OmniWM window manager";

  config = lib.mkIf config.programs.omniwm.enable {
    homebrew = {
      taps = [
        {
          name = "BarutSRB/tap";
          trusted = true;
        }
      ];

      casks = [
        "omniwm"
      ];
    };
  };
}