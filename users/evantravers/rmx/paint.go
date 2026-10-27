package main

import (
	"fmt"
	"image/color"
	"strings"

	"charm.land/lipgloss/v2"
	"github.com/charmbracelet/x/ansi"
)

// Rex draws a floating layer with no background of its own, so any cell
// left at the terminal's default background shows the panes underneath.
// fill and paint make every cell of the screen opaque.

// fill pads (or cuts) content to exactly w×h cells, so every cell
// exists for paint to colour.
func fill(content string, w, h int) string {
	lines := strings.Split(content, "\n")
	if len(lines) > h {
		lines = lines[:h]
	}
	for len(lines) < h {
		lines = append(lines, "")
	}
	for i, line := range lines {
		if n := lipgloss.Width(line); n > w {
			lines[i] = ansi.Truncate(line, w, "")
		} else {
			lines[i] = line + strings.Repeat(" ", w-n)
		}
	}
	return strings.Join(lines, "\n")
}

// paint starts each line with bg and puts bg back after every SGR
// sequence that resets the background, so styled spans keep their own
// backgrounds and everything else gets bg.
func paint(content string, bg color.Color) string {
	r, g, b, _ := bg.RGBA()
	set := fmt.Sprintf("48;2;%d;%d;%d", r>>8, g>>8, b>>8)
	lines := strings.Split(content, "\n")
	for i, line := range lines {
		lines[i] = "\x1b[" + set + "m" + repaint(line, set) + "\x1b[0m"
	}
	return strings.Join(lines, "\n")
}

// repaint rewrites one line's SGR sequences so a background reset
// becomes a switch to set.
func repaint(line, set string) string {
	var out strings.Builder
	for {
		start := strings.Index(line, "\x1b[")
		if start < 0 {
			out.WriteString(line)
			return out.String()
		}
		end := start + 2
		for end < len(line) && strings.IndexByte("0123456789;:", line[end]) >= 0 {
			end++
		}
		out.WriteString(line[:start])
		if end < len(line) && line[end] == 'm' {
			params := line[start+2 : end]
			if resetsBackground(params) {
				if params == "" {
					// A bare ESC[m is a full reset; keep it one
					params = "0"
				}
				params += ";" + set
			}
			out.WriteString("\x1b[" + params + "m")
			line = line[end+1:]
			continue
		}
		// Not an SGR: copy the introducer and carry on after it
		out.WriteString(line[start:end])
		line = line[end:]
	}
}

// resetsBackground reports whether an SGR parameter list leaves the
// background at the terminal default.
func resetsBackground(params string) bool {
	if params == "" {
		return true
	}
	fields := strings.Split(params, ";")
	reset := false
	for i := 0; i < len(fields); i++ {
		f := fields[i]
		code, _, colon := strings.Cut(f, ":")
		switch code {
		case "", "0", "49":
			reset = true
		case "48":
			reset = false
		}
		// 38/48/58;5;n and ;2;r;g;b carry their colour in the next
		// fields, which aren't codes of their own
		if (code == "38" || code == "48" || code == "58") && !colon && i+1 < len(fields) {
			switch fields[i+1] {
			case "5":
				i += 2
			case "2":
				i += 4
			}
		}
	}
	return reset
}
