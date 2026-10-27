package main

import (
	"image/color"
	"strings"
	"testing"
)

func TestResetsBackground(t *testing.T) {
	for params, want := range map[string]bool{
		"":            true,
		"0":           true,
		"49":          true,
		"1;0":         true,
		"38;5;0":      false, // colour index 0, not a reset
		"38;2;0;0;0":  false,
		"0;48;5;212":  false, // reset, then a background of its own
		"48;5;212;0":  true,
		"38:2::0:0:0": false,
		"1":           false,
	} {
		if got := resetsBackground(params); got != want {
			t.Errorf("resetsBackground(%q) = %v, want %v", params, got, want)
		}
	}
}

func TestPaintGivesEveryCellABackground(t *testing.T) {
	bg := color.RGBA{28, 25, 23, 255}
	set := "48;2;28;25;23"
	got := paint("a\x1b[mb\x1b[38;5;1mc\x1b[0m", bg)
	want := "\x1b[" + set + "ma\x1b[0;" + set + "mb\x1b[38;5;1mc\x1b[0;" + set + "m\x1b[0m"
	if got != want {
		t.Errorf("paint:\n got %q\nwant %q", got, want)
	}
}

func TestFill(t *testing.T) {
	got := fill("ab\nlonger line", 4, 3)
	want := "ab  \nlong\n    "
	if got != want {
		t.Errorf("fill = %q, want %q", got, want)
	}
}

func TestSlugify(t *testing.T) {
	for in, want := range map[string]string{
		"Fix login bug":        "fix-login-bug",
		"  --Hello, World!-- ": "hello-world",
		"émoji 🎉 ok":           "moji-ok",
	} {
		if got := slugify(in); got != want {
			t.Errorf("slugify(%q) = %q, want %q", in, got, want)
		}
	}
	if got := shorten(strings.Repeat("ab-", 20)); len(got) > 50 || strings.HasSuffix(got, "-") {
		t.Errorf("shorten = %q", got)
	}
}

func TestPaneQuoteFish(t *testing.T) {
	t.Setenv("WT_SHELL", "/bin/fish")
	for in, want := range map[string]string{
		"/plain/path": "/plain/path",
		"it's here":   `'it\'s here'`,
		`back\slash`:  `'back\\slash'`,
	} {
		if got := paneQuote(in); got != want {
			t.Errorf("paneQuote(%q) = %q, want %q", in, got, want)
		}
	}
}
