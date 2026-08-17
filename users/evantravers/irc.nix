{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Summon helper: ensure a detached 'irc' tmux session with a 'tiny' window
  # exists (so the IRC connection and scrollback persist in `tmux ls`), then
  # switch the current client to it. Navigating away (prefix + window keys,
  # switch-client, etc.) just moves your view; the session keeps running.
  irc-summon = pkgs.writeShellApplication {
    name = "irc-summon";
    runtimeInputs = [
      pkgs.gnugrep
      pkgs.tiny
      pkgs.tmux
    ];
    text = ''
      # Toggle: if we're already in the irc session, jump back to the last window.
      if [ "$(tmux display-message -p '#{session_name}')" = "irc" ]; then
        tmux last-window || tmux switch-client -l
        exit 0
      fi
      if ! tmux has-session -t irc 2>/dev/null; then
        tmux new-session -d -s irc -n tiny tiny
      elif ! tmux list-windows -t irc -F '#{window_name}' | grep -qx tiny; then
        tmux new-window -t irc -n tiny tiny
      fi
      tmux switch-client -t irc:tiny
    '';
  };
in
{
  config = lib.mkIf config.programs.tiny.enable {
    home.packages = [ irc-summon ];

    programs.tmux.extraConfig = lib.mkIf config.programs.tmux.enable ''
      bind-key "I" run-shell "${irc-summon}/bin/irc-summon"
    '';

    programs.tiny = {
      settings = {
        servers = [
          {
            addr = "irc.libera.chat";
            port = 6697;
            tls = true;
            realname = "Evan";
            nicks = [ "evantravers" ];
            join = [
              "#elixir"
              "#lobsters"
              "#neovim"
              "#nethack"
              "#nixos"
            ];
            sasl = {
              username = "evantravers";
              password = {
                command = "op read op://Private/7ftnywolnvbyska745tklaayqe/password";
              };
            };
          }
        ];
        defaults = {
          nicks = [ "evantravers" ];
          realname = "Evan";
          join = [ ];
          tls = true;
        };
      };
    };
  };
}
