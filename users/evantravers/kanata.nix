{ pkgs, lib, config, ... }:
let
  cfg = config.kanata;
  home = config.users.users.evantravers.home;
  activeLink = "${home}/.local/state/kanata/active.kbd";

  # nixpkgs' kanata-with-cmd has the `cmd` action, which disable-onboard.kbd
  # needs so its ESC binding can shell out to kanata-switch.
  kanata = pkgs.kanata-with-cmd;

  # The Karabiner DriverKit build kanata's client was compiled against;
  # nixpkgs keeps it in step with kanata's vendored crate.
  driver = kanata.passthru.darwinDriver;
  vhiddaemonBin = "${driver}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";

  # macOS ties Input Monitoring and Accessibility grants for a bare binary
  # to its code hash, which changes on every rebuild. Running kanata from a
  # signed app bundle at a fixed path ties the grants to the bundle ID and
  # signing certificate instead, so they survive rebuilds.
  bundleId = "org.nixos.kanata";
  appPath = "/Applications/Kanata.app";
  appExe = "${appPath}/Contents/MacOS/kanata";
  stampFile = "/var/db/org.nixos.kanata.source";

  kanataApp = pkgs.runCommand "Kanata.app" { } ''
    mkdir -p $out/Contents/MacOS
    cp ${kanata}/bin/kanata $out/Contents/MacOS/kanata
    cat > $out/Contents/Info.plist <<'PLIST'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key><string>${bundleId}</string>
      <key>CFBundleName</key><string>Kanata</string>
      <key>CFBundleExecutable</key><string>kanata</string>
      <key>CFBundlePackageType</key><string>APPL</string>
      <key>CFBundleShortVersionString</key><string>${kanata.version}</string>
      <key>LSUIElement</key><true/>
    </dict>
    </plist>
    PLIST
  '';

  # Installs and signs Kanata.app during activation. Arguments: the
  # Kanata.app store path, the user whose login keychain holds the signing
  # certificate, and optionally the certificate's name.
  installKanataApp = pkgs.writeShellApplication {
    name = "install-kanata-app";
    runtimeInputs = [ pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.gawk ];
    # codesign, security, tccutil, launchctl and open are Apple's own tools,
    # so they are called by their /usr/bin and /bin paths.
    text = ''
      app_src=$1
      kanata_user=$2
      identity_name=''${3:-}
      stamp_file=${stampFile}
      app_path=${appPath}
      bundle_id=${bundleId}

      kanata_uid="$(id -u "$kanata_user")"
      # -H so security/codesign find the user's login keychain, not root's.
      as_user() { /bin/launchctl asuser "$kanata_uid" sudo -H -u "$kanata_user" "$@"; }

      identity=""
      if [ -n "$identity_name" ]; then
        identity="$(as_user /usr/bin/security find-identity -v -p codesigning \
          | grep -F "\"$identity_name\"" \
          | awk '{ print $2; exit }')" || true
      fi
      if [ -n "$identity" ]; then mode=signed; else mode=adhoc; fi

      prev_source="$(sed -n 1p "$stamp_file" 2>/dev/null || true)"
      prev_mode="$(sed -n 2p "$stamp_file" 2>/dev/null || true)"
      # Reinstall only when the build or the signing method changed.
      if [ "$prev_source" = "$app_src" ] && [ "$prev_mode" = "$mode" ]; then
        exit 0
      fi

      echo "[kanata] installing $app_path from $app_src ($mode)"
      tmp="$(as_user /usr/bin/mktemp -d)"
      cp -R "$app_src" "$tmp/Kanata.app"
      chown -R "$kanata_user" "$tmp"
      chmod -R u+w "$tmp"

      if [ "$mode" = signed ] \
         && as_user /usr/bin/codesign --force --timestamp=none \
              --sign "$identity" --identifier "$bundle_id" "$tmp/Kanata.app"; then
        :
      else
        if [ "$mode" = signed ]; then
          echo "[kanata] WARNING: signing with \"$identity_name\" failed (keychain locked?), falling back to ad-hoc"
          mode=adhoc
        fi
        /usr/bin/codesign --force --sign - --identifier "$bundle_id" "$tmp/Kanata.app"
      fi

      rm -rf "$app_path"
      cp -R "$tmp/Kanata.app" "$app_path"
      chown -R root:wheel "$app_path"
      rm -rf "$tmp"
      printf '%s\n%s\n' "$app_src" "$mode" > "$stamp_file"

      # The kanata job points at the fixed app path, so launchd won't
      # restart kanata on its own when only the binary changed.
      if [ "$mode" = signed ] && [ "$prev_mode" = signed ]; then
        /bin/launchctl kickstart -k system/org.kanata 2>/dev/null || true
      else
        /usr/bin/tccutil reset ListenEvent "$bundle_id" || true
        /usr/bin/tccutil reset Accessibility "$bundle_id" || true
        echo "[kanata] *** Grant Input Monitoring and Accessibility to $app_path, then run ***"
        echo "[kanata] ***   sudo launchctl kickstart -k system/org.kanata                 ***"
        as_user /usr/bin/open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent" || true
        as_user /usr/bin/open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true
        as_user /usr/bin/open -R "$app_path" || true
      fi
    '';
  };

  kanata-switch = pkgs.writeShellScriptBin "kanata-switch" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Absolute paths baked in at build time: this script is also invoked by
    # the root LaunchDaemon (via disabled.kbd's ESC binding), where HOME is
    # not set at all, so $HOME can't be relied on here.
    CONFIG_DIR="${home}/.config/kanata"
    ACTIVE_LINK="${home}/.local/state/kanata/active.kbd"

    # optional non-interactive use: `kanata-switch macbook.kbd`
    # (also used by the ESC binding in disabled.kbd to restore the layout)
    if [ $# -ge 1 ]; then
      choice="$1"
      if [ ! -e "$CONFIG_DIR/$choice" ]; then
        echo "error: no such layout: $CONFIG_DIR/$choice" >&2
        exit 1
      fi
    else
      choice=$(basename -a "$CONFIG_DIR"/*.kbd | gum choose --header "Select kanata layout")
    fi

    ln -sfn "$CONFIG_DIR/$choice" "$ACTIVE_LINK"
    echo "Switched active kanata layout to $choice"

    # Ask the running kanata to live-reload the new config over its TCP
    # server (started with -p 127.0.0.1:5829). This is near-instant and
    # avoids launchctl kickstart -k, whose respawn gets held back by the
    # daemon's ThrottleInterval, leaving the keyboard unremapped for tens
    # of seconds.
    resp=$(printf '{"ReloadFile":{"path":"%s","wait":true,"timeout_ms":5000}}\n' "$CONFIG_DIR/$choice" \
      | nc -w 8 127.0.0.1 5829 2>/dev/null || true)
    if printf '%s' "$resp" | grep -q '"ok":true'; then
      exit 0
    fi

    # Fallback: daemon not running or reload failed. kickstart only restarts
    # an already-loaded daemon; if it was previously unloaded (e.g. bootout
    # during troubleshooting), fall back to loading it fresh instead of
    # silently no-op'ing.
    sudo launchctl kickstart -k system/org.kanata \
      || sudo launchctl bootstrap system /Library/LaunchDaemons/org.kanata.plist
  '';
in
{
  options.kanata = {
    enable = lib.mkEnableOption "kanata keyboard remapping and the karabiner-dk VirtualHIDDevice driver it depends on";
    signingIdentity = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "Apple Development: Jane Doe (ABCDE12345)";
      description = ''
        Name of a code-signing certificate in the primary user's login
        keychain, as shown by `security find-identity -v -p codesigning`.
        Kanata.app is signed with it so its Input Monitoring and
        Accessibility grants survive rebuilds. Without one, the app is
        signed ad-hoc and must be granted again after every rebuild.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      kanata
      pkgs.gum
      kanata-switch
    ];

    # This machine has FileVault on, so ~evantravers's home directory lives on
    # the encrypted Data volume and isn't mounted yet when launchd first
    # loads LaunchDaemons at boot (well before login/unlock). A LaunchDaemon
    # exec path under the home directory can get caught by launchd's
    # "Missing executable detected" check during that window, which disables
    # the job permanently (RunAtLoad/KeepAlive won't revive it). So
    # ProgramArguments below never exec from the home directory; only
    # activeLink (a config-file *argument*, not the exec path itself) is
    # kept under home.
    system.activationScripts.preActivation.text = ''
      # kanata-switch repoints this symlink to swap layouts at runtime without
      # a rebuild; seed it here so RunAtLoad has something to point at on a
      # fresh install.
      mkdir -p "${home}/.local/state/kanata"
      chown evantravers:staff "${home}/.local/state/kanata"
      if [ ! -e "${activeLink}" ]; then
        ln -sfn "${home}/.config/kanata/hrm-macbook.kbd" "${activeLink}"
        chown -h evantravers:staff "${activeLink}"
      fi

      # Install Kanata.app before launchd reloads the kanata job, which
      # execs it.
      ${installKanataApp}/bin/install-kanata-app ${kanataApp} ${config.system.primaryUser} ${
        lib.escapeShellArg (if cfg.signingIdentity == null then "" else cfg.signingIdentity)
      }
    '';

    # Activate the Karabiner DriverKit virtual HID driver during system activation.
    # macOS refuses to activate a system extension unless the app that holds
    # it lives under /Applications (a symlink into /nix/store is not enough,
    # since macOS checks the resolved path). So copy the Manager app there
    # first, then run it from the copy.
    system.activationScripts.postActivation.text = ''
      SRC_APP="${driver}/Applications/.Karabiner-VirtualHIDDevice-Manager.app"
      DEST_DIR="/Applications/.Nix-Karabiner"
      DEST_APP="$DEST_DIR/.Karabiner-VirtualHIDDevice-Manager.app"
      STAMP="$DEST_DIR/.source"
      if [ -d "$SRC_APP" ]; then
        if [ ! -d "$DEST_APP" ] || [ "$(cat "$STAMP" 2>/dev/null)" != "$SRC_APP" ]; then
          echo "copying karabiner-dk manager to $DEST_DIR..."
          mkdir -p "$DEST_DIR"
          rm -rf "$DEST_APP"
          /usr/bin/ditto "$SRC_APP" "$DEST_APP"
          echo "$SRC_APP" > "$STAMP"
        fi
        echo "activating karabiner-dk driver..."
        "$DEST_APP/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager" forceActivate || true
      fi
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
        # Latency-sensitive: every remapped key goes through this daemon.
        ProcessType = "Interactive";
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
        #
        # Only Apple's shells may sit between launchd and kanata: with a
        # shell from the Nix store in the exec chain, macOS refuses Input
        # Monitoring even though Kanata.app holds the grant.
        ProgramArguments = [
          "/bin/bash"
          "-c"
          ''
            /bin/wait4path "${appExe}"
            while ! /usr/bin/pgrep -f "Karabiner-VirtualHIDDevice-Daemon" > /dev/null; do
              sleep 1
            done
            # -p starts kanata's TCP server (localhost only) so kanata-switch
            # can live-reload layouts without a launchd restart.
            exec "${appExe}" -c "${activeLink}" -p 127.0.0.1:5829
          ''
        ];
        RunAtLoad = true;
        KeepAlive = {
          OtherJobEnabled = {
            "org.pqrs.Karabiner-VirtualHIDDevice-Daemon" = true;
          };
        };
        ProcessType = "Interactive";
        ThrottleInterval = 30;
        StandardOutPath = "/var/log/kanata.log";
        StandardErrorPath = "/var/log/kanata.log";
      };
    };
  };
}
