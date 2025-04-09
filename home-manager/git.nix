{...}:
{
  home.file = {
    ".gitconfig".source = ../.config/git/.gitconfig;
    ".gitconfig".force = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
  };
}
