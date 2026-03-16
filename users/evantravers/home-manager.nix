{ pkgs, lib, ... }:
{
  imports = [
    ./email.nix
    ./git.nix
    ./helix.nix
    ./irc.nix
    ./jujutsu.nix
    ./nvim.nix
    ./starship.nix
    ./tmux.nix
  ];

  xdg.enable = true;
  # TODO: move this to ./home-manager/modules/darwin or something
  xdg.configFile."hammerspoon" = lib.mkIf pkgs.stdenv.isDarwin { source = .config/hammerspoon; };
  xdg.configFile."kanata" = lib.mkIf pkgs.stdenv.isDarwin { source = .config/kanata; };
  xdg.configFile."ghostty".source = .config/ghostty;
  xdg.configFile."moxide/settings.toml".text = ''
    title_headings = false
  '';

  home = {
    stateVersion = "25.05";

    packages = with pkgs; [
      jj-starship
      llm-agents.beads
      llm-agents.claude-code
      llm-agents.claude-code-acp
      llm-agents.opencode
      llm-agents.openspec
      llm-agents.pi
      amber
      devenv
      gh
      gum
      harper
      lua-language-server
      markdown-oxide
      nil
      nixfmt-rfc-style
      ripgrep
      sesh
    ];
  };

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
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # N/A
      '';
      shellAliases = {
        opencode = "op run --no-masking -- opencode";
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    nh = {
      enable = true;
      package = pkgs.unstable.nh;
      clean.enable = true;
      flake = ../../.;
    };

    yazi = {
      enable = true;
      enableFishIntegration = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
