{ inputs, ... }:
{
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  llm-agents = _final: prev: {
    llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
  };

  neovim-nightly = inputs.neovim-nightly-overlay.overlays.default;

  # Workaround for https://github.com/NixOS/nixpkgs/issues/488689
  # gnulib's error() macro passes dgettext() results as format strings,
  # triggering -Werror,-Wformat-security in openat-die.c
  # Solution from https://github.com/wimpysworld/nix-config/commit/4248e93
  fix-inetutils = _final: prev: {
    inetutils = prev.inetutils.overrideAttrs (
      old:
      prev.lib.optionalAttrs prev.stdenv.isDarwin {
        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE = toString [
            (old.env.NIX_CFLAGS_COMPILE or "")
            "-Wno-format-security"
          ];
        };
      }
    );
  };
}
