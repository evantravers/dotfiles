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

  devenv = inputs.devenv.overlays.default;
  neovim-nightly = inputs.neovim-nightly-overlay.overlays.default;
  jujutsu = inputs.jujutsu.overlays.default;
}
