{ pkgs, lib, config, ... }:
let
  home = config.users.users.evantravers.home;
  activeLink = "${home}/.local/state/kanata/active.kbd";
  vhiddaemonBin = "${pkgs.karabiner-dk}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";

  kanata-switch = pkgs.writeShellScriptBin "kanata-switch" ''
    #!/usr/bin/env bash
    set -euo pipefail

    CONFIG_DIR="$HOME/.config/kanata"
    ACTIVE_LINK="$HOME/.local/state/kanata/active.kbd"

    choice=$(basename -a "$CONFIG_DIR"/*.kbd | gum choose --header "Select kanata layout")

    ln -sfn "$CONFIG_DIR/$choice" "$ACTIVE_LINK"
    echo "Switched active kanata layout to $choice"

    # kickstart only restarts an already-loaded daemon; if it was previously
    # unloaded (e.g. bootout during troubleshooting), fall back to loading
    # it fresh instead of silently no-op'ing.
    sudo launchctl kickstart -k system/org.kanata \
      || sudo launchctl bootstrap system /Library/LaunchDaemons/org.kanata.plist
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

    # This machine has FileVault on, so ~evantravers's home directory lives on
    # the encrypted Data volume and isn't mounted yet when launchd first
    # loads LaunchDaemons at boot (well before login/unlock). A LaunchDaemon
    # exec path under the home directory can get caught by launchd's
    # "Missing executable detected" check during that window, which disables
    # the job permanently (RunAtLoad/KeepAlive won't revive it). So
    # ProgramArguments below reference the karabiner-dk store path directly
    # instead of a home-directory symlink; only activeLink (a config-file
    # *argument*, not the exec path itself) is safe to keep under home.
    system.activationScripts.preActivation.text = ''
      # kanata-switch repoints this symlink to swap layouts at runtime without
      # a rebuild; seed it here so RunAtLoad has something to point at on a
      # fresh install.
      mkdir -p "${home}/.local/state/kanata"
      chown evantravers:staff "${home}/.local/state/kanata"
      if [ ! -e "${activeLink}" ]; then
        ln -sfn "${home}/.config/kanata/macbook.kbd" "${activeLink}"
        chown -h evantravers:staff "${activeLink}"
      fi
    '';

    # Activate the Karabiner DriverKit virtual HID driver during system activation.
    system.activationScripts.postActivation.text = ''
      MANAGER="${pkgs.karabiner-dk}/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"
      if [ -x "$MANAGER" ]; then
        echo "activating karabiner-dk driver..."
        "$MANAGER" forceActivate || true
      fi

      # macOS TCC grants Input Monitoring + Accessibility per binary path.
      # kanata now launches via the stable /run/current-system/sw/bin/kanata
      # path, so a grant here should survive version bumps -- but if the
      # grant's code identity ever changes anyway, kanata will respawn in a
      # ~10s loop, first complaining about Input Monitoring, then
      # Accessibility, until both are (re-)set for this path.
      echo ""
      echo "kanata TCC reminder: if it's not remapping keys, (re-)grant these two"
      echo "permissions for the current binary, removing any stale/greyed-out entry:"
      echo ""
      echo "  Binary: /run/current-system/sw/bin/kanata"
      echo ""
      echo "The vhiddaemon binary's path changes on every karabiner-dk version"
      echo "bump (it's referenced directly from the nix store, not via a stable"
      echo "symlink -- see the comment above). If key remapping stops working"
      echo "after a switch, its Input Monitoring grant may need to be redone too:"
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
        # launchd checks that ProgramArguments[0] exists *at job-load time*,
        # which can be before /nix is mounted this early in boot -- and once
        # it logs "Missing executable detected" for a job, that job is
        # disabled for good (RunAtLoad/KeepAlive never revives it). Route
        # through /bin/bash (always present) so launchd's own check always
        # passes; the real path is only resolved later, at actual exec time,
        # by which point /nix has mounted.
        ProgramArguments = [
          "/bin/bash"
          "-c"
          ''exec "${vhiddaemonBin}"''
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 30;
        StandardOutPath = "/var/log/vhiddaemon.log";
        StandardErrorPath = "/var/log/vhiddaemon.log";
      };
    };

    # Run kanata as a supervised root LaunchDaemon (it needs root to grab the
    # keyboard via IOKit) instead of launching it manually with `sudo kanata`.
    launchd.daemons.kanata = {
      serviceConfig = {
        Label = "org.kanata";
        # kanata connects to the vhiddaemon's socket on start and doesn't
        # retry the connection itself, so a RunAtLoad race where kanata
        # starts before the daemon is actually accepting connections leaves
        # it stuck failing forever. Poll for the daemon process before
        # exec'ing, mirroring the same wait Karabiner-Elements.app used to do.
        ProgramArguments = [
          "/bin/bash"
          "-c"
          ''
            while ! pgrep -f "Karabiner-VirtualHIDDevice-Daemon" > /dev/null; do
              sleep 1
            done
            exec /run/current-system/sw/bin/kanata -c "${activeLink}"
          ''
        ];
        RunAtLoad = true;
        KeepAlive = {
          OtherJobEnabled = {
            "org.pqrs.Karabiner-VirtualHIDDevice-Daemon" = true;
          };
        };
        ThrottleInterval = 30;
        StandardOutPath = "/var/log/kanata.log";
        StandardErrorPath = "/var/log/kanata.log";
      };
    };
  };
}
