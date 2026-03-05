{ pkgs, ... }:
{
  accounts.email.accounts.gmail = {
    primary = true;
    aerc.enable = true;
    himalaya.enable = true;

    address = "evantravers@gmail.com";
    userName = "evantravers@gmail.com";
    realName = "Evan Travers";
    folders = {
      inbox = "INBOX";
      sent = "\[Gmail\]/Sent\ Mail";
      trash = "\[Gmail\]/Trash";
    };
    passwordCommand = "op read op://Private/a3v65jhzsq4lpiunlcf6fceesa/password";
    flavor = "gmail.com";
  };

  programs = {
    aerc = {
      enable = true;
      extraConfig = {
        general.unsafe-accounts-conf = true;
        viewer = {
          pager = "${pkgs.less}/bin/less -R";
        };
        filters = {
          "text/plain" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
          "text/calendar" = "${pkgs.aerc}/libexec/aerc/filters/calendar";
          "text/html" = "${pkgs.aerc}/libexec/aerc/filters/html";
          "message/delivery-status" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
          "message/rfc822" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
        };
        ui = {
          threading-enabled = true;
          show-thread-context = true;
          styleset-name = "dracula";
          border-char-vertical = "┃";
          spinner = "[ ⡿ ],[ ⣟ ],[ ⣯ ],[ ⣷ ],[ ⣾ ],[ ⣽ ],[ ⣻ ],[ ⢿ ]";
        };
      };
    };
    himalaya.enable = true;
  };
}
