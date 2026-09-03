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
      nh
      obsidian
      rainfrog
      sesh
      thunderbird
      tmux
      vimPlugins
      ;
  };

  llm-agents = _final: prev: {
    llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
  };

  # Neovim nightly (0.13.0-dev) from nix-community/neovim-nightly-overlay,
  # replacing neovim-unwrapped (which promote-unstable would otherwise take
  # from the unstable channel — note neovim-unwrapped is deliberately absent
  # from that list). Self-expires: once nixpkgs-unstable ships 0.13, an
  # evaluation warning fires and the unstable package is used instead.
  # `nix flake update neovim-nightly` to move the nightly pin.
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

  # Hunk straight from the upstream flake (github:modem-dev/hunk, rev pinned
  # in flake.lock — `nix flake update hunk` to move) instead of llm-agents.nix
  # release builds, to test freshly-merged features.
  hunk = _final: prev: {
    hunk = inputs.hunk.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  # Pin karabiner-dk driver version for kanata compatibility. The pin self-
  # expires: once kanata's required driver version matches the nixpkgs default,
  # the override is a no-op and prints an evaluation warning. A changed-but-
  # not-caught-up requirement prints a warning to update the pin instead.
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

  # Workaround for fish build failure on Apple Silicon due to an upstream
  # nixpkgs issue: the cached fish binary has broken codesigning, so force a
  # local rebuild instead of substituting it. The pin self-flags: a fish
  # version bump means new binaries were cached upstream, so the workaround
  # may no longer be needed and an evaluation warning asks you to re-check.
  # See: https://github.com/NixOS/nixpkgs/issues/507531
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

  devenv = inputs.devenv.overlays.default;

  # mini.diff source for jj (jujutsu), not in nixpkgs. Hosted on tangled.org.
  # https://tangled.org/ronshavit.com/mini.diff.jj
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

  # Fork of zenbones-theme/zenbones.nvim from upstream PR #236
  # (s-cerevisiae/zenbones.nvim @ the `cache` branch). Adds a msgpack colorscheme
  # cache: colors/palettes are compiled through lush once on first load and cached,
  # so later loads skip lush entirely (startup ~2ms). Overrides zenbones-nvim in
  # vimPlugins, which promote-unstable then forwards to top-level pkgs. The override
  # self-expires with an evaluation warning once nixpkgs' zenbones-nvim carries the
  # cache (detected by the "bones_no_cache" option in lua/zenbones/util.lua, which
  # this PR introduced; a plain version check would false-fire since nixpkgs is
  # already at the same 4.12.0 tag the PR targets).
  zenbones-cache-fork = final: prev: {
    # Preserve the rest of `unstable` (overlay results merge shallowly, so a
    # bare `unstable.vimPlugins = ...` would clobber the whole unstable set).
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
