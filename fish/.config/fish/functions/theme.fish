function theme -d "toggle kitty theme"
  if test -n "$termTheme"
    echo "going light!"
    set -xU termTheme "light"
    set fish_color_normal color0
    set fish_color_command color8 bold
    kitty @ --to unix:/tmp/kitty set-colors --all --configured ~/.config/kitty/themes/gruvbox-light.conf
  else
    echo "going dark!"
    set -exU termTheme
    set fish_color_normal color8
    set fish_color_command color0 bold
    kitty @ --to unix:/tmp/kitty set-colors --reset
  end
end
