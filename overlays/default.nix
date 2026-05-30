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
  # neovim-nightly = inputs.neovim-nightly-overlay.overlays.default;
  jj-starship = inputs.jj-starship.overlays.default;

  # mini.diff source for jj (jujutsu), not in nixpkgs. Hosted on tangled.org.
  # https://tangled.org/ronshavit.com/mini.diff.jj
  mini-diff-jj = final: _prev: {
    mini-diff-jj = final.unstable.vimUtils.buildVimPlugin {
      pname = "mini-diff-jj";
      version = "5cb6cc2";
      # require("mini.diff.jj") pulls in mini.diff, which only exists at runtime
      # (provided by mini-nvim), so skip the build-time require check for it.
      nvimSkipModules = [ "mini.diff.jj" ];
      src = final.fetchgit {
        url = "https://tangled.org/ronshavit.com/mini.diff.jj";
        rev = "5cb6cc239394c21b90c4b7848a96c1c023aa6057";
        hash = "sha256-plEn52ksNmOtCeCFynPtW5ReRdtQSbygx5dtnlpSSsc=";
      };
    };
  };
}
