{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rex;

  # wt — worktree + agent launcher for rex, and wt sesh, a sesh picker
  # that switches rex sessions; see wt/main.go. init.lua opens both
  # in floating panes.
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
    # The rex CLI itself is app-managed and expected on PATH.
    home.packages = [ wt ];

    # rex reads this on `rex config reload`; it doesn't watch the file
    xdg.configFile."rex/init.lua".source = ./.config/rex/init.lua;

    programs.fish = lib.mkIf config.programs.fish.enable {
      interactiveShellInit = lib.mkAfter ''
        # The login shell rex runs commands through resets PATH (nix-darwin),
        # dropping the rex CLI that rex put at its front
        if set -q REX_BIN_DIR; and test -n "$REX_BIN_DIR"
          fish_add_path -m $REX_BIN_DIR
        end
      '';
    };

    xdg.configFile."fish/conf.d/rex.fish" = lib.mkIf config.programs.fish.enable {
      source = ./.config/fish/conf.d/rex.fish;
    };
  };
}
