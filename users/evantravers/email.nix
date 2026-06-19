{ config, lib, ... }:
let
  passwordCommand = "op read op://Private/a3v65jhzsq4lpiunlcf6fceesa/password";
in

{
  options.programs.email.enable = lib.mkEnableOption "email configuration";

  config = lib.mkIf config.programs.email.enable {
    accounts.email.accounts.gmail = {
      primary = true;

      address = "evantravers@gmail.com";
      userName = "evantravers@gmail.com";
      realName = "Evan Travers";
      folders = {
        inbox = "INBOX";
        sent = "\[Gmail\]/Sent\ Mail";
        trash = "\[Gmail\]/Trash";
      };
      passwordCommand = passwordCommand;
      flavor = "gmail.com";

      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };

      smtp = {
        host = "smtp.gmail.com";
        tls.enable = true;
      };
    };

    programs.meli = {
      # enable = true;
      settings = {
        terminal.theme = "dark";
      };
    };
  };
}
