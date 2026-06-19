{ pkgs, lib, ... }:

{
  environment.systemPackages = [ pkgs.orbstack ];

  home-manager.users.evantravers = {
    programs.ssh = {
      extraConfig = lib.optionalString pkgs.stdenv.isDarwin ''
        Include ~/.orbstack/ssh/config
      '';
    };
  };
}
