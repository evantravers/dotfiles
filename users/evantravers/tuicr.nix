# tuicr — code review TUI with vim keybindings (https://github.com/agavra/tuicr)
#
# Ships two custom local themes ported from the zenbones colorscheme family
# (https://github.com/mcchrish/zenbones.nvim), mirroring users/evantravers/hunk.nix:
#   - "zenbones-dark"  (the dark  `zenbones`  variant)
#   - "zenbones-light" (the light `zenwritten` variant)
#
# tuicr local themes are flat TOML files in ~/.config/tuicr/themes/<name>.toml,
# selected by name from config `theme` / `theme_dark` / `theme_light` or the
# `--theme` flag. Both are registered; the active one is programs.tuicr.theme.
#
# Notes on the mapping (palette values come from the zenbones specs in
# hunk.nix):
#   - Surfaces: panel_bg = Normal bg, bg_highlight/cursor_line_bg/status_bar_bg
#     = CursorLine, fg_dim/border_unfocused = LineNr.
#   - Diff: diff_add/diff_del use the Added/Removed foregrounds, diff_*_bg the
#     DiffAdd/DiffDelete row tints, syntax_*_bg the brighter content tints.
#   - zenbones has no yellow; "pending"/warning roles use wood, accent roles
#     (borders, cursor, mode badge) use blossom.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.tuicr;

  # ---------------------------------------------------------------------------
  # Palettes — same sources as hunk.nix (lua/zenbones/specs/{dark,light}.lua +
  # generated colors/zenbones.vim / colors/zenwritten.vim).
  # ---------------------------------------------------------------------------

  zenbonesDark = {
    panel_bg = "#1C1917"; # Normal bg (sand)
    bg_highlight = "#25211F"; # CursorLine
    fg_primary = "#B4BDC3"; # Normal fg (stone)
    fg_secondary = "#979FA4"; # Identifier
    fg_dim = "#685F5A"; # LineNr

    diff_add = "#819B69"; # Added / leaf
    diff_add_bg = "#232D1A"; # DiffAdd
    diff_del = "#DE6E7C"; # Removed / rose
    diff_del_bg = "#3E2225"; # DiffDelete
    diff_context = "#B4BDC3";
    diff_hunk_header = "#6099C0"; # water / Changed
    expanded_context_fg = "#685F5A";

    syntax_add_bg = "#3B492D"; # leaf @ +20L
    syntax_del_bg = "#62393D"; # rose @ +20L

    file_added = "#819B69";
    file_modified = "#6099C0";
    file_deleted = "#DE6E7C";
    file_renamed = "#B77E64"; # wood (diffFile)

    reviewed = "#819B69";
    pending = "#B77E64";

    comment_note = "#6099C0";
    comment_suggestion = "#B279A7"; # blossom
    comment_issue = "#DE6E7C";
    comment_praise = "#819B69";

    border_focused = "#B279A7";
    border_unfocused = "#685F5A";
    status_bar_bg = "#25211F";
    cursor_color = "#B279A7";
    cursor_line_bg = "#25211F";
    branch_name = "#B279A7";
    help_indicator = "#797F84"; # Conceal

    message_info_fg = "#1C1917";
    message_info_bg = "#6099C0";
    message_warning_fg = "#1C1917";
    message_warning_bg = "#B77E64";
    message_error_fg = "#1C1917";
    message_error_bg = "#DE6E7C";
    update_badge_fg = "#1C1917";
    update_badge_bg = "#B77E64";

    mode_fg = "#1C1917";
    mode_bg = "#B279A7";
  };

  zenbonesLight = {
    panel_bg = "#EEEEEE"; # Normal bg (sand)
    bg_highlight = "#E5E5E5"; # CursorLine
    fg_primary = "#353535"; # Normal fg (stone)
    fg_secondary = "#505050"; # Identifier
    fg_dim = "#989898"; # LineNr

    diff_add = "#4F6C31"; # Added / leaf
    diff_add_bg = "#CBE5B8"; # DiffAdd
    diff_del = "#A8334C"; # Removed / rose
    diff_del_bg = "#EBD8DA"; # DiffDelete
    diff_context = "#353535";
    diff_hunk_header = "#286486"; # water / Changed
    expanded_context_fg = "#989898";

    syntax_add_bg = "#B1C8A0"; # leaf @ -16L
    syntax_del_bg = "#DDB8BC"; # rose @ -16L

    file_added = "#4F6C31";
    file_modified = "#286486";
    file_deleted = "#A8334C";
    file_renamed = "#944927"; # wood (diffFile)

    reviewed = "#4F6C31";
    pending = "#944927";

    comment_note = "#286486";
    comment_suggestion = "#88507D"; # blossom
    comment_issue = "#A8334C";
    comment_praise = "#4F6C31";

    border_focused = "#88507D";
    border_unfocused = "#989898";
    status_bar_bg = "#E5E5E5";
    cursor_color = "#88507D";
    cursor_line_bg = "#E5E5E5";
    branch_name = "#88507D";
    help_indicator = "#8B8B8B"; # Comment

    message_info_fg = "#EEEEEE";
    message_info_bg = "#286486";
    message_warning_fg = "#EEEEEE";
    message_warning_bg = "#944927";
    message_error_fg = "#EEEEEE";
    message_error_bg = "#A8334C";
    update_badge_fg = "#EEEEEE";
    update_badge_bg = "#944927";

    mode_fg = "#EEEEEE";
    mode_bg = "#88507D";
  };

  renderTheme =
    t:
    lib.concatStringsSep "\n" (
      [ "# Managed by home-manager — see users/evantravers/tuicr.nix." ]
      ++ lib.mapAttrsToList (key: value: "${key} = \"${value}\"") t
    );

  # Render one top-level setting as a TOML assignment (strings must be quoted).
  toToml =
    value:
    if lib.isBool value || lib.isInt value then
      lib.generators.mkValueStringDefault { } value
    else
      ''"${toString value}"'';

  settingsLines = lib.mapAttrsToList (key: value: "${key} = ${toToml value}") cfg.settings;

  configText = lib.concatStringsSep "\n" (
    [
      "# Managed by home-manager — see users/evantravers/tuicr.nix."
      "theme = \"${cfg.theme}\""
    ]
    ++ settingsLines
  );
in
{
  options.programs.tuicr = {
    enable = lib.mkEnableOption "the tuicr code review TUI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llm-agents.tuicr;
      defaultText = "pkgs.llm-agents.tuicr";
      description = "The tuicr package to install.";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "zenbones-dark";
      description = ''
        Theme selected by config `theme`. The zenbones-dark and zenbones-light
        local themes are always registered in ~/.config/tuicr/themes/; bundled
        tuicr theme names (e.g. "catppuccin-mocha") also work.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.bool
          lib.types.str
          lib.types.int
        ]
      );
      default = {
        # Updates come from nix; the binary can't (and shouldn't) self-update.
        no_update_check = true;
      };
      defaultText = "{ no_update_check = true; }";
      description = "Top-level tuicr settings (diff_view, leader, mouse, ...).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "tuicr/config.toml".text = configText;
      "tuicr/themes/zenbones-dark.toml".text = renderTheme zenbonesDark;
      "tuicr/themes/zenbones-light.toml".text = renderTheme zenbonesLight;
    };
  };
}
