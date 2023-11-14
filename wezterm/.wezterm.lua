local wezterm = require 'wezterm'

function Scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'zenbones_dark'
  else
    return 'zenbones_light'
  end
end

return {
  font = wezterm.font_with_fallback {
    {
      family = 'Monaspace Neon Var',
      weight = 600,
      harfbuzz_features = { "calt", "liga", "dlig", "ss01", "ss02", "ss03", "ss04", "ss05", "ss06", "ss07", "ss08" },
    },
  },
  color_scheme = Scheme_for_appearance(wezterm.gui.get_appearance()),
  hide_tab_bar_if_only_one_tab = true,
  window_padding = {
    left   = '2cell',
    right  = '2cell',
    top    = '1cell',
    bottom = '1cell'
  },
  window_decorations = "RESIZE",
  adjust_window_size_when_changing_font_size = false,
  line_height = 1.1,
  term = "wezterm",
  send_composed_key_when_left_alt_is_pressed = false,
  send_composed_key_when_right_alt_is_pressed = false,
  window_close_confirmation = 'NeverPrompt'

  config.default_domain = 'WSL:NixOS'
}
