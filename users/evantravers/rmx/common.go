package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

// stateDir holds the log and per-worktree state
func stateDir() string {
	base := os.Getenv("XDG_STATE_HOME")
	if base == "" {
		base = filepath.Join(os.Getenv("HOME"), ".local", "state")
	}
	dir := filepath.Join(base, "rmx")
	_ = os.MkdirAll(dir, 0o755)
	return dir
}

// command builds name args… to run in dir ("" for the current one)
func command(dir, name string, args ...string) *exec.Cmd {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	return cmd
}

// output runs cmd and returns its trimmed stdout. A failure's error
// carries the command's stderr, which says what went wrong.
func output(cmd *exec.Cmd) (string, error) {
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		name := filepath.Base(cmd.Path)
		if len(cmd.Args) > 1 {
			name += " " + cmd.Args[1]
		}
		if msg := strings.TrimSpace(stderr.String()); msg != "" {
			return "", fmt.Errorf("%s: %s", name, msg)
		}
		return "", fmt.Errorf("%s: %w", name, err)
	}
	return strings.TrimSpace(string(out)), nil
}

// run runs cmd, discarding its stdout; see output for errors
func run(cmd *exec.Cmd) error {
	_, err := output(cmd)
	return err
}

// notify logs a message and shows it as a macOS notification, since
// rex has no equivalent of tmux display-message. osascript isn't waited
// on, so its startup doesn't hold up the caller.
func notify(msg string) {
	if f, err := os.OpenFile(filepath.Join(stateDir(), "rmx.log"),
		os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o644); err == nil {
		fmt.Fprintln(f, "rmx: "+msg)
		f.Close()
	}
	cmd := exec.Command("osascript", "-", msg)
	cmd.Stdin = strings.NewReader(`on run argv
  display notification (item 1 of argv) with title "rmx"
end run`)
	_ = cmd.Start()
}

var nonSlug = regexp.MustCompile(`[^a-z0-9]+`)

// slugify makes lowercase kebab-case, safe as a branch, workspace and
// directory name
func slugify(s string) string {
	return strings.Trim(nonSlug.ReplaceAllString(strings.ToLower(s), "-"), "-")
}

// shorten caps a slug at 50 characters without a trailing hyphen
func shorten(s string) string {
	if len(s) > 50 {
		s = s[:50]
	}
	return strings.TrimRight(s, "-")
}

// repoRoot is the repo containing dir: jj's root, else git's
func repoRoot(dir string) (string, error) {
	if root, err := output(command(dir, "jj", "root")); err == nil {
		return root, nil
	}
	return output(command(dir, "git", "rev-parse", "--show-toplevel"))
}

// isJJ reports whether dir is in a jj repo (the usual case)
func isJJ(dir string) bool {
	return command(dir, "jj", "root").Run() == nil
}

// worktreesOf is where a checkout's worktrees live, matching workmux's
// layout: <repo>__worktrees/<branch>
func worktreesOf(checkout string) string {
	return strings.TrimSuffix(checkout, "/") + "__worktrees"
}

// metaDir holds a worktree's state (the agent's prompt, the rex session
// it lives in), kept outside the worktree so jj never snapshots it.
func metaDir(wt string) string {
	return filepath.Join(stateDir(), "worktrees",
		filepath.Base(filepath.Dir(wt))+"__"+filepath.Base(wt))
}

// self is the path that runs rmx again: the nix wrapper when there is
// one (it sets RMX_SELF), so panes get the wrapper's PATH.
func self() string {
	if s := os.Getenv("RMX_SELF"); s != "" {
		return s
	}
	if exe, err := os.Executable(); err == nil {
		return exe
	}
	return "rmx"
}
