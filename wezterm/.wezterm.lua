local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'zenbones_dark'
  else
    return 'zenbones_light'
  end
end

return {
  font = wezterm.font 'JetBrains Mono',
  color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),
  hide_tab_bar_if_only_one_tab = true,
  window_padding = {
    left   = '2cell',
    right  = '2cell',
    top    = '1cell',
    bottom = '1cell'
  },
  window_decorations = "NONE"
}
