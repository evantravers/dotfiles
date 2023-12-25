{ pkgs, ... }:

{
  # https://devenv.sh/basics/
  packages = [
    pkgs.git
    pkgs.lua-language-server
    pkgs.nixd
  ];

  # https://devenv.sh/scripts/
  enterShell = ''
  '';
}
