package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

// task is what the UI collects and create works from
type task struct {
	path   string // the project's main checkout
	prompt string // the agent's task; "" for a plain worktree named title
	title  string // slug, used when there is no prompt
}

// launch collects a task (unless prompt is given, which uses the current
// repo) and hands it to create, in the background when running under a
// multiplexer.
func launch(prompt string) int {
	cwd, _ := os.Getwd()
	t := task{path: cwd, prompt: prompt}
	if root, err := repoRoot(cwd); err == nil {
		t.path = root
	}

	if prompt == "" {
		u := startUI()
		ok := ask(u, &t)
		u.close()
		// User aborts (esc, ctrl+c) are not errors
		if !ok {
			return 0
		}
	}

	// The prompt waits in the state dir; create moves it into the
	// worktree's state
	f, err := os.CreateTemp(stateDir(), "prompt.")
	if err != nil {
		fmt.Fprintln(os.Stderr, "rmx:", err)
		return 1
	}
	_, err = f.WriteString(t.prompt)
	if cerr := f.Close(); err == nil {
		err = cerr
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "rmx:", err)
		return 1
	}
	args := []string{t.path, f.Name(), t.title}

	// Everything after this point — branch naming, provisioning, devenv,
	// agent launch — happens in the background. The user only hears back
	// via a notification: an issue, or "created". setsid keeps it alive
	// when the floating layer that started it closes.
	if os.Getenv("REX_SESSION") != "" || os.Getenv("TMUX") != "" {
		cmd := exec.Command(self(), append([]string{"__create"}, args...)...)
		cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
		if err := cmd.Start(); err != nil {
			fmt.Fprintln(os.Stderr, "rmx:", err)
			return 1
		}
		notify("creating worktree in the background…")
		return 0
	}
	return create(args)
}

// ask fills in t from the user, reporting false when they back out
func ask(u *ui, t *task) bool {
	choice, ok := u.choose("Where should the agent work?", []string{
		"Current project: " + filepath.Base(t.path),
		"Pick another project…",
	})
	if !ok {
		return false
	}
	if choice == 1 {
		ps, err := projects()
		if err != nil {
			u.message("rmx: " + err.Error())
			return false
		}
		items := make([]string, len(ps))
		for i, p := range ps {
			items[i] = p.display()
		}
		i, ok := u.filter("📂 Projects", "Pick a project…", items)
		if !ok {
			return false
		}
		t.path = ps[i].Path
	}

	if t.prompt, ok = u.write("Task for the agent", "Describe the task…", 8); !ok {
		return false
	}
	if t.prompt != "" {
		return true
	}

	// Prompt-less launch: fall back to a hand-typed worktree title.
	// Branch, workspace and directory name: "Fix login bug" → fix-login-bug
	title, ok := u.input("Worktree title (empty to abort)")
	if !ok || title == "" {
		return false
	}
	if t.title = shorten(slugify(title)); t.title == "" {
		u.message(fmt.Sprintf("rmx: no usable name in %q", title))
		return false
	}
	return true
}

// create is `rmx __create <path> <prompt_file> <title>`
func create(args []string) int {
	if len(args) != 3 {
		fmt.Fprintln(os.Stderr, "usage: rmx __create <path> <prompt_file> <title>")
		return 2
	}
	t := task{path: args[0], title: args[2]}
	data, err := os.ReadFile(args[1])
	os.Remove(args[1])
	if err != nil {
		notify("failed: " + err.Error())
		return 1
	}
	t.prompt = string(data)

	branch, err := t.create()
	if err != nil {
		notify("failed: " + err.Error())
		return 1
	}
	notify(fmt.Sprintf("created '%s' — agent starting", branch))
	return 0
}

// create provisions the worktree and opens a rex session for the agent,
// labelled "<project>: <branch>" and starting in the worktree. It returns the
// branch name.
func (t task) create() (string, error) {
	jj := isJJ(t.path)

	branch := t.title
	if t.prompt != "" {
		var err error
		if branch, err = branchName(t.path, t.prompt); err != nil {
			return "", err
		}
	}

	wt, err := t.addWorktree(jj, branch)
	if err != nil {
		return "", err
	}
	branch = filepath.Base(wt)

	// The agent reads its task at launch time from the worktree's state
	// dir (outside the worktree, so jj never snapshots it)
	meta := metaDir(wt)
	if err := os.RemoveAll(meta); err != nil {
		return "", err
	}
	if err := os.MkdirAll(meta, 0o755); err != nil {
		return "", err
	}
	promptFile := ""
	if t.prompt != "" {
		promptFile = filepath.Join(meta, "PROMPT.md")
		if err := os.WriteFile(promptFile, []byte(t.prompt), 0o644); err != nil {
			return "", err
		}
	}

	if err := devenvRebind(t.path, wt); err != nil {
		return "", fmt.Errorf("devenv rebind: %w", err)
	}

	// The agent's window: a shell in the worktree that starts the agent
	// itself (see shellBlock), so there's no prompt to poll for. The
	// shell stays open when the agent exits. The agent stays unquoted:
	// it may carry arguments.
	run := paneQuote(self()) + " __agent --main " + paneQuote(t.path)
	if promptFile != "" {
		run += " --prompt " + paneQuote(promptFile)
	}
	run += " -- " + agentCommand(t.path)

	label := filepath.Base(t.path) + ": " + branch
	session, err := newSession(label, "agent", shellBlock(wt, run))
	if err != nil {
		return "", fmt.Errorf("create rex session: %w", err)
	}
	if err := os.WriteFile(filepath.Join(meta, "session"), []byte(session+"\n"), 0o644); err != nil {
		return "", err
	}

	// Don't switch to it by default, matching wmx. With RMX_FOCUS=1,
	// show the new session in a connected app.
	if os.Getenv("RMX_FOCUS") == "1" {
		if client := firstAppClient(); client != "" {
			_ = selectSession(client, session, "")
		}
	}
	return branch, nil
}

// branchName asks pi for a branch name for the task
func branchName(dir, prompt string) (string, error) {
	out, err := output(command(dir, "pi", "-p",
		"Generate a concise git branch name based on the task description.\n"+
			"Rules: 2-4 words, kebab-case, all lowercase, no prefix like feature/. "+
			"Output ONLY the branch name.\n\n"+prompt))
	if err != nil {
		return "", fmt.Errorf("auto-name branch: %w", err)
	}
	for _, line := range strings.Split(out, "\n") {
		if s := shorten(slugify(line)); s != "" && strings.Count(s, "-") < 6 {
			return s, nil
		}
	}
	return "", errors.New("auto-name branch: pi gave no usable name")
}

// addWorktree adds a jj workspace (or git worktree) for branch at
// <repo>__worktrees/<branch>, next to the main checkout, and returns its
// path. A taken name (directory, branch or jj workspace) gets a numeric
// suffix, since there is no user to ask.
func (t task) addWorktree(jj bool, branch string) (string, error) {
	base := baseRevision(jj, t.path)

	var taken []string
	if jj {
		out, err := output(command(t.path, "jj", "workspace", "list",
			"--ignore-working-copy", "-T", `name ++ "\n"`))
		if err != nil {
			return "", err
		}
		taken = strings.Split(out, "\n")
	}
	wts := worktreesOf(t.path)
	free := func(name string) bool {
		if _, err := os.Stat(filepath.Join(wts, name)); err == nil {
			return false
		}
		if jj {
			for _, w := range taken {
				if w == name {
					return false
				}
			}
			return true
		}
		return command(t.path, "git", "show-ref", "--verify", "--quiet", "refs/heads/"+name).Run() != nil
	}
	name := ""
	for _, suffix := range []string{"", "-2", "-3", "-4", "-5"} {
		if free(branch + suffix) {
			name = branch + suffix
			break
		}
	}
	if name == "" {
		return "", fmt.Errorf("no free worktree name for %s", branch)
	}
	wt := filepath.Join(wts, name)

	// jj workspace add won't create intermediate directories (git does)
	if err := os.MkdirAll(wts, 0o755); err != nil {
		return "", err
	}
	var cmd *exec.Cmd
	if jj {
		args := []string{"workspace", "add", wt, "--name", name}
		if base != "" {
			args = append(args, "--revision", base)
		}
		cmd = command(t.path, "jj", args...)
	} else {
		args := []string{"worktree", "add", "-b", name, wt}
		if base != "" {
			args = append(args, base)
		}
		cmd = command(t.path, "git", args...)
	}
	if err := run(cmd); err != nil {
		return "", fmt.Errorf("provision worktree: %w", err)
	}
	return wt, nil
}

// baseRevision is the repo's trunk when there is one (workmux's
// base_branch = "auto" behaved this way), else "" for the current
// checkout. jj's trunk() falls back to root(), the empty commit, so
// that's excluded. Reading the commit graph needs no working-copy
// snapshot.
func baseRevision(jj bool, dir string) string {
	if jj {
		out, _ := output(command(dir, "jj", "log", "--ignore-working-copy", "--no-graph",
			"--limit", "1", "-r", "trunk() ~ root()", "-T", "commit_id"))
		if out != "" {
			return "trunk()"
		}
		return ""
	}
	ref, err := output(command(dir, "git", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"))
	if err != nil {
		return ""
	}
	def := strings.TrimPrefix(ref, "origin/")
	if command(dir, "git", "show-ref", "--verify", "--quiet", "refs/heads/"+def).Run() != nil {
		return ""
	}
	return def
}

// agentCommand is the project's agent: .workmux.yaml's agent key, else pi
func agentCommand(dir string) string {
	data, err := os.ReadFile(filepath.Join(dir, ".workmux.yaml"))
	if err != nil {
		return "pi"
	}
	for _, line := range strings.Split(string(data), "\n") {
		if rest, ok := strings.CutPrefix(line, "agent:"); ok {
			if a := strings.TrimSpace(rest); a != "" {
				return a
			}
		}
	}
	return "pi"
}
