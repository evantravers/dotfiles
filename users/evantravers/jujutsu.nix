{
  pkgs,
  lib,
  config,
  ...
}:
let
  jjc = pkgs.callPackage ./jjc { };
in
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
      templates = {
        draft_commit_description = "builtin_draft_commit_description_with_diff";
      };
    };
  };

  home.packages = [ jjc ] ++ lib.optional config.programs.starship.enable pkgs.unstable.jj-starship;

  programs.fish = {
    binds = {
      "alt-o".command = "jj_desc_wrap";
    };
    functions = {
      jj_desc_wrap = {
        description = "Wrap previous token or history command in jj desc -m \"\"";
        body = ''
          set -l tokens (commandline -pc)
          set -l token $tokens[-1]
          if test -z "$token"
            set token (history --max=1 | head -1)
          end
          if test -z "$token"
            commandline -i "jj desc -m \"\" "
            commandline -C 12
          else
            commandline -r -- "jj desc -m \"$token\""
            commandline -C 12
          end
          commandline -f repaint
        '';
      };
    };
  };
}
