{ pkgs, ... }:
let
  passwordCommand = "op read op://Private/a3v65jhzsq4lpiunlcf6fceesa/password";
in

{
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
    enable = true;
    package = pkgs.unstable.meli;
    settings = {
      terminal.theme = "dark";

      accounts.gmail = {
        root_mailbox = "INBOX";
        format = "imap";
        server_hostname = "imap.gmail.com";
        server_port = "993";
        server_username = "evantravers@gmail.com";
        server_password_command = passwordCommand;
        identity = "evantravers@gmail.com";
        display_name = "Evan Travers";
        listing.index_style = "Conversations";
        composing.store_sent_mail = false;

        send_mail = {
          hostname = "smtp.gmail.com";
          port = 587;
          auth = {
            type = "auto";
            username = "evantravers@gmail.com";
            password = {
              type = "command_eval";
              value = passwordCommand;
            };
          };
          security.type = "STARTTLS";
        };
      };
    };
  };
}
