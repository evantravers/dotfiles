package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// remove is `wt rm [-y] [--notify] [name]`. --notify reports the outcome
// as a notification, for init.lua, which runs it detached.
func remove(args []string) int {
	yes, toNotify, name := false, false, ""
	for _, a := range args {
		switch a {
		case "-y", "--yes":
			yes = true
		case "--notify":
			toNotify = true
		default:
			name = a
		}
	}
	removed, session, err := removeWorktree(name, yes)
	switch {
	case err != nil && toNotify:
		notify("rm failed: " + err.Error())
	case err != nil:
		fmt.Fprintln(os.Stderr, "wt rm:", err)
	case removed == "":
	case toNotify:
		notify(fmt.Sprintf("removed '%s'", removed))
	default:
		fmt.Printf("wt: removed '%s'\n", removed)
	}
	// Kill the rex session last: it may be the one running this command
	if session != "" {
		_, _ = rex("session", "kill", session)
	}
	if err != nil {
		return 1
	}
	return 0
}

// removeWorktree returns the name of the worktree it removed ("" when
// the user said no) and the rex session it lived in, for the caller to
// close
func removeWorktree(name string, yes bool) (removed, session string, err error) {
	cwd, _ := os.Getwd()
	root, jj, err := repoRoot(cwd)
	if err != nil {
		return "", "", fmt.Errorf("not in a repository")
	}

	// Inside a worktree: <repo>__worktrees/<name> belongs to <repo>
	main := root
	if m, ok := mainOf(root); ok {
		main = m
		if name == "" {
			name = filepath.Base(root)
		}
	}

	if name == "" || !yes {
		var ok bool
		if name, ok, err = askRemove(main, name); err != nil || !ok {
			return "", "", err
		}
	}
	wt := filepath.Join(worktreesOf(main), name)
	if !isDir(wt) {
		return "", "", fmt.Errorf("no worktree at %s", wt)
	}

	if jj {
		// Snapshot the workspace first so its last edits are kept in its
		// change, then drop it; the change itself stays in the repo. The
		// forget itself needs no snapshot of the main checkout. A
		// workspace whose change was squashed or rebased from elsewhere
		// is stale, and jj status refuses it until it's updated (a no-op
		// otherwise); edits it never snapshotted land in a recovery
		// commit of their own.
		if err := run(command(wt, "jj", "workspace", "update-stale")); err != nil {
			return "", "", err
		}
		if err := run(command(wt, "jj", "status")); err != nil {
			return "", "", err
		}
		if err := run(command(main, "jj", "workspace", "forget", "--ignore-working-copy", name)); err != nil {
			return "", "", err
		}
		if err := os.RemoveAll(wt); err != nil {
			return "", "", err
		}
	} else {
		// Refuses when the worktree has uncommitted changes; the branch stays
		if err := run(command(main, "git", "worktree", "remove", wt)); err != nil {
			return "", "", err
		}
	}

	meta := metaDir(wt)
	data, _ := os.ReadFile(filepath.Join(meta, "session"))
	os.RemoveAll(meta)
	return name, strings.TrimSpace(string(data)), nil
}

// askRemove confirms on the terminal, or lists main's worktrees when
// there's no name to confirm. It reports false when the user says no.
func askRemove(main, name string) (string, bool, error) {
	if name == "" {
		names, err := worktreeNames(main)
		if err != nil || len(names) == 0 {
			return "", false, fmt.Errorf("no worktrees for %s", filepath.Base(main))
		}
		return "", false, fmt.Errorf("which worktree? %s", strings.Join(names, ", "))
	}
	fmt.Printf("Remove worktree '%s' and close its rex session? [y/N] ", name)
	answer, _ := bufio.NewReader(os.Stdin).ReadString('\n')
	answer = strings.ToLower(strings.TrimSpace(answer))
	return name, answer == "y" || answer == "yes", nil
}

// worktreeNames lists the worktrees next to main
func worktreeNames(main string) ([]string, error) {
	entries, err := os.ReadDir(worktreesOf(main))
	if err != nil {
		return nil, err
	}
	var names []string
	for _, e := range entries {
		if e.IsDir() {
			names = append(names, e.Name())
		}
	}
	return names, nil
}
