{ pkgs, ... }:

{
  # https://devenv.sh/basics/
  packages = [ pkgs.git pkgs.lua-language-server ];

  # https://devenv.sh/scripts/
  enterShell = ''
  '';
}
