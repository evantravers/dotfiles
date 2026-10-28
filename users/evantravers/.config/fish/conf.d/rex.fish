status is-interactive; or return
set -q REX_SESSION; or return

# cmd+k, name the session after a project: at the first prompt, fill the
# command line with `cd` to the best zoxide match for the session label.
# Enter to go, ctrl+c to dismiss; nothing lands in history.
#
# Runs at the first prompt rather than now so it sees the current label,
# and after config.fish has put rex back on PATH.
function __rex_prefill_cd --on-event fish_prompt
    functions -e __rex_prefill_cd

    test "$PWD" = "$HOME"; or return
    type -q rex; and type -q zoxide; and type -q jq; or return

    # don't start a server or hang the prompt if this session's server is gone
    set -l label (rex session inspect $REX_SESSION --json --autostart=false --timeout 1s 2>/dev/null | jq -r '.label // empty')
    test -n "$label"; or return

    # whole label first (my-app); fall back to hyphens as separate keywords
    # (fix-login-redirect -> fix login redirect)
    set -l dir (zoxide query -- $label 2>/dev/null; or zoxide query -- (string split -n - -- $label) 2>/dev/null)
    test -n "$dir"; or return

    commandline -r -- "cd "(string escape -- $dir[1])
end
