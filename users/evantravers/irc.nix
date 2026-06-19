{ config, lib, ... }:
{
  config = lib.mkIf config.programs.tiny.enable {
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
              "#nethack"
              "#nixos"
              "#neovim"
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
