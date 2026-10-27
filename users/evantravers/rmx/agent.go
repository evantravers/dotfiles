package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

var errNoBinding = errors.New("no devenv binding")

// devenvBinding looks up the devenv binding for the first of paths that
// has one. Bindings live in ~/.local/share/devenv/allowed, a stream of
// JSON objects keyed by absolute path; the latest entry for a path wins.
// It returns the --from/--profile arguments (empty for plain in-tree
// trust), with relative --from paths resolved against main, or
// errNoBinding.
func devenvBinding(main string, paths ...string) ([]string, error) {
	base := os.Getenv("XDG_DATA_HOME")
	if base == "" {
		base = filepath.Join(os.Getenv("HOME"), ".local", "share")
	}
	f, err := os.Open(filepath.Join(base, "devenv", "allowed"))
	if err != nil {
		return nil, errNoBinding
	}
	defer f.Close()

	type entry struct {
		Path     string   `json:"path"`
		From     string   `json:"from"`
		Profiles []string `json:"profiles"`
	}
	latest := map[string]entry{}
	dec := json.NewDecoder(f)
	for {
		var e entry
		if err := dec.Decode(&e); err == io.EOF {
			break
		} else if err != nil {
			return nil, fmt.Errorf("reading devenv bindings: %w", err)
		}
		latest[e.Path] = e
	}

	for _, p := range paths {
		e, ok := latest[p]
		if !ok {
			continue
		}
		if e.From == "" {
			return nil, nil
		}
		from := e.From
		switch {
		case strings.Contains(from, ":"): // flake ref or path:/abs
		case strings.HasPrefix(from, "/"):
			from = "path:" + from
		default: // relative to the main checkout
			dir := filepath.Join(main, from)
			if info, err := os.Stat(dir); err != nil || !info.IsDir() {
				return nil, fmt.Errorf("devenv binding source %s is missing", dir)
			}
			from = "path:" + dir
		}
		args := []string{"--from", from}
		for _, profile := range e.Profiles {
			args = append(args, "--profile", profile)
		}
		return args, nil
	}
	return nil, errNoBinding
}

// devenvRebind copies the main checkout's devenv binding (plain
// auto-activation trust or an out-of-tree --from binding) into the
// worktree, which is a different path and so has no environment without
// this. No-op when the main checkout has no binding.
func devenvRebind(root, wt string) error {
	if _, err := exec.LookPath("devenv"); err != nil {
		return nil
	}
	args, err := devenvBinding(root, root)
	if errors.Is(err, errNoBinding) {
		return nil
	} else if err != nil {
		return err
	}
	return run(command(wt, "devenv", append([]string{"allow"}, args...)...))
}

// agent runs an agent inside the project's devenv environment with
// `devenv shell --from <source>`. The main checkout's env is already
// built and trusted, so this is warm (~seconds), and the agent still
// runs with the worktree as its cwd.
func agent(args []string) int {
	main, prompt := "", ""
loop:
	for len(args) > 0 {
		switch {
		case args[0] == "--main" && len(args) > 1:
			main, args = args[1], args[2:]
		case args[0] == "--prompt" && len(args) > 1:
			prompt, args = args[1], args[2:]
		case args[0] == "--":
			args = args[1:]
			break loop
		default:
			break loop
		}
	}
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "rmx __agent: no agent given")
		return 2
	}
	cwd, _ := os.Getwd()

	// Main checkout for this worktree/workspace: --main from rmx, else
	// git's common dir (git worktrees), else this directory
	if main == "" {
		if common, err := output(command(cwd, "git", "rev-parse", "--git-common-dir")); err == nil && common != "" {
			if !filepath.IsAbs(common) {
				common = filepath.Join(cwd, common)
			}
			main = filepath.Dir(common)
		}
	}
	if main == "" {
		main = cwd
	}

	// The task, using each agent's prompt-passing convention
	cmd := args
	if data, err := os.ReadFile(prompt); err == nil && len(data) > 0 {
		if filepath.Base(args[0]) == "claude" {
			cmd = append(cmd, "--")
		}
		cmd = append(cmd, string(data))
	}

	// Binding lookup: the worktree itself first (rmx copies bindings into
	// new worktrees), then the main checkout. Plain in-tree trust reuses
	// the main checkout's environment. A broken binding stops here: the
	// pane stays open, so the error stays visible.
	devenvArgs, err := devenvBinding(main, cwd, main)
	switch {
	case errors.Is(err, errNoBinding):
		// No binding, but the project has an in-tree devenv: reuse the
		// main checkout's (already built, already trusted) environment
		if !exists(filepath.Join(main, "devenv.nix")) && !exists(filepath.Join(main, "devenv.yaml")) {
			return execve(cmd)
		}
	case err != nil:
		fmt.Fprintln(os.Stderr, "rmx:", err)
		return 2
	}
	if len(devenvArgs) == 0 {
		devenvArgs = []string{"--from", "path:" + main}
	}
	return execve(append(append([]string{"devenv", "shell"}, devenvArgs...), append([]string{"--"}, cmd...)...))
}

func exists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// execve replaces rmx with argv, returning only on failure
func execve(argv []string) int {
	path, err := exec.LookPath(argv[0])
	if err == nil {
		err = syscall.Exec(path, argv, os.Environ())
	}
	fmt.Fprintf(os.Stderr, "rmx: %s: %v\n", argv[0], err)
	return 127
}
