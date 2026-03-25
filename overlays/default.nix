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

  # devenv = inputs.devenv.overlays.default;
  neovim-nightly = inputs.neovim-nightly-overlay.overlays.default;
  jj-starship = inputs.jj-starship.overlays.default;

  # TODO: remove once nixpkgs-unstable picks up NixOS/nixpkgs#502769
  direnv-linkmode = final: prev: {
    direnv = prev.direnv.overrideAttrs (_: {
      postPatch = ''
        substituteInPlace GNUmakefile --replace-fail " -linkmode=external" ""
      '';
    });
  };
}
