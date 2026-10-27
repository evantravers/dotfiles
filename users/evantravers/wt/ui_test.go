package main

import (
	"strings"
	"testing"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
)

const longText = "I kinda want to bind some vim style hjkl bindings for focusing windows in rex so I can move around without the mouse"

// Rex can cut off a float's right side, so every prompt, margin
// included, must keep within maxWidth however wide the screen
func TestContentKeepsToMaxWidth(t *testing.T) {
	steps := map[string]step{
		"write":  newWrite("Task for the agent", "Describe the task…", 8),
		"input":  &inputStep{in: newInput("Worktree title")},
		"filter": newFilter("Pick", "Search…", []string{strings.Repeat("x", 150)}),
	}
	for name, s := range steps {
		r := &root{results: make(chan bool, 1)}
		r.Update(tea.WindowSizeMsg{Width: 200, Height: 40})
		r.Update(showMsg{s})
		r.Update(tea.PasteMsg{Content: longText})
		if w := lipgloss.Width(r.content()); w > maxWidth {
			t.Errorf("%s: view is %d cells, over %d", name, w, maxWidth)
		}
	}
}
