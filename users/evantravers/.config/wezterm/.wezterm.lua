local wezterm = require 'wezterm'

function Scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'zenbones_dark'
  else
    return 'zenbones_light'
  end
end

return {
  -- fonts
  font = wezterm.font 'JetBrains Mono',
  font_size = 16.0;
  line_height = 1.1,
  -- theme
  color_scheme = Scheme_for_appearance(wezterm.gui.get_appearance()),
  -- window and UI
  max_fps = 240,
  window_padding = {
    left   = '2cell',
    right  = '2cell',
    top    = '1cell',
    bottom = '1cell'
  },
  window_decorations = "RESIZE",
  window_close_confirmation = 'NeverPrompt',
  adjust_window_size_when_changing_font_size = false,
  hide_tab_bar_if_only_one_tab = true,
  -- keyboard
  send_composed_key_when_left_alt_is_pressed = false,
  send_composed_key_when_right_alt_is_pressed = false,
  -- term
  term = "wezterm",
}
