function dark -d "Set dark theme"
  set -xU theme "dark"
  kitty @ set-colors -a "~/.local/share/nvim/lazy/zenbones.nvim/extras/kitty/zenbones_dark.conf"
end
