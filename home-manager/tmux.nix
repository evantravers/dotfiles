{pkgs, lib, ...}:
{
  programs.tmux = {
    enable = true;
    sensibleOnTop = false;
    prefix = "C-space";
    escapeTime = 10;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "wezterm";

    extraConfig = lib.fileContents ../.config/tmux/.config/tmux/tmux.conf;

    plugins = with pkgs.tmuxPlugins; [
      logging
      pain-control
      sessionist
      tmux-thumbs
      yank
    ];
  };
}
