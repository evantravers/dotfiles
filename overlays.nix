{ inputs, ... }:
{
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      localSystem.system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      overlays = [
        # obsidian 1.13.4 darwin unpack fix (upstream NixOS/nixpkgs c594c220,
        # not yet on the nixpkgs-unstable branch). The 1.13.4 universal DMG
        # unpacks via 7z into a volume-named directory
        # ("Obsidian 1.13.4-universal/Obsidian.app"), so the hardcoded
        # sourceRoot = "Obsidian.app" breaks the darwin build. Drop sourceRoot
        # and copy the app out of the auto-detected dir. The override self-
        # expires with an evaluation warning once the upstream fix lands on
        # nixpkgs-unstable (detected by the hardcoded sourceRoot disappearing).
        (fixfinal: fixprev: {
          obsidian =
            if fixfinal.stdenv.hostPlatform.isDarwin then
              let
                noOverride = (fixprev.obsidian.sourceRoot or null) != "${fixprev.obsidian.appname}.app";
              in
              fixprev.lib.warnIf noOverride
                ''
                  obsidian's darwin unpack fix is now in nixpkgs; the sourceRoot override can be removed.
                ''
                (
                  if noOverride then
                    fixprev.obsidian
                  else
                    fixprev.obsidian.overrideAttrs (old: {
                      sourceRoot = null;
                      installPhase = ''
                        runHook preInstall
                        mkdir -p $out/{Applications,bin}
                        cp -R ${old.appname}.app $out/Applications
                        makeWrapper $out/Applications/${old.appname}.app/Contents/MacOS/${old.appname} $out/bin/obsidian
                        makeWrapper $out/Applications/${old.appname}.app/Contents/MacOS/obsidian-cli $out/bin/obsidian-cli
                        runHook postInstall
                      '';
                    })
                )
            else
              fixprev.obsidian;
        })
      ];
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
      thunderbird
      tmux
      vimPlugins
      ;
  };

  llm-agents = _final: prev: {
    llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
  };

  workmux = _final: prev: {
    workmux = inputs.workmux.packages.${prev.stdenv.hostPlatform.system}.default;
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
}
