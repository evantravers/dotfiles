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

  home-manager.users.evantravers.programs.fish = {
    shellInit = ''
    set -gx SSH_AUTH_SOCK '/home/evantravers/.1password/agent.sock'
    '';
    interactiveShellInit =
      # run 1password agent bridge
      ''
      # .config/.agent-bridge.sh
      _1password_agent_wsl
      '';
    functions = {
      op = {
        description = "Use Host Win11 1Password";
        wraps = "op.exe";
        body = ''
          op.exe $argv
        '';
      };
      _1password_agent_wsl = {
        description = "Creates socat npiperelay with windows-based 1Password";
        body = ''
        set -gx SSH_AUTH_SOCK $HOME/.1password/agent.sock
        # need `ps -ww` to get non-truncated command for matching
        # use square brackets to generate a regex match for the process we want but that doesn't match the grep command running it!
        set ALREADY_RUNNING (
                ps -auxww | grep -q "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent"
          echo $status)
        if test $ALREADY_RUNNING != "0"
                if test -S $SSH_AUTH_SOCK
                        # not expecting the socket to exist as the forwarding command isn't running (http://www.tldp.org/LDP/abs/html/fto.html)
                        echo "removing previous socket..."
                        rm $SSH_AUTH_SOCK
          end
                echo "Starting SSH-Agent relay..."
                # setsid to force new session to keep running
                # set socat to listen on $SSH_AUTH_SOCK and forward to npiperelay which then forwards to openssh-ssh-agent on windows
          set agent (setsid socat "UNIX-LISTEN:$SSH_AUTH_SOCK,fork" "EXEC:/mnt/c/Users/Tower/scoop/shims/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) &>/dev/null
          disown
        end
        '';
      };
    };
  };

  networking.hostName = "wsl";

  wsl = {
    enable = true;
    defaultUser = "evantravers";
    interop.includePath = true;
  };
}
