{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.programs.tmux.enable {
    home.packages = [ pkgs.sesh ];

    programs.tmux = {
      escapeTime = 10;
      prefix = "C-space";
      sensibleOnTop = false;
      shell = "${pkgs.fish}/bin/fish";
      terminal = if pkgs.stdenv.isDarwin then "xterm-ghostty" else "wezterm";

      extraConfig =
        lib.fileContents .config/tmux/.tmux.conf
        + ''
          bind-key "P" display-popup -T "#[align=centre,bg=colour8,fg=colour0]#[bold] 📂 Repositories " -E -b rounded -s "bg=default fg=default" -S "bg=default fg=colour8" -w 80% -h 80% "sesh picker -idH --preview --placeholder 'Pick a sesh'"
        '';

      plugins = with pkgs.tmuxPlugins; [
        pain-control
        sessionist
        yank
      ];
    };
  };
}
