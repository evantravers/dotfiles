function light -d "Set light theme"
  set -xU theme "light"
  kitty @ set-colors -a "~/.local/share/nvim/lazy/zenbones.nvim/extras/kitty/zenbones_light.conf"
end
