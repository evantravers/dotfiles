function dark -d "Set dark theme"
  set -xU theme "dark"
  kitty @ set-colors -a "~/.local/share/nvim/site/pack/paqs/start/zenbones.nvim/extras/kitty/zenbones_dark.conf"
end
