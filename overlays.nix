{ inputs, ... }:
{
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      localSystem.system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  promote-unstable = final: _prev: {
    inherit (final.unstable)
      jj-starship
      jujutsu
      llama-cpp
      meli
      nh
      obsidian
      rainfrog
      sesh
      tmux
      vimPlugins
      ;
  };

  llm-agents = _final: prev: {
    llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
  };

  neovim-nightly = final: prev: {
    neovim-unwrapped =
      let
        inherit (final.unstable) lib;
        inNixpkgs = lib.versionAtLeast final.unstable.neovim-unwrapped.version "0.13";
      in
      lib.warnIf inNixpkgs
        ''
          neovim 0.13 is now in nixpkgs-unstable; the neovim-nightly overlay and flake input can be removed (re-add neovim-unwrapped to promote-unstable).
        ''
        (
          if inNixpkgs then
            final.unstable.neovim-unwrapped
          else
            inputs.neovim-nightly.packages.${prev.stdenv.hostPlatform.system}.neovim
        );
  };

  workmux = _final: prev: {
    workmux = inputs.workmux.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  karabiner-dk-version = final: prev: {
    karabiner-dk =
      let
        inherit (prev) lib;
        default = prev.karabiner-dk;
        pinned = "6.2.0";
        need = prev.kanata.darwinDriverVersion;
        useDefault = need == default.version;
      in
      lib.warnIf useDefault
        "kanata now targets karabiner-dk ${need} (the nixpkgs default); the driver-version pin can be removed."
        (
          lib.warnIf (need != pinned && !useDefault)
            "kanata's driver requirement changed to ${need}; update the karabiner-dk pin from ${pinned}."
            (if useDefault then default else default.override { "driver-version" = pinned; })
        );
  };

  fish-darwin-rebuild =
    final: prev:
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
      fish =
        let
          inherit (prev) lib;
          brokenVersion = "4.7.1";
          bumped = prev.fish.version != brokenVersion;
        in
        lib.warnIf bumped
          ''
            fish is now ${prev.fish.version} (was ${brokenVersion} when the darwin codesign workaround was added); re-check nixpkgs#507531 and remove the fish-darwin-rebuild overlay if fixed.
          ''
          (
            prev.fish.overrideAttrs (_old: {
              NIX_FORCE_LOCAL_REBUILD = "darwin-codesign-fix";
            })
          );
    };

  pi-nvim = final: _prev: {
    pi-nvim = final.unstable.vimUtils.buildVimPlugin {
      pname = "nvim-pi";
      version = "0.7.0";
      src = final.fetchFromGitHub {
        owner = "aliou";
        repo = "nvim-pi";
        rev = "102e087179cfe8e65bd6b9ab2edbb86d64cecf2f";
        hash = "sha256-DlzwwnkA0h59R1ZXk4OTt/1P9ZgD/HTJfTh0pvy5bgM=";
      };
    };
  };

  devenv = inputs.devenv.overlays.default;

  vim-plugin-mini-nvim-main = final: prev: {
    unstable = prev.unstable // {
      vimPlugins = prev.unstable.vimPlugins // {
        mini-nvim =
          let
            inherit (final.unstable) lib;
            nixpkgsMini = prev.unstable.vimPlugins.mini-nvim;
            clueLua = nixpkgsMini + "/lua/mini/clue.lua";
            inNixpkgs =
              builtins.pathExists clueLua
              && builtins.match ".*Previously it was also a problem.*" (builtins.readFile clueLua) != null;
          in
          lib.warnIf inNixpkgs
            ''
              mini.nvim's multicursor fixes (nvim-mini/mini.nvim#2546) are now in nixpkgs vimPlugins; the vim-plugin-mini-nvim-main overlay and flake input can be removed.
            ''
            (
              if inNixpkgs then
                nixpkgsMini
              else
                final.unstable.vimUtils.buildVimPlugin {
                  pname = "mini-nvim";
                  version = inputs.mini-nvim.shortRev;
                  src = inputs.mini-nvim;
                }
            );
      };
    };
  };

  mini-diff-jj = final: _prev: {
    mini-diff-jj =
      let
        inNixpkgs = final.unstable.vimPlugins ? mini-diff-jj;
      in
      final.unstable.lib.warnIf inNixpkgs
        ''
          mini-diff-jj is now in nixpkgs vimPlugins; this tangled.org override can be removed.
        ''
        (
          if inNixpkgs then
            final.unstable.vimPlugins.mini-diff-jj
          else
            final.unstable.vimUtils.buildVimPlugin {
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
            }
        );
  };

  zenbones-cache-fork = final: prev: {
    unstable = prev.unstable // {
      vimPlugins = prev.unstable.vimPlugins // {
        zenbones-nvim =
          let
            inherit (final.unstable) lib;
            nixpkgsZenbones = prev.unstable.vimPlugins.zenbones-nvim;
            utilLua = nixpkgsZenbones + "/lua/zenbones/util.lua";
            inNixpkgs =
              builtins.pathExists utilLua
              && builtins.match ".*bones_no_cache.*" (builtins.readFile utilLua) != null;
          in
          lib.warnIf inNixpkgs
            ''
              zenbones' colorscheme cache (upstream PR #236) is now in nixpkgs vimPlugins; the fork override can be removed.
            ''
            (
              final.unstable.vimUtils.buildVimPlugin {
                pname = "zenbones.nvim";
                version = "4.12.0-236";
                # Same check setup as nixpkgs' zenbones-nvim override
                # (pkgs/applications/editors/vim/plugins/overrides.nix): lush is
                # needed at require-check time, and the randombones/shipwright
                # modules can't be required without globals/setup.
                checkInputs = [ final.unstable.vimPlugins.lush-nvim ];
                nvimSkipModules = [
                  # Requires global variable set
                  "randombones"
                  "randombones.palette"
                  "randombones_dark.palette"
                  "randombones_light"
                  "randombones_light.palette"
                  # Optional shipwright
                  "zenbones.shipwright.runners.alacritty"
                  "zenbones.shipwright.runners.foot"
                  "zenbones.shipwright.runners.ghostty"
                  "zenbones.shipwright.runners.iterm"
                  "zenbones.shipwright.runners.kitty"
                  "zenbones.shipwright.runners.lightline"
                  "zenbones.shipwright.runners.lualine"
                  "zenbones.shipwright.runners.tmux"
                  "zenbones.shipwright.runners.vim"
                  "zenbones.shipwright.runners.wezterm"
                  "zenbones.shipwright.runners.windows_terminal"
                  "randombones_dark"
                ];
                src = final.fetchFromGitHub {
                  owner = "s-cerevisiae";
                  repo = "zenbones.nvim";
                  rev = "bc982d86126f41c6ef7aadf189c4e70f57ee19bf";
                  hash = "sha256-MiiYxpdz+0LytGLbFhrrN7l0DppBcgIYqS6UIB1NXYc=";
                };
              }
            );
      };
    };
  };
}
