{ inputs, ... }:
{
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      localSystem.system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  # Promote selected packages from the unstable channel to top-level pkgs so
  # feature modules can use plain `pkgs.<name>` and stay channel-agnostic. This
  # is the one place the channel decision is made, so two modules using the same
  # program can't disagree about where it comes from.
  promote-unstable = final: _prev: {
    inherit (final.unstable)
      jj-starship
      jujutsu
      llama-cpp
      meli
      # 26.05 stable neovim-unwrapped isn't cached for aarch64-darwin and its
      # build runs flaky functional tests that crash; unstable is cached.
      neovim-unwrapped
      nh
      obsidian
      rainfrog
      tmux
      vimPlugins
      ;
  };

  llm-agents = _final: prev: {
    llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
  };

  # Pin karabiner-dk driver version for kanata compatibility.
  karabiner-dk-version = final: prev: {
    karabiner-dk = prev.karabiner-dk.override { "driver-version" = "6.2.0"; };
  };

  devenv = inputs.devenv.overlays.default;

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
