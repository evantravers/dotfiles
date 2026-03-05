{ pkgs, lib, ... }:
{
  programs.jujutsu = {
    enable = true;
    package = pkgs.jujutsu;
    settings = {
      user = {
        name = "Evan Travers";
        email = "evantravers@gmail.com";
      };
      ui.default-command = "log";
      fix.tools.nixfmt = {
        command = [
          "${lib.getExe pkgs.nixfmt-rfc-style}"
          "--strict"
          "--filename=$path"
        ];
        patterns = [ "glob:'**/*.nix'" ];
      };
      templates = {
        draft_commit_description = "builtin_draft_commit_description_with_diff";
      };
    };
  };
}
