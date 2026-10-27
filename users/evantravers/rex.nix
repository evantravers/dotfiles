{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rex;

  # rmx — worktree + agent launcher for rex, and rsesh, a sesh picker
  # that switches rex sessions; see rmx/main.go. Both draw full-screen
  # with every cell painted, so they work in rex's floating layers,
  # which init.lua opens them in.
  rmx = pkgs.buildGoModule {
    pname = "rmx";
    version = "0.1.0";
    src = ./rmx;
    vendorHash = "sha256-BZoTxx5/W5DsNJ8fK+buk9eG3ondyY+Sia4GRr+vh74=";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      ln -s rmx $out/bin/rsesh
      # Panes run rmx __agent through RMX_SELF, so they get this PATH too.
      # rex defaults panes to the macOS account shell (zsh); rmx makes
      # this fish the panes' shell (overridable via RMX_SHELL).
      wrapProgram $out/bin/rmx \
        --set-default RMX_SELF $out/bin/rmx \
        --prefix PATH : ${
          lib.makeBinPath (
            with pkgs;
            [
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
    enable = lib.mkEnableOption "rex integration (rmx worktree agent launcher)";
  };

  config = lib.mkIf cfg.enable {
    # The rex CLI itself is app-managed and expected on PATH.
    home.packages = [ rmx ];

    # rex reads this on `rex config reload`; it doesn't watch the file
    xdg.configFile."rex/init.lua".source = ./.config/rex/init.lua;

    # The login shell rex runs commands through resets PATH (nix-darwin),
    # dropping the rex CLI that rex put at its front
    programs.fish.interactiveShellInit = lib.mkAfter ''
      if set -q REX_BIN_DIR; and test -n "$REX_BIN_DIR"
        fish_add_path -m $REX_BIN_DIR
      end
    '';
  };
}
