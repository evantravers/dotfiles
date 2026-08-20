# hunk — review-first terminal diff viewer (https://github.com/modem-dev/hunk)
#
# Ships two custom themes ported from the zenbones colorscheme family
# (https://github.com/mcchrish/zenbones.nvim):
#   - "zenbones-dark"  (the dark  `zenbones`  variant)
#   - "zenbones-light" (the light `zenwritten` variant)
#
# hunk has no plugin system; custom themes live inline in ~/.config/hunk/config.toml
# under `[themes.<id>]` tables. Both are registered so you can flip between them
# in-app with `t` (Choose theme). The active one is set by programs.hunk.theme.
#
# Notes on the mapping:
#   - Surfaces/diff tints come straight from the colorscheme (Normal, DiffAdd,
#     DiffChange, DiffDelete, DiffText, CursorLine, Search, ...). The
#     *ContentBg tints are the same hue/saturation treatment at +12L over the
#     row tints, mirroring how hunk's own built-in themes derive them.
#   - Syntax colors follow zenbones' monochrome philosophy: code is foreground
#     grayscale, only `type` gets a warm hue (Type = bg.li(58)) and accents
#     stay reserved for diagnostics/diff. scopes are exact TextMate scopes so
#     they survive the deprecated [custom_theme.syntax] migration.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.hunk;

  # ---------------------------------------------------------------------------
  # Palettes — ported from lua/zenbones/specs/{dark,light}.lua + generated
  # colors/zenbones.vim (dark) / colors/zenwritten.vim (light).
  # ---------------------------------------------------------------------------

  zenbonesDark = {
    label = "Zenbones Dark";
    surfaces = {
      background = "#1C1917"; # Normal bg (sand)
      panel = "#25211F"; # CursorLine
      panelAlt = "#302B29"; # NormalFloat / Pmenu
      border = "#685F5A"; # LineNr / WinSeparator
      text = "#B4BDC3"; # Normal fg (stone)
      muted = "#797F84"; # Conceal
      accent = "#B279A7"; # blossom
      accentMuted = "#65435E"; # Search bg
    };
    diff = {
      addedBg = "#232D1A"; # DiffAdd
      removedBg = "#3E2225"; # DiffDelete
      movedAddedBg = "#1D2C36"; # DiffChange
      movedRemovedBg = "#1D2C36";
      contextBg = "#1C1917";
      addedContentBg = "#3B492D"; # leaf @ +20L
      removedContentBg = "#62393D"; # rose @ +20L
      contextContentBg = "#25211F";
      addedSignColor = "#819B69"; # Added / leaf
      removedSignColor = "#DE6E7C"; # Removed / rose
      lineNumberBg = "#1C1917";
      lineNumberFg = "#685F5A"; # LineNr
      selectedHunk = "#25211F"; # CursorLine
    };
    chrome = {
      badgeAdded = "#819B69";
      badgeRemoved = "#DE6E7C";
      badgeNeutral = "#797F84";
      fileNew = "#819B69";
      fileDeleted = "#DE6E7C";
      fileRenamed = "#B77E64"; # wood (diffFile)
      fileModified = "#6099C0"; # water / Changed
      fileUntracked = "#797F84";
      noteBorder = "#B279A7";
      noteBackground = "#25211F";
      noteTitleBackground = "#302B29";
      noteTitleText = "#B4BDC3";
    };
    syntax = {
      source = "#B4BDC3"; # default fg
      comment = "#6E6763"; # Comment
      string = "#868C91"; # String (fg4)
      "constant.numeric" = "#868C91"; # Number
      "constant.other" = "#868C91"; # Constant
      "constant.language" = "#B4BDC3"; # Boolean
      variable = "#979FA4"; # Identifier
      "variable.parameter" = "#979FA4";
      "variable.other.property" = "#979FA4"; # @property
      "entity.other.attribute-name" = "#979FA4";
      "entity.name.function" = "#B4BDC3"; # Function
      "support.function" = "#B4BDC3";
      "entity.name.type" = "#A1938C"; # Type (bg.li(58))
      "entity.name.class" = "#A1938C";
      "support.type" = "#A1938C";
      "support.class" = "#A1938C";
      "storage.type" = "#A1938C";
      "entity.name.tag" = "#8D9499"; # Special
      keyword = "#B4BDC3"; # Statement
      "keyword.operator" = "#B4BDC3";
      "storage.modifier" = "#B4BDC3";
      punctuation = "#867A74"; # Delimiter
      "punctuation.definition.comment" = "#6E6763";
      "markup.heading" = "#B4BDC3"; # Title
      "markup.bold" = "#B4BDC3";
      "markup.italic" = "#B4BDC3";
      "markup.raw" = "#868C91"; # Constant
      "markup.quote" = "#868C91";
      "markup.link" = "#868C91";
    };
  };

  zenbonesLight = {
    label = "Zenbones Light";
    surfaces = {
      background = "#EEEEEE"; # Normal bg (sand)
      panel = "#E5E5E5"; # CursorLine
      panelAlt = "#D7D7D7"; # NormalFloat / Pmenu
      border = "#989898"; # LineNr
      text = "#353535"; # Normal fg (stone)
      muted = "#8B8B8B"; # Comment
      accent = "#88507D"; # blossom
      accentMuted = "#DEB9D6"; # Search bg
    };
    diff = {
      addedBg = "#CBE5B8"; # DiffAdd
      removedBg = "#EBD8DA"; # DiffDelete
      movedAddedBg = "#D4DEE7"; # DiffChange
      movedRemovedBg = "#D4DEE7";
      contextBg = "#EEEEEE";
      addedContentBg = "#B1C8A0"; # leaf @ -16L
      removedContentBg = "#DDB8BC"; # rose @ -16L
      contextContentBg = "#E5E5E5";
      addedSignColor = "#4F6C31"; # Added / leaf
      removedSignColor = "#A8334C"; # Removed / rose
      lineNumberBg = "#EEEEEE";
      lineNumberFg = "#989898"; # LineNr
      selectedHunk = "#E5E5E5"; # CursorLine
    };
    chrome = {
      badgeAdded = "#4F6C31";
      badgeRemoved = "#A8334C";
      badgeNeutral = "#8B8B8B";
      fileNew = "#4F6C31";
      fileDeleted = "#A8334C";
      fileRenamed = "#944927"; # wood (diffFile)
      fileModified = "#286486"; # water / Changed
      fileUntracked = "#8B8B8B";
      noteBorder = "#88507D";
      noteBackground = "#E5E5E5";
      noteTitleBackground = "#D7D7D7";
      noteTitleText = "#353535";
    };
    syntax = {
      source = "#353535";
      comment = "#8B8B8B";
      string = "#636363"; # String (fg4)
      "constant.numeric" = "#636363";
      "constant.other" = "#636363";
      "constant.language" = "#353535";
      variable = "#505050"; # Identifier
      "variable.parameter" = "#505050";
      "variable.other.property" = "#505050";
      "entity.other.attribute-name" = "#505050";
      "entity.name.function" = "#353535";
      "support.function" = "#353535";
      "entity.name.type" = "#735057"; # Type
      "entity.name.class" = "#735057";
      "support.type" = "#735057";
      "support.class" = "#735057";
      "storage.type" = "#735057";
      "entity.name.tag" = "#5C5C5C"; # Special
      keyword = "#353535";
      "keyword.operator" = "#353535";
      "storage.modifier" = "#353535";
      punctuation = "#848484"; # Delimiter
      "punctuation.definition.comment" = "#8B8B8B";
      "markup.heading" = "#353535";
      "markup.bold" = "#353535";
      "markup.italic" = "#353535";
      "markup.raw" = "#636363";
      "markup.quote" = "#636363";
      "markup.link" = "#636363";
    };
  };

  # Map a role-keyed palette to hunk's flat config keys. The palette's
  # surfaces/diff/chrome keys already use hunk's flat names, so just merge
  # them; pkgs.formats.toml quotes the dotted syntax_scopes keys for us.
  toTheme =
    base: t:
    {
      inherit base;
      inherit (t) label;
      syntax_scopes = t.syntax;
    }
    // t.surfaces
    // t.diff
    // t.chrome;

  configValue = cfg.settings // {
    theme = cfg.theme;
    themes = {
      zenbones-dark = toTheme "github-dark-default" zenbonesDark;
      zenbones-light = toTheme "github-light-default" zenbonesLight;
    };
  };
in
{
  options.programs.hunk = {
    enable = lib.mkEnableOption "the hunk terminal diff viewer";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llm-agents.hunk;
      defaultText = "pkgs.llm-agents.hunk";
      description = "The hunk package to install.";
    };

    theme = lib.mkOption {
      type = lib.types.enum [
        "zenbones-dark"
        "zenbones-light"
      ];
      default = "zenbones-dark";
      description = ''
        Which hunk theme to use by default. Both zenbones themes are always
        registered — switch between them in-app with `t` (Choose theme).
      '';
    };

    linkSkills = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Symlink hunk's bundled agent skills (hunk-review) from the nix store
        into ~/.claude/skills and ~/.config/pi/agent/skills. The links point
        at the installed hunk's store path, so they stay in sync across
        upgrades.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {
        mode = "auto";
        # The config file is read-only (nix store symlink); don't prompt to
        # persist view preferences to it. Declare settings here instead.
        prompt_save_view_preferences = false;
      };
      defaultText = ''{ mode = "auto"; prompt_save_view_preferences = false; }'';
      description = ''
        Top-level hunk settings (mode, vcs, line_numbers, keybindings, …).
        Nested attrsets become TOML tables, so keybindings can be declared as

        ```nix
        settings.keybindings = {
          "hunk-less-search.find" = "/";
          "hunk.review.focusFilter" = "F";
        };
        ```
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."hunk/config.toml".source =
      (pkgs.formats.toml { }).generate "hunk-config"
        configValue;

    # hunk bundles its agent skills inside the package at <pkg>/skills/<name>/
    # (as printed by `hunk skill path`). The store path is known at eval time,
    # so plain home.file symlinks suffice — they track upgrades automatically
    # on every switch, no activation script needed.
    home.file = lib.mkIf cfg.linkSkills (
      lib.genAttrs
        [
          ".claude/skills/hunk-review"
          ".config/pi/agent/skills/hunk-review"
        ]
        (_: {
          source = "${cfg.package}/skills/hunk-review";
        })
    );
  };
}
