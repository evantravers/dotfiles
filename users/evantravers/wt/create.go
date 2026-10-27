package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"syscall"
)

// task is what the UI collects and create works from
type task struct {
	path   string // the project's main checkout
	jj     bool   // path is a jj repo, else git
	prompt string // the agent's task; "" for a plain worktree named title
	title  string // slug, used when there is no prompt
}

// launch collects a task (unless prompt is given, which uses the current
// repo) and hands it to create, in the background when running under a
// multiplexer.
func launch(prompt string) int {
	var u *ui
	if prompt == "" {
		u = startUI()
	}
	cwd, _ := os.Getwd()
	t := task{path: cwd, prompt: prompt}
	root, jj, rootErr := projectRoot(cwd)
	if rootErr == nil {
		t.path, t.jj = root, jj
	}
	if u != nil {
		ok := ask(u, &t, rootErr)
		u.close()
		// User aborts (esc, ctrl+c) are not errors
		if !ok {
			return 0
		}
	} else if rootErr != nil {
		fmt.Fprintln(os.Stderr, "wt:", rootErr)
		return 1
	}

	if os.Getenv("REX_SESSION") == "" && os.Getenv("TMUX") == "" {
		return t.createNotify()
	}

	// Everything after this point — naming, provisioning, devenv,
	// agent launch — happens in the background. The user only hears back
	// via a notification: an issue, or "created". setsid keeps it alive
	// when the floating layer that started it closes. The prompt waits in
	// the state dir; create moves it into the worktree's state.
	f, err := os.CreateTemp(stateDir(), "prompt.")
	if err != nil {
		fmt.Fprintln(os.Stderr, "wt:", err)
		return 1
	}
	_, err = f.WriteString(t.prompt)
	if cerr := f.Close(); err == nil {
		err = cerr
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "wt:", err)
		return 1
	}
	vcs := "git"
	if t.jj {
		vcs = "jj"
	}
	cmd := exec.Command(self(), "__create", t.path, vcs, f.Name(), t.title)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	if err := cmd.Start(); err != nil {
		fmt.Fprintln(os.Stderr, "wt:", err)
		return 1
	}
	notify("creating worktree in the background…")
	return 0
}

// ask fills in t from the user, reporting false when they back out.
// rootErr is why t.path isn't a project, if it isn't.
func ask(u *ui, t *task, rootErr error) bool {
	choice, ok := u.choose("Where should the agent work?", []string{
		"Current project: " + filepath.Base(t.path),
		"Pick another project…",
	})
	if !ok {
		return false
	}
	if choice == 0 && rootErr != nil {
		u.message("wt: " + rootErr.Error())
		return false
	}
	if choice == 1 {
		ps, err := projects()
		if err != nil {
			u.message("wt: " + err.Error())
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
		root, jj, err := projectRoot(ps[i].Path)
		if err != nil {
			u.message("wt: " + err.Error())
			return false
		}
		t.path, t.jj = root, jj
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
		u.message(fmt.Sprintf("wt: no usable name in %q", title))
		return false
	}
	return true
}

// create is `wt __create <path> <jj|git> <prompt_file> <title>`, with
// the project launch already found
func create(args []string) int {
	if len(args) != 4 {
		fmt.Fprintln(os.Stderr, "usage: wt __create <path> <jj|git> <prompt_file> <title>")
		return 2
	}
	data, err := os.ReadFile(args[2])
	os.Remove(args[2])
	if err != nil {
		notify("failed: " + err.Error())
		return 1
	}
	t := task{path: args[0], jj: args[1] == "jj", prompt: string(data), title: args[3]}
	return t.createNotify()
}

// createNotify runs create and reports how it went in a notification
func (t task) createNotify() int {
	name, err := t.create()
	if err != nil {
		notify("failed: " + err.Error())
		return 1
	}
	notify(fmt.Sprintf("created '%s' — agent starting", name))
	return 0
}

// create provisions the worktree and opens a rex session for the agent,
// starting in the worktree. The session goes unlabelled: rex names it
// and the agent renames it once it knows the task. It returns the
// workspace name (the branch name in a git repo). A failure after the
// worktree exists removes it again, so a retry doesn't leave an orphan
// behind.
func (t task) create() (name string, err error) {
	name = t.title
	if t.prompt != "" {
		if name, err = autoName(t.path, t.prompt); err != nil {
			return "", err
		}
	}

	wt, err := t.addWorktree(name)
	if err != nil {
		return "", err
	}
	name = filepath.Base(wt)
	session := ""
	defer func() {
		if err != nil {
			if session != "" {
				_, _ = rex("session", "kill", session)
			}
			t.discard(wt)
		}
	}()

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

	session, err = newSession("", "agent", shellBlock(wt, run))
	if err != nil {
		return "", fmt.Errorf("create rex session: %w", err)
	}
	if err := os.WriteFile(filepath.Join(meta, "session"), []byte(session+"\n"), 0o644); err != nil {
		return "", err
	}

	// Creation is background work: don't steal focus. With WT_FOCUS=1,
	// show the new session in a connected app.
	if os.Getenv("WT_FOCUS") == "1" {
		if client := firstAppClient(); client != "" {
			_ = selectSession(client, session)
		}
	}
	return name, nil
}

// discard undoes addWorktree and create's state for wt
func (t task) discard(wt string) {
	name := filepath.Base(wt)
	if t.jj {
		_ = run(command(t.path, "jj", "workspace", "forget", "--ignore-working-copy", name))
	} else {
		_ = run(command(t.path, "git", "worktree", "remove", "--force", wt))
		_ = run(command(t.path, "git", "branch", "-D", name))
	}
	os.RemoveAll(wt)
	os.RemoveAll(metaDir(wt))
}

// autoName asks Apple's on-device model (fm) for a name for the task:
// no tokens, no API key, so no credential prompts from the background.
func autoName(dir, prompt string) (string, error) {
	out, err := output(command(dir, "fm", "respond", "--no-stream", "--greedy",
		"--instructions",
		"Generate a concise git branch name based on the task description. "+
			"Rules: 2-4 words, kebab-case, all lowercase, no prefix like feature/. "+
			"Output ONLY the branch name.",
		prompt))
	if err != nil {
		return "", fmt.Errorf("auto-name: %w", err)
	}
	for _, line := range strings.Split(out, "\n") {
		if s := shorten(slugify(line)); s != "" && strings.Count(s, "-") < 6 {
			return s, nil
		}
	}
	return "", errors.New("auto-name branch: fm gave no usable name")
}

// addWorktree adds a jj workspace (or git worktree) named slug at
// <repo>__worktrees/<slug>, next to the main checkout, and returns its
// path. A taken name (directory, branch or jj workspace) gets a numeric
// suffix, since there is no user to ask.
func (t task) addWorktree(slug string) (string, error) {
	jj := t.jj
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
			return !slices.Contains(taken, name)
		}
		return command(t.path, "git", "show-ref", "--verify", "--quiet", "refs/heads/"+name).Run() != nil
	}
	name := ""
	for _, suffix := range []string{"", "-2", "-3", "-4", "-5"} {
		if free(slug + suffix) {
			name = slug + suffix
			break
		}
	}
	if name == "" {
		return "", fmt.Errorf("no free worktree name for %s", slug)
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

// baseRevision is the repo's trunk when there is one — new work starts
// from the base branch, not from wherever this checkout happens to be —
// else "" for the current checkout. jj's trunk() falls back to root(), the empty commit, so
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

// agentCommand is the project's agent: the agent key in .wt.yaml, else
// pi. .workmux.yaml is read as a fallback while projects still carry
// workmux config.
func agentCommand(dir string) string {
	for _, file := range []string{".wt.yaml", ".workmux.yaml"} {
		data, err := os.ReadFile(filepath.Join(dir, file))
		if err != nil {
			continue
		}
		for _, line := range strings.Split(string(data), "\n") {
			if rest, ok := strings.CutPrefix(line, "agent:"); ok {
				if a := strings.TrimSpace(rest); a != "" {
					return a
				}
			}
		}
	}
	return "pi"
}
