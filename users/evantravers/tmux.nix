{pkgs, lib, ...}:
{
  programs.tmux = {
    enable = true;
    escapeTime = 10;
    prefix = "C-space";
    sensibleOnTop = false;
    shell = "${pkgs.fish}/bin/fish";
    terminal = if pkgs.stdenv.isDarwin then "xterm-ghostty" else "wezterm";

    extraConfig = lib.fileContents .config/tmux/.tmux.conf;

    plugins = with pkgs.tmuxPlugins; [
      logging
      pain-control
      sessionist
      session-wizard
      tmux-thumbs
      yank
    ];
  };
}
