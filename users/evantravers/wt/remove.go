package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// remove is `wt rm [-y] [name]`
func remove(args []string) int {
	yes, name := false, ""
	for _, a := range args {
		if a == "-y" || a == "--yes" {
			yes = true
		} else {
			name = a
		}
	}
	if err := removeWorktree(name, yes); err != nil {
		fmt.Fprintln(os.Stderr, "wt rm:", err)
		return 1
	}
	return 0
}

func removeWorktree(name string, yes bool) error {
	cwd, _ := os.Getwd()
	root, jj, err := repoRoot(cwd)
	if err != nil {
		return fmt.Errorf("not in a repository")
	}

	// Inside a worktree: <repo>__worktrees/<name> belongs to <repo>
	main := root
	if m, ok := mainOf(root); ok {
		main = m
		if name == "" {
			name = filepath.Base(root)
		}
	}
	wts := worktreesOf(main)

	// The UI starts only when there's something to ask
	if name == "" || !yes {
		var ok bool
		if name, ok, err = askRemove(main, name); err != nil || !ok {
			return err
		}
	}
	wt := filepath.Join(wts, name)
	if info, err := os.Stat(wt); err != nil || !info.IsDir() {
		return fmt.Errorf("no worktree at %s", wt)
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
			return err
		}
		if err := run(command(wt, "jj", "status")); err != nil {
			return err
		}
		if err := run(command(main, "jj", "workspace", "forget", "--ignore-working-copy", name)); err != nil {
			return err
		}
		if err := os.RemoveAll(wt); err != nil {
			return err
		}
	} else {
		// Refuses when the worktree has uncommitted changes; the branch stays
		if err := run(command(main, "git", "worktree", "remove", wt)); err != nil {
			return err
		}
	}

	// Kill the rex session last: it may be the one running this command
	meta := metaDir(wt)
	data, _ := os.ReadFile(filepath.Join(meta, "session"))
	os.RemoveAll(meta)
	fmt.Printf("wt: removed '%s'\n", name)
	if session := strings.TrimSpace(string(data)); session != "" {
		_, _ = rex("session", "kill", session)
	}
	return nil
}

// askRemove picks one of main's worktrees when name is empty, then
// confirms. It reports false when the user backs out.
func askRemove(main, name string) (string, bool, error) {
	var names []string
	if name == "" {
		entries, err := os.ReadDir(worktreesOf(main))
		if err != nil {
			return "", false, fmt.Errorf("no worktrees for %s", filepath.Base(main))
		}
		for _, e := range entries {
			if e.IsDir() {
				names = append(names, e.Name())
			}
		}
		sort.Strings(names)
	}

	u := startUI()
	defer u.close()
	if name == "" {
		i, ok := u.filter("", "Remove which worktree?", names)
		if !ok {
			return "", false, nil
		}
		name = names[i]
	}
	return name, u.confirm(fmt.Sprintf("Remove worktree '%s' and close its rex session?", name)), nil
}
