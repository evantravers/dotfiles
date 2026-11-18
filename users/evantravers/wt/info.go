package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// The JSON helpers init.lua reads. Lua in rex can't list a directory or
// run a pipeline, so the repo logic stays here.

func printJSON(v any) int {
	if err := json.NewEncoder(os.Stdout).Encode(v); err != nil {
		fmt.Fprintln(os.Stderr, "wt:", err)
		return 1
	}
	return 0
}

// info is `wt __info <dir>`: dir's project (its main checkout), its
// worktrees, and the worktree dir is in, if any
func info(args []string) int {
	if len(args) != 1 {
		fmt.Fprintln(os.Stderr, "usage: wt __info <dir>")
		return 2
	}
	root, jj, err := repoRoot(args[0])
	if err != nil {
		fmt.Fprintf(os.Stderr, "wt: %s is not in a repository\n", args[0])
		return 1
	}
	main, current := root, ""
	if m, ok := mainOf(root); ok {
		main, current = m, filepath.Base(root)
	}
	names, _ := worktreeNames(main)
	if names == nil {
		names = []string{}
	}
	return printJSON(map[string]any{
		"root":      main,
		"name":      filepath.Base(main),
		"jj":        jj,
		"current":   current,
		"worktrees": names,
	})
}

// listProjects is `wt __projects`: sesh's config and zoxide entries, one
// per directory, with the label of each one's rex session
func listProjects() int {
	ps, err := projects()
	if err != nil {
		fmt.Fprintln(os.Stderr, "wt:", err)
		return 1
	}
	type entry struct {
		Path  string `json:"path"`
		Name  string `json:"name"`
		Label string `json:"label"`
	}
	out := []entry{}
	seen := map[string]bool{}
	for _, p := range ps {
		if seen[p.Path] {
			continue
		}
		seen[p.Path] = true
		out = append(out, entry{Path: p.Path, Name: p.Name, Label: p.label()})
	}
	return printJSON(out)
}
