// wt — git worktrees / jj workspaces + agent, for the rex multiplexer.
//
// The prompts live in rex's init.lua, which asks with rex.ui.pick and
// rex.ui.input in the command palette and calls wt's internal
// subcommands for the repo work. wt itself has no interactive UI.
//
// Usage:
//
//	wt <prompt…>      launch a worktree in the current repo with an agent
//	                  working on prompt.
//	wt rm [-y] [name] remove a worktree/workspace and close its rex session.
//	                  Inside a worktree, name defaults to that one.
//
// Internal subcommands (init.lua and rex panes call these):
//
//	wt __create <dir> <title> <prompt>  provision a worktree of dir's
//	                  project and start its agent (rex starts it detached).
//	                  title names a prompt-less worktree.
//	wt __agent [--] <agent…>  run the agent in the devenv environment
//	                  (started by the agent's window)
//	wt __info <dir>   JSON about dir's project and its worktrees
//	wt __projects     JSON list of sesh's config and zoxide entries
//	wt __notify <msg> show msg as a notification
//
// Environment:
//
//	WT_SHELL  shell for new rex panes (default: fish from PATH)
//	WT_FOCUS  set to 1 to show the new session in the app
//	WT_SELF   path panes use to run wt (rex.nix sets it to the wrapper)
package main

import (
	"fmt"
	"os"
	"strings"
)

const usage = `Usage: wt <prompt…>
       wt rm [-y] [name]

Launch a worktree of the current repo with an agent working on prompt,
in a new rex session. To pick a project and describe the task in rex's
command palette, run the New Agent… action instead.

rm removes a worktree and closes its rex session. -y skips the
confirmation.
`

func main() {
	args := os.Args[1:]

	cmd := ""
	if len(args) > 0 {
		cmd = args[0]
	}
	switch cmd {
	case "", "-h", "--help":
		fmt.Print(usage)
		if cmd == "" {
			os.Exit(2)
		}
	case "rm":
		os.Exit(remove(args[1:]))
	case "__create":
		os.Exit(create(args[1:]))
	case "__agent":
		os.Exit(agent(args[1:]))
	case "__info":
		os.Exit(info(args[1:]))
	case "__projects":
		os.Exit(listProjects())
	case "__notify":
		notify(strings.Join(args[1:], " "))
	default:
		// An unknown internal subcommand must not become an agent's task
		if strings.HasPrefix(cmd, "__") {
			fmt.Fprintf(os.Stderr, "wt: unknown subcommand %s\n", cmd)
			os.Exit(2)
		}
		os.Exit(launch(strings.Join(args, " ")))
	}
}
