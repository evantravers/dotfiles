{ pkgs, lib, ... }:
{
  programs.jujutsu = {
    enable = true;
    package = pkgs.unstable.jujutsu;
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
      templates.draft_commit_description = ''
          concat(
            coalesce(description, default_commit_description, "\n"),
            surround(
              "\nJJ: This commit contains the following changes:\n", "",
              indent("JJ:     ", diff.stat(72)),
            ),
            "\nJJ: ignore-rest\n",
            diff.git(),
          )
      '';
    };
  };
}
