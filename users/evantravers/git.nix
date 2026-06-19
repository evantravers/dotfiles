{ config, lib, ... }:
{
  config = lib.mkIf config.programs.git.enable {
    home.file = {
      ".cvsignore".source = .config/git/.cvsignore;
      ".gitconfig".source = .config/git/.gitconfig;
    };
  };
}
