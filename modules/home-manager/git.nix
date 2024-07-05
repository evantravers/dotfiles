{...}:
{
  home.file = {
    ".cvsignore".source = ../../dotfiles/git/.cvsignore;
    ".gitconfig".source = ../../dotfiles/git/.gitconfig;
  };

  programs.git = {
    enable = true;

    lfs.enable = true;
  };
}
