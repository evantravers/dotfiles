local wezterm = require 'wezterm'

function Scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'zenbones_dark'
  else
    return 'zenbones_light'
  end
end

return {
  font = wezterm.font_with_fallback {'JetBrains Mono Medium'},
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
}
