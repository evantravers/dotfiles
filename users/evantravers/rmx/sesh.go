package main

import "fmt"

// sesh is `rsesh [CLIENT]`: list rex sessions, then sesh's config and
// zoxide entries; picking one switches CLIENT to that session, creating
// it (a shell in the entry's directory) when it doesn't exist.
//
// CLIENT is the rex client to switch (init.lua's sesh action passes the
// one that pressed the key); it defaults to the first connected app.
func sesh(args []string) int {
	// The UI comes up first, so a floating layer is painted while the
	// lists load
	u := startUI()
	defer u.close()
	if err := pickSesh(u, args); err != nil {
		u.message("rsesh: " + err.Error())
		return 1
	}
	return 0
}

// seshEntry is one line of the picker
type seshEntry struct {
	display string
	label   string // the rex session's label
	id      string // the rex session, when it's open
	path    string // where a new session starts
}

func pickSesh(u *ui, args []string) error {
	client := ""
	if len(args) > 0 {
		client = args[0]
	}
	if client == "" {
		if client = firstAppClient(); client == "" {
			return fmt.Errorf("no rex app is connected")
		}
	}

	entries, err := seshEntries()
	if err != nil {
		return err
	}
	items := make([]string, len(entries))
	for i, e := range entries {
		items[i] = e.display
	}
	i, ok := u.filter("📂 Repositories", "Pick a sesh", items)
	if !ok {
		return nil
	}

	e := entries[i]
	if e.id == "" {
		if e.id, err = ensureSession(e.label, e.path); err != nil {
			return fmt.Errorf("couldn't create session %s: %w", e.label, err)
		}
	}
	return selectSession(client, e.id, "")
}

// seshEntries lists open rex sessions, then projects. A project whose
// session is already open is listed only once, as the rex session.
func seshEntries() ([]seshEntry, error) {
	sessions, err := rexSessions()
	if err != nil {
		return nil, err
	}
	ps, err := projects()
	if err != nil {
		return nil, err
	}

	var entries []seshEntry
	open := map[string]bool{}
	for _, s := range sessions {
		open[s.Label] = true
		entries = append(entries, seshEntry{display: "🟢 " + s.Label, label: s.Label, id: s.ID})
	}
	seen := map[string]bool{}
	for _, p := range ps {
		if open[p.Label] || seen[p.Path] {
			continue
		}
		seen[p.Path] = true
		entries = append(entries, seshEntry{display: p.display(), label: p.Label, path: p.Path})
	}
	if len(entries) == 0 {
		return nil, fmt.Errorf("nothing to pick from")
	}
	return entries, nil
}
