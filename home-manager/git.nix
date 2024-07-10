{...}:
{
  home.file = {
    ".cvsignore".source = ../.config/git/.cvsignore;
    ".gitconfig".source = ../.config/git/.gitconfig;
  };

  programs.git = {
    enable = true;

    lfs.enable = true;
  };
}
