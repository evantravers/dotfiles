{ pkgs, lib, config, ... }:

{
  options.programs.orbstack.enable = lib.mkEnableOption "OrbStack";

  config = lib.mkIf config.programs.orbstack.enable {
    environment.systemPackages = [ pkgs.orbstack ];

    home-manager.users.evantravers = {
      programs.ssh = {
        extraConfig = lib.optionalString pkgs.stdenv.isDarwin ''
          Include ~/.orbstack/ssh/config
        '';
      };
    };
  };
}
