function theme -d "toggle kitty theme"
  if test "$termTheme" = "light"
    _gruvbox_dark
  else
    _gruvbox_light
  end
end
