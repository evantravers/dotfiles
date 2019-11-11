function fasd_cd -d "fasd builtin cd"
  if test (count $argv) -le 1
    command fasd "$argv"
  else
    set -l ret (command fasd -e 'printf %s' $argv)
    test -z "$ret"; and return
    test -d "$ret"; and cd "$ret"; or printf "%s\n" $ret
  end
end
