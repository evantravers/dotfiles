package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

// rex runs the rex CLI and returns its stdout. Errors carry rex's
// stderr, which says what went wrong.
func rex(args ...string) ([]byte, error) {
	var stderr bytes.Buffer
	cmd := exec.Command("rex", args...)
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		if msg := strings.TrimSpace(stderr.String()); msg != "" {
			return out, fmt.Errorf("%s", msg)
		}
		return out, err
	}
	return out, nil
}

// rexCall calls a server API method with input as JSON, decoding the
// reply into out (when not nil). session scopes the call; it may be "".
func rexCall(session, method string, input, out any) error {
	in, err := json.Marshal(input)
	if err != nil {
		return err
	}
	args := []string{"api", "call"}
	if session != "" {
		args = append(args, "-s", session)
	}
	reply, err := rex(append(args, method, string(in))...)
	if err != nil {
		return fmt.Errorf("%s: %w", method, err)
	}
	if out == nil {
		return nil
	}
	return json.Unmarshal(reply, out)
}

type rexSession struct {
	ID    string `json:"session_id"`
	Label string `json:"label"`
}

func rexSessions() ([]rexSession, error) {
	out, err := rex("ls", "--json")
	if err != nil {
		return nil, err
	}
	var ls struct {
		Sessions []rexSession `json:"sessions"`
	}
	return ls.Sessions, json.Unmarshal(out, &ls)
}

// ensureSession returns the ID of the session with this label,
// creating it (one plain shell window in cwd) if it doesn't exist.
func ensureSession(label, cwd string) (string, error) {
	sessions, err := rexSessions()
	if err != nil {
		return "", err
	}
	for _, s := range sessions {
		if s.Label == label {
			return s.ID, nil
		}
	}
	return newSession(label, "Terminal", shellBlock(cwd, ""))
}

// newSession creates a session with one window, returning its ID
func newSession(label, window string, layout map[string]any) (string, error) {
	var created struct {
		ID string `json:"session_id"`
	}
	err := rexCall("", "session.create", map[string]any{
		"label": label,
		"initial_windows": []any{map[string]any{
			"window_label": window,
			"layout":       layout,
		}},
	}, &created)
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

// selectSession shows a session (and window, if not "") in a client
func selectSession(client, session, window string) error {
	args := []string{"-C", client, "do", "session.select", "session_id=" + session}
	if window != "" {
		args = append(args, "window_id="+window)
	}
	_, err := rex(args...)
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
//
// fish only reports its directory to rex (OSC 7) when it draws a prompt,
// which waits for the command to exit. Until then rex knows no directory
// for the pane and opens splits and tabs from it in ~, so the command
// reports the directory first.
func shellBlock(cwd, run string) map[string]any {
	opts := map[string]any{"cwd": cwd}
	sh := shellBin()
	switch {
	case run != "" && isFish(sh):
		osc7 := `printf '\e]7;file://%s%s\a' $hostname (string escape --style=url -- $PWD); `
		opts["shell"] = "none"
		opts["command"] = []string{sh, "-l", "-C", osc7 + run}
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

// shellBin is the shell new panes run: RMX_SHELL, else fish from PATH.
// rex's own default is the macOS account shell (zsh).
func shellBin() string {
	if sh := os.Getenv("RMX_SHELL"); sh != "" {
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

type project struct {
	Src   string `json:"Src"`
	Name  string `json:"Name"`
	Path  string `json:"Path"`
	Icon  string `json:"Icon"`
	Label string `json:"-"`
}

// projects lists sesh's config and zoxide entries (tmux sessions don't
// exist under rex), each with the label of its rex session: the
// configured name, else the directory basename. The one place that
// naming lives.
func projects() ([]project, error) {
	out, err := exec.Command("sesh", "list", "--json", "-c", "-z", "-d").Output()
	if err != nil {
		return nil, fmt.Errorf("sesh list: %w", err)
	}
	var ps []project
	if err := json.Unmarshal(out, &ps); err != nil {
		return nil, err
	}
	for i, p := range ps {
		if p.Src == "config" {
			ps[i].Label = p.Name
		} else {
			ps[i].Label = filepath.Base(strings.TrimSuffix(p.Path, "/"))
		}
	}
	return ps, nil
}

// display is how pickers show a project
func (p project) display() string {
	icon := p.Icon
	if icon == "" {
		icon = "📁"
	}
	return icon + " " + p.Name
}
