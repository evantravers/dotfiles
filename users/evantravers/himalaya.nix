{pkgs, ...}:
{
  home.packages = with pkgs; [
    unstable.himalaya
  ];

  # TODO: Put this in attrset as soon as home-manager is fixed
  xdg.configFile."himalaya/config.toml".text = ''
  [accounts.gmail]
  default = true
  email = "evantravers@gmail.com"
  display-name = "evantravers"
  folder.aliases.inbox = "INBOX"
  folder.aliases.sent = "[Gmail]/Sent Mail"
  folder.aliases.drafts = "[Gmail]/Drafts"
  folder.aliases.trash = "[Gmail]/Trash"
  downloads-dir = "/Users/evantravers/Downloads"
  backend.type = "imap"
  backend.host = "imap.gmail.com"
  backend.port = 993
  backend.login = "evantravers@gmail.com"
  backend.encryption.type = "tls"
  backend.auth.type = "password"
  backend.auth.command = "op read op://Private/a3v65jhzsq4lpiunlcf6fceesa/password"
  message.send.backend.type = "smtp"
  message.send.backend.host = "smtp.gmail.com"
  message.send.backend.port = 465
  message.send.backend.login = "evantravers@gmail.com"
  message.send.backend.encryption.type = "tls"
  message.send.backend.auth.type = "password"
  message.send.backend.auth.command = "op read op://Private/a3v65jhzsq4lpiunlcf6fceesa/password"
  '';
}

