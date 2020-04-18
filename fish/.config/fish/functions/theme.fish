function theme -d "toggle kitty theme"
  if test "$termTheme" = "light"
    set -eU termTheme
    _gruvbox_dark
    kitty @ --to unix:/tmp/kitty set-colors --reset
  else
    set -xU termTheme "light"
    _gruvbox_light
    kitty @ --to unix:/tmp/kitty set-colors --all --configured ~/.config/kitty/themes/gruvbox-light.conf
  end
end
