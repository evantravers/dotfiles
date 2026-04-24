{ pkgs, ... }:
{
  home.packages = with pkgs; [
    unstable.llama-cpp
  ];
}
