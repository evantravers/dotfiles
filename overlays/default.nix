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

  # Override mini-nvim to v0.18.0 from GitHub.
  # Named with a prefix so it runs after promote-unstable (which promotes vimPlugins) in alphabetical order.
  vimPlugins-mini-nvim = final: prev: {
    vimPlugins = prev.vimPlugins // {
      mini-nvim = prev.vimPlugins.mini-nvim.overrideAttrs (oldAttrs: {
        version = "0.18.0";
        src = final.fetchFromGitHub {
          owner = "echasnovski";
          repo = "mini.nvim";
          rev = "v0.18.0";
          hash = "sha256-kCcyl4KUEY51UeGYmvuLD1hswWbwKhHGUt/0XLbPuUw=";
        };
      });
    };
  };
}
