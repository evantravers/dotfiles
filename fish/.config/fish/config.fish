starship init fish | source

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Launch tmux immediately after loading the shell
if command --query tmux
  and status is-interactive
  and not string match --quiet --regex 'screen|tmux' $TERM
  and test -z $TMUX
  exec tmux new-session -A -s main
end
