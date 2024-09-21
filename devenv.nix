{ pkgs, ... }:

{
  # https://devenv.sh/packages/
  packages = [
    pkgs.lua-language-server
  ];
}
