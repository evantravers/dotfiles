package main

import (
	"image/color"
	"strings"

	"charm.land/bubbles/v2/textarea"
	"charm.land/bubbles/v2/textinput"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/sahilm/fuzzy"
)

// The UI is one full-screen Bubble Tea program for a whole run, so a
// series of prompts shares one opaque screen (see paint.go). Each
// prompt is a step: the caller hands it to the program and blocks
// until the user submits it or backs out with esc or ctrl+c.

// Colours from gum's defaults, as ANSI indexes so they follow the theme
var (
	headerStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("99")).Bold(true)
	accentStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("212"))
	faintStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("240"))
	errorStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("1"))
)

// Until the terminal reports its background, paint with a dark grey
var fallbackBg color.Color = color.RGBA{24, 24, 24, 255}

type step interface {
	init() tea.Cmd
	resize(w, h int)
	// update reports done when the step has its result
	update(msg tea.Msg) (cmd tea.Cmd, done bool)
	view() string
}

type ui struct {
	prog    *tea.Program
	results chan bool
	exited  chan struct{}
}

type showMsg struct{ s step }

func startUI() *ui {
	u := &ui{results: make(chan bool, 1), exited: make(chan struct{})}
	u.prog = tea.NewProgram(&root{results: u.results})
	go func() {
		defer close(u.exited)
		_, _ = u.prog.Run()
	}()
	return u
}

// run shows s and reports whether the user submitted it
func (u *ui) run(s step) bool {
	u.prog.Send(showMsg{s})
	select {
	case ok := <-u.results:
		return ok
	case <-u.exited:
		return false
	}
}

func (u *ui) close() {
	u.prog.Quit()
	<-u.exited
}

// filter fuzzy-filters items and returns the index of the pick
func (u *ui) filter(header, placeholder string, items []string) (int, bool) {
	s := newFilter(header, placeholder, items)
	if !u.run(s) {
		return 0, false
	}
	return s.pick, true
}

func (u *ui) choose(header string, options []string) (int, bool) {
	s := &chooseStep{header: header, options: options}
	if !u.run(s) {
		return 0, false
	}
	return s.cursor, true
}

// write takes multi-line text; ctrl+d submits
func (u *ui) write(header, placeholder string, height int) (string, bool) {
	s := newWrite(header, placeholder, height)
	if !u.run(s) {
		return "", false
	}
	return strings.TrimSpace(s.area.Value()), true
}

func (u *ui) input(placeholder string) (string, bool) {
	s := &inputStep{in: newInput(placeholder)}
	if !u.run(s) {
		return "", false
	}
	return strings.TrimSpace(s.in.Value()), true
}

func (u *ui) confirm(prompt string) bool {
	s := &confirmStep{prompt: prompt, yes: true}
	return u.run(s) && s.yes
}

// message shows an error until a key is pressed
func (u *ui) message(text string) {
	u.run(&messageStep{text: text})
}

// ------------------------------------------------------------------ root ---

type root struct {
	s       step
	results chan bool
	w, h    int
	bg      color.Color
}

func (r *root) Init() tea.Cmd { return tea.RequestBackgroundColor }

func (r *root) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		r.w, r.h = msg.Width, msg.Height
		if r.s != nil {
			r.s.resize(r.inner())
		}
		return r, nil
	case tea.BackgroundColorMsg:
		r.bg = msg.Color
		return r, nil
	case showMsg:
		r.s = msg.s
		r.s.resize(r.inner())
		return r, r.s.init()
	case tea.KeyPressMsg:
		if r.s == nil {
			return r, nil
		}
		if k := msg.String(); k == "esc" || k == "ctrl+c" {
			r.finish(false)
			return r, nil
		}
	}
	if r.s == nil {
		return r, nil
	}
	cmd, done := r.s.update(msg)
	if done {
		r.finish(true)
	}
	return r, cmd
}

func (r *root) finish(ok bool) {
	r.s = nil
	r.results <- ok
}

// Rex can draw a floating layer narrower than the terminal inside it,
// cutting off the right side, so the margin and step together keep to
// this many columns
const maxWidth = 80

// inner is the size inside the margin View draws
func (r *root) inner() (int, int) {
	return max(min(r.w, maxWidth)-4, 1), max(r.h-2, 1)
}

// content is the step's view inside its margin, cut to the inner width
func (r *root) content() string {
	if r.s == nil {
		return ""
	}
	w, _ := r.inner()
	return lipgloss.NewStyle().Padding(1, 2).MaxWidth(w + 4).Render(r.s.view())
}

func (r *root) View() tea.View {
	content := r.content()
	bg := r.bg
	if bg == nil {
		bg = fallbackBg
	}
	v := tea.NewView(paint(fill(content, r.w, r.h), bg))
	v.AltScreen = true
	return v
}

// ---------------------------------------------------------------- filter ---

type filterStep struct {
	header  string
	items   []string
	in      textinput.Model
	matches fuzzy.Matches
	cursor  int
	offset  int
	rows    int
	pick    int
}

func newInput(placeholder string) textinput.Model {
	in := textinput.New()
	in.Placeholder = placeholder
	in.Prompt = "> "
	st := in.Styles()
	st.Focused.Prompt = accentStyle
	st.Focused.Placeholder = faintStyle
	in.SetStyles(st)
	return in
}

func newFilter(header, placeholder string, items []string) *filterStep {
	s := &filterStep{header: header, items: items, in: newInput(placeholder)}
	s.refilter()
	return s
}

func (s *filterStep) init() tea.Cmd { return s.in.Focus() }

func (s *filterStep) resize(w, h int) {
	s.in.SetWidth(w - 2)
	s.rows = max(h-2, 1)
	if s.header != "" {
		s.rows = max(h-3, 1)
	}
}

func (s *filterStep) refilter() {
	if q := s.in.Value(); q != "" {
		s.matches = fuzzy.Find(q, s.items)
	} else {
		s.matches = make(fuzzy.Matches, len(s.items))
		for i, item := range s.items {
			s.matches[i] = fuzzy.Match{Str: item, Index: i}
		}
	}
	s.cursor, s.offset = 0, 0
}

func (s *filterStep) update(msg tea.Msg) (tea.Cmd, bool) {
	if k, ok := msg.(tea.KeyPressMsg); ok {
		switch k.String() {
		case "enter":
			if len(s.matches) == 0 {
				return nil, false
			}
			s.pick = s.matches[s.cursor].Index
			return nil, true
		case "up", "ctrl+p", "ctrl+k":
			s.move(-1)
			return nil, false
		case "down", "ctrl+n", "ctrl+j":
			s.move(1)
			return nil, false
		}
	}
	before := s.in.Value()
	var cmd tea.Cmd
	s.in, cmd = s.in.Update(msg)
	if s.in.Value() != before {
		s.refilter()
	}
	return cmd, false
}

func (s *filterStep) move(d int) {
	s.cursor = min(max(s.cursor+d, 0), max(len(s.matches)-1, 0))
	if s.cursor < s.offset {
		s.offset = s.cursor
	} else if s.cursor >= s.offset+s.rows {
		s.offset = s.cursor - s.rows + 1
	}
}

func (s *filterStep) view() string {
	var b strings.Builder
	if s.header != "" {
		b.WriteString(headerStyle.Render(s.header) + "\n")
	}
	b.WriteString(s.in.View() + "\n")
	end := min(s.offset+s.rows, len(s.matches))
	for i := s.offset; i < end; i++ {
		m := s.matches[i]
		if i == s.cursor {
			b.WriteString(accentStyle.Render("• "))
		} else {
			b.WriteString("  ")
		}
		b.WriteString(highlight(m.Str, m.MatchedIndexes) + "\n")
	}
	return b.String()
}

// highlight colours the matched bytes of str
func highlight(str string, matched []int) string {
	if len(matched) == 0 {
		return str
	}
	hit := make(map[int]bool, len(matched))
	for _, i := range matched {
		hit[i] = true
	}
	var b strings.Builder
	for i, r := range str {
		if hit[i] {
			b.WriteString(accentStyle.Render(string(r)))
		} else {
			b.WriteRune(r)
		}
	}
	return b.String()
}

// ---------------------------------------------------------------- choose ---

type chooseStep struct {
	header  string
	options []string
	cursor  int
}

func (s *chooseStep) init() tea.Cmd   { return nil }
func (s *chooseStep) resize(w, h int) {}

func (s *chooseStep) update(msg tea.Msg) (tea.Cmd, bool) {
	k, ok := msg.(tea.KeyPressMsg)
	if !ok {
		return nil, false
	}
	switch k.String() {
	case "enter":
		return nil, true
	case "up", "k", "ctrl+p":
		s.cursor = max(s.cursor-1, 0)
	case "down", "j", "ctrl+n":
		s.cursor = min(s.cursor+1, len(s.options)-1)
	}
	return nil, false
}

func (s *chooseStep) view() string {
	var b strings.Builder
	b.WriteString(headerStyle.Render(s.header) + "\n")
	for i, o := range s.options {
		if i == s.cursor {
			b.WriteString(accentStyle.Render("> "+o) + "\n")
		} else {
			b.WriteString("  " + o + "\n")
		}
	}
	return b.String()
}

// ----------------------------------------------------------------- write ---

type writeStep struct {
	header string
	area   textarea.Model
}

func newWrite(header, placeholder string, height int) *writeStep {
	a := textarea.New()
	a.Placeholder = placeholder
	a.ShowLineNumbers = false
	a.CharLimit = 0
	a.SetHeight(height)
	st := a.Styles()
	st.Focused.CursorLine = lipgloss.NewStyle()
	st.Focused.Placeholder = faintStyle
	st.Focused.Prompt = accentStyle
	a.SetStyles(st)
	return &writeStep{header: header, area: a}
}

func (s *writeStep) init() tea.Cmd   { return s.area.Focus() }
func (s *writeStep) resize(w, h int) { s.area.SetWidth(w) }

func (s *writeStep) update(msg tea.Msg) (tea.Cmd, bool) {
	if k, ok := msg.(tea.KeyPressMsg); ok && k.String() == "ctrl+d" {
		return nil, true
	}
	var cmd tea.Cmd
	s.area, cmd = s.area.Update(msg)
	return cmd, false
}

func (s *writeStep) view() string {
	return headerStyle.Render(s.header) + "\n" + s.area.View() + "\n" +
		faintStyle.Render("ctrl+d submit • esc cancel")
}

// ----------------------------------------------------------------- input ---

type inputStep struct{ in textinput.Model }

func (s *inputStep) init() tea.Cmd   { return s.in.Focus() }
func (s *inputStep) resize(w, h int) { s.in.SetWidth(w - 2) }

func (s *inputStep) update(msg tea.Msg) (tea.Cmd, bool) {
	if k, ok := msg.(tea.KeyPressMsg); ok && k.String() == "enter" {
		return nil, true
	}
	var cmd tea.Cmd
	s.in, cmd = s.in.Update(msg)
	return cmd, false
}

func (s *inputStep) view() string { return s.in.View() }

// --------------------------------------------------------------- confirm ---

type confirmStep struct {
	prompt string
	yes    bool
}

func (s *confirmStep) init() tea.Cmd   { return nil }
func (s *confirmStep) resize(w, h int) {}

func (s *confirmStep) update(msg tea.Msg) (tea.Cmd, bool) {
	k, ok := msg.(tea.KeyPressMsg)
	if !ok {
		return nil, false
	}
	switch k.String() {
	case "enter":
		return nil, true
	case "y", "Y":
		s.yes = true
		return nil, true
	case "n", "N":
		s.yes = false
		return nil, true
	case "left", "right", "tab", "h", "l":
		s.yes = !s.yes
	}
	return nil, false
}

func (s *confirmStep) view() string {
	button := func(label string, on bool) string {
		st := lipgloss.NewStyle().Padding(0, 2)
		if on {
			st = st.Background(lipgloss.Color("212")).Foreground(lipgloss.Color("0"))
		}
		return st.Render(label)
	}
	return s.prompt + "\n\n" + button("Yes", s.yes) + "  " + button("No", !s.yes)
}

// --------------------------------------------------------------- message ---

type messageStep struct{ text string }

func (s *messageStep) init() tea.Cmd   { return nil }
func (s *messageStep) resize(w, h int) {}

func (s *messageStep) update(msg tea.Msg) (tea.Cmd, bool) {
	_, ok := msg.(tea.KeyPressMsg)
	return nil, ok
}

func (s *messageStep) view() string {
	return errorStyle.Render(s.text) + "\n\n" + faintStyle.Render("Press any key to close")
}
