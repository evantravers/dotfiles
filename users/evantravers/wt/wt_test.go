package main

import (
	"strings"
	"testing"
)

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
