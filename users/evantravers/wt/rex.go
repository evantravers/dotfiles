package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

// rex runs the rex CLI and returns its stdout; see output for errors
func rex(args ...string) ([]byte, error) {
	out, err := output(command("", "rex", args...))
	return []byte(out), err
}

// rexCall calls a server API method with input as JSON, decoding the
// reply into out (when not nil)
func rexCall(method string, input, out any) error {
	in, err := json.Marshal(input)
	if err != nil {
		return err
	}
	reply, err := rex("api", "call", method, string(in))
	if err != nil {
		return fmt.Errorf("%s: %w", method, err)
	}
	if out == nil {
		return nil
	}
	return json.Unmarshal(reply, out)
}

// newSession creates a session with one window, returning its ID. An
// empty label lets rex choose one.
func newSession(label, window string, layout map[string]any) (string, error) {
	var created struct {
		ID string `json:"session_id"`
	}
	input := map[string]any{
		"initial_windows": []any{map[string]any{
			"window_label": window,
			"layout":       layout,
		}},
	}
	if label != "" {
		input["label"] = label
	}
	err := rexCall("session.create", input, &created)
	if err == nil && created.ID == "" {
		err = fmt.Errorf("session.create returned no session")
	}
	return created.ID, err
}

// firstAppClient is the first connected rex app, or ""
func firstAppClient() string {
	out, err := rex("client", "ls", "--json")
	if err != nil {
		return ""
	}
	var ls struct {
		Clients []struct {
			ID   string `json:"client_id"`
			Info struct {
				Kind string `json:"kind"`
			} `json:"info"`
		} `json:"clients"`
	}
	if json.Unmarshal(out, &ls) != nil {
		return ""
	}
	for _, c := range ls.Clients {
		if c.Info.Kind == "app" {
			return c.ID
		}
	}
	return ""
}

// selectSession shows a session in a client
func selectSession(client, session string) error {
	_, err := rex("-C", client, "do", "session.select", "session_id="+session)
	return err
}

// One terminal block for a rex layout: the preferred shell in a
// directory, optionally running a command first and staying open as an
// interactive shell afterwards.
//
// fish runs the command with --init-command: after its config loads but
// before the first prompt, so the devenv prompt hook can't swallow it
// (typed-ahead input, rex's initial_input, gets eaten by the hook).
// Other shells fall back to initial_input.
func shellBlock(cwd, run string) map[string]any {
	opts := map[string]any{"cwd": cwd}
	sh := shellBin()
	switch {
	case run != "" && isFish(sh):
		opts["shell"] = "none"
		opts["command"] = []string{sh, "-l", "-C", run}
	default:
		if sh != "" {
			opts["shell"] = sh
		}
		if run != "" {
			opts["initial_input"] = run + "\n"
		}
	}
	return map[string]any{"block": map[string]any{
		"flavor":  "com.superlogical.terminal.shell",
		"options": opts,
	}}
}

// shellBin is the shell new panes run: WT_SHELL, else fish from PATH.
// rex's own default is the macOS account shell (zsh).
func shellBin() string {
	if sh := os.Getenv("WT_SHELL"); sh != "" {
		return sh
	}
	sh, _ := exec.LookPath("fish")
	return sh
}

func isFish(sh string) bool { return filepath.Base(sh) == "fish" }

var unsafeWord = regexp.MustCompile(`[^A-Za-z0-9_./:=@%+,-]`)

// paneQuote quotes one word for the shell the panes run: fish takes
// single quotes with only \ and ' escaped; POSIX shells take '…' with
// ' written as '\”.
func paneQuote(s string) string {
	if s != "" && !unsafeWord.MatchString(s) {
		return s
	}
	if isFish(shellBin()) {
		s = strings.ReplaceAll(s, `\`, `\\`)
		return "'" + strings.ReplaceAll(s, `'`, `\'`) + "'"
	}
	return "'" + strings.ReplaceAll(s, `'`, `'\''`) + "'"
}

// ------------------------------------------------------------- projects ---

// project is a checkout at ~/src/<forge>/<user>/<project>
type project struct {
	Name, Path string
}

// isRepo reports whether dir is a checkout: git's .git (a directory,
// or a file in a worktree) or jj's .jj sits inside
func isRepo(dir string) bool {
	return exists(filepath.Join(dir, ".git")) || exists(filepath.Join(dir, ".jj"))
}

// projects lists the checkouts under ~/src: the repositories exactly
// three levels down (~/src/<forge>/<user>/<project>), named
// <user>/<project> (the forge level is noise: github.com holds
// everything that matters). The .git/.jj test keeps wiki folders and
// wt's own <repo>__worktrees containers out.
func projects() ([]project, error) {
	src := filepath.Join(os.Getenv("HOME"), "src")
	// dirs is the visible subdirectories of path
	dirs := func(path string) ([]os.DirEntry, error) {
		entries, err := os.ReadDir(path)
		if err != nil {
			return nil, err
		}
		out := entries[:0]
		for _, e := range entries {
			if e.IsDir() && !strings.HasPrefix(e.Name(), ".") {
				out = append(out, e)
			}
		}
		return out, nil
	}
	forges, err := dirs(src)
	if err != nil {
		return nil, err
	}
	var ps []project
	for _, forge := range forges {
		users, err := dirs(filepath.Join(src, forge.Name()))
		if err != nil {
			continue
		}
		for _, user := range users {
			dir := filepath.Join(src, forge.Name(), user.Name())
			repos, err := dirs(dir)
			if err != nil {
				continue
			}
			for _, repo := range repos {
				path := filepath.Join(dir, repo.Name())
				if !isRepo(path) {
					continue
				}
				ps = append(ps, project{
					Name: user.Name() + "/" + repo.Name(),
					Path: path,
				})
			}
		}
	}
	return ps, nil
}
