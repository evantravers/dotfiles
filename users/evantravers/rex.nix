{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rex;

  # The rex CLI ships inside the app bundle. Inside rex, REX_BIN_DIR
  # points at the binary for the running server; elsewhere, fall back
  # to the installed copy.
  rex-cli = pkgs.writeShellScriptBin "rex" ''
    dir="''${REX_BIN_DIR:-$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS}"
    exec "$dir/rex" "$@"
  '';

  # wt — worktree + agent launcher for rex, and wt sesh, a sesh picker
  # that switches rex sessions; see wt/main.go. init.lua opens wt in
  # a floating pane.
  wt = pkgs.buildGoModule {
    pname = "wt";
    version = "0.1.0";
    src = ./wt;
    vendorHash = "sha256-BZoTxx5/W5DsNJ8fK+buk9eG3ondyY+Sia4GRr+vh74=";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      # Panes run wt __agent through WT_SELF, so they get this PATH too.
      # rex defaults panes to the macOS account shell (zsh); wt makes
      # this fish the panes' shell (overridable via WT_SHELL).
      wrapProgram $out/bin/wt \
        --set-default WT_SELF $out/bin/wt \
        --prefix PATH : ${
          lib.makeBinPath (
            with pkgs;
            [
              rex-cli
              sesh
              git
              jujutsu
              devenv
              llm-agents.pi
              config.programs.fish.package
            ]
          )
        }
    '';
  };
in
{
  options.programs.rex = {
    enable = lib.mkEnableOption "rex integration (wt worktree agent launcher)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      rex-cli
      wt
    ];

    # rex reads this on `rex config reload`; it doesn't watch the file
    xdg.configFile."rex/init.lua".source = ./.config/rex/init.lua;
  };
}
