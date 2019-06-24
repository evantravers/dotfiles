#!/usr/bin/env/ bash

if [ -z "${TERMTHEME}" ]; then
  export TERMTHEME="light"
  kitty @ --to unix:/tmp/kitty set-colors --all --configured ~/.config/kitty/themes/gruvbox-light.conf
else
  export TERMTHEME=""
  kitty @ --to unix:/tmp/kitty set-colors --reset
fi


