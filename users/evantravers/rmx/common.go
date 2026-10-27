package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"syscall"
)

// xdgDir is the XDG base directory in env, else ~/<fallback>
func xdgDir(env, fallback string) string {
	if dir := os.Getenv(env); dir != "" {
		return dir
	}
	return filepath.Join(os.Getenv("HOME"), fallback)
}

// stateDir holds the log and per-worktree state
func stateDir() string {
	dir := filepath.Join(xdgDir("XDG_STATE_HOME", ".local/state"), "rmx")
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
// on, so its startup doesn't hold up the caller. The script goes in its
// arguments, so it's complete once Start returns even if the caller
// exits at once; setsid keeps it alive when a closing float hangs up
// its process group.
func notify(msg string) {
	if f, err := os.OpenFile(filepath.Join(stateDir(), "rmx.log"),
		os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o644); err == nil {
		fmt.Fprintln(f, "rmx: "+msg)
		f.Close()
	}
	cmd := exec.Command("osascript",
		"-e", "on run argv",
		"-e", `display notification (item 1 of argv) with title "rmx"`,
		"-e", "end run",
		msg)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
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

// repoRoot is the repo containing dir: jj's root (the usual case, and
// reported as jj), else git's
func repoRoot(dir string) (root string, jj bool, err error) {
	if root, err := output(command(dir, "jj", "root")); err == nil {
		return root, true, nil
	}
	root, err = output(command(dir, "git", "rev-parse", "--show-toplevel"))
	return root, false, err
}

// Worktrees live next to their main checkout, matching workmux's
// layout: <repo>__worktrees/<branch>
const worktreesSuffix = "__worktrees"

// projectRoot is the project dir belongs to: its repo's root, mapped
// from a worktree back to the main checkout, so a subdirectory or an
// agent's worktree stands for the project itself
func projectRoot(dir string) (root string, jj bool, err error) {
	if root, jj, err = repoRoot(dir); err != nil {
		return "", false, fmt.Errorf("%s is not in a repository", dir)
	}
	if main, ok := mainOf(root); ok {
		root = main
	}
	return root, jj, nil
}

// worktreesOf is where a checkout's worktrees live
func worktreesOf(checkout string) string {
	return strings.TrimSuffix(checkout, "/") + worktreesSuffix
}

// mainOf is the main checkout a worktree belongs to, reporting false
// when wt isn't in a worktrees directory
func mainOf(wt string) (string, bool) {
	return strings.CutSuffix(filepath.Dir(wt), worktreesSuffix)
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
