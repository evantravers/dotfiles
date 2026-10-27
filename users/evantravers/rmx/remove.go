package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// remove is `rmx rm [-y] [name]`
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
		fmt.Fprintln(os.Stderr, "rmx rm:", err)
		return 1
	}
	return 0
}

func removeWorktree(name string, yes bool) error {
	cwd, _ := os.Getwd()
	root, err := repoRoot(cwd)
	if err != nil {
		return fmt.Errorf("not in a repository")
	}

	// Inside a worktree: <repo>__worktrees/<name> belongs to <repo>
	main := root
	if parent := filepath.Dir(root); strings.HasSuffix(parent, "__worktrees") {
		main = strings.TrimSuffix(parent, "__worktrees")
		if name == "" {
			name = filepath.Base(root)
		}
	}
	wts := worktreesOf(main)

	// The UI starts only when there's something to ask
	if name == "" || !yes {
		ok, err := askRemove(wts, &name)
		if err != nil || !ok {
			return err
		}
	}
	wt := filepath.Join(wts, name)
	if info, err := os.Stat(wt); err != nil || !info.IsDir() {
		return fmt.Errorf("no worktree at %s", wt)
	}

	if isJJ(main) {
		// Snapshot the workspace first so its last edits are kept in its
		// change, then drop it; the change itself stays in the repo. The
		// forget itself needs no snapshot of the main checkout.
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
	fmt.Printf("rmx: removed '%s'\n", name)
	if session := strings.TrimSpace(string(data)); session != "" {
		_, _ = rex("session", "kill", session)
	}
	return nil
}

// askRemove picks a worktree when name is empty, then confirms. It
// reports false when the user backs out.
func askRemove(wts string, name *string) (bool, error) {
	var names []string
	if *name == "" {
		entries, err := os.ReadDir(wts)
		if err != nil {
			return false, fmt.Errorf("no worktrees for %s", filepath.Base(strings.TrimSuffix(wts, "__worktrees")))
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
	if *name == "" {
		i, ok := u.filter("", "Remove which worktree?", names)
		if !ok {
			return false, nil
		}
		*name = names[i]
	}
	return u.confirm(fmt.Sprintf("Remove worktree '%s' and close its rex session?", *name)), nil
}
