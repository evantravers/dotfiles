{ pkgs, lib, config, ... }:
let
  home = config.users.users.evantravers.home;
  activeLink = "${home}/.local/state/kanata/active.kbd";

  kanata-switch = pkgs.writeShellScriptBin "kanata-switch" ''
    #!/usr/bin/env bash
    set -euo pipefail

    CONFIG_DIR="$HOME/.config/kanata"
    ACTIVE_LINK="$HOME/.local/state/kanata/active.kbd"

    choice=$(basename -a "$CONFIG_DIR"/*.kbd | gum choose --header "Select kanata layout")

    ln -sfn "$CONFIG_DIR/$choice" "$ACTIVE_LINK"
    echo "Switched active kanata layout to $choice"

    sudo launchctl kickstart -k system/org.kanata
  '';
in
{
  options.kanata.enable = lib.mkEnableOption "kanata keyboard remapping and the karabiner-dk VirtualHIDDevice driver it depends on";

  config = lib.mkIf config.kanata.enable {
    environment.systemPackages = [
      pkgs.kanata
      pkgs.karabiner-dk
      kanata-switch
    ];

    # Activate the Karabiner DriverKit virtual HID driver during system activation.
    system.activationScripts.postActivation.text = ''
      # kanata-switch repoints this symlink to swap layouts at runtime without
      # a rebuild; seed it here so RunAtLoad has something to point at on a
      # fresh install.
      mkdir -p "${home}/.local/state/kanata"
      chown evantravers:staff "${home}/.local/state/kanata"
      if [ ! -e "${activeLink}" ]; then
        ln -sfn "${home}/.config/kanata/macbook.kbd" "${activeLink}"
        chown -h evantravers:staff "${activeLink}"
      fi

      MANAGER="${pkgs.karabiner-dk}/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"
      if [ -x "$MANAGER" ]; then
        echo "activating karabiner-dk driver..."
        "$MANAGER" forceActivate || true
      fi

      # macOS TCC grants Input Monitoring + Accessibility per binary path, so
      # every kanata store-path change (version bump, config change) needs both
      # re-granted. kanata will respawn in a ~10s loop, first complaining about
      # Input Monitoring, then Accessibility, until both are set for this path.
      echo ""
      echo "kanata TCC reminder: if it's not remapping keys, (re-)grant these two"
      echo "permissions for the current binary, removing any stale/greyed-out entry:"
      echo ""
      echo "  Binary: ${pkgs.kanata}/bin/kanata"
      echo ""
      echo "  Input Monitoring: open 'x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent'"
      echo "  Accessibility:    open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'"
      echo ""
      echo "  Then: sudo launchctl kickstart -k system/org.kanata"
      echo ""
    '';

    # forceActivate only approves the DriverKit extension; the userspace daemon
    # that bridges kanata to it needs its own supervised process, which used to
    # come from the (now removed) Karabiner-Elements.app installer.
    launchd.daemons.karabiner-vhiddaemon = {
      serviceConfig = {
        Label = "org.pqrs.Karabiner-VirtualHIDDevice-Daemon";
        ProgramArguments = [
          "${pkgs.karabiner-dk}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
        ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };

    # Run kanata as a supervised root LaunchDaemon (it needs root to grab the
    # keyboard via IOKit) instead of launching it manually with `sudo kanata`.
    launchd.daemons.kanata = {
      serviceConfig = {
        Label = "org.kanata";
        ProgramArguments = [
          "${pkgs.kanata}/bin/kanata"
          "-c"
          activeLink
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/var/log/kanata.log";
        StandardErrorPath = "/var/log/kanata.log";
      };
    };
  };
}
