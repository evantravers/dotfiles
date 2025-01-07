{pkgs, lib, ...}:
{
  programs.tmux = {
    enable = true;
    escapeTime = 10;
    prefix = "C-space";
    sensibleOnTop = false;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "xterm-256color";

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
