# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ pkgs, ... }:

{
  imports = [
    # include NixOS-WSL modules
  ];

  nixpkgs.config.allowUnfree = true;

  environment = {
    systemPackages = with pkgs; [
      socat
      wslu
      wsl-open
      wezterm.terminfo
    ];
  };

  programs.fish = {
    shellInit = ''
    set -gx SSH_AUTH_SOCK '/home/evantravers/.1password/agent.sock'
    '';
    interactiveShellInit =
      # run 1password agent bride
      ''
      # .config/.agent-bridge.sh
      _1password_agent_wsl
      '';
  };

  networking.hostName = "wsl";

  wsl = {
    enable = true;
    defaultUser = "evantravers";
    interop.includePath = true;
  };
}
