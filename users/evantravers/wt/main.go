// wt — git worktrees / jj workspaces + agent, for the rex multiplexer,
// and wt sesh, a sesh picker that switches rex sessions.
//
// Both draw full-screen and paint every cell (paint.go), so they work in
// rex's floating layers, which have no background of their own.
//
// Usage:
//
//	wt [prompt…]      pick a project, describe a task, launch a worktree
//	                  with an agent working on it. With a prompt argument,
//	                  skips the pickers and uses the current repo.
//	wt rm [-y] [name] remove a worktree/workspace and close its rex session.
//	                  Inside a worktree, removes that one; otherwise picks
//	                  from the current repo's worktrees.
//	wt sesh [CLIENT]  pick a rex session, sesh config or zoxide entry and
//	                  switch CLIENT (default: the first connected app) to
//	                  it, creating the session if needed.
//
// Internal subcommands:
//
//	wt __create <path> <jj|git> <prompt_file> <title>     (spawned detached)
//	wt __agent [--main DIR] [--prompt FILE] [--] <agent…>  (started by the
//	                  agent's window: runs the agent in the devenv environment)
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

const usage = `Usage: wt [prompt…]
       wt rm [-y] [name]
       wt sesh [CLIENT]

Pick a project, describe a task, and launch a worktree with an agent
working on it in a new rex session. With a prompt argument, skips the
pickers and uses the current repo.

rm removes a worktree and closes its rex session. -y skips the
confirmation.

sesh picks a rex session, sesh config entry or zoxide directory and
switches the rex app to it. Switching needs Remote Control on in Rex's
Settings under Rex Server.
`

func main() {
	// The login shell rex runs commands through resets PATH (nix-darwin),
	// dropping the rex CLI that rex put at its front
	if dir := os.Getenv("REX_BIN_DIR"); dir != "" {
		os.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	}

	args := os.Args[1:]

	cmd := ""
	if len(args) > 0 {
		cmd = args[0]
	}
	switch cmd {
	case "-h", "--help":
		fmt.Print(usage)
	case "sesh":
		if len(args) > 1 && (args[1] == "-h" || args[1] == "--help") {
			fmt.Print(usage)
			return
		}
		os.Exit(sesh(args[1:]))
	case "rm":
		os.Exit(remove(args[1:]))
	case "__create":
		os.Exit(create(args[1:]))
	case "__agent":
		os.Exit(agent(args[1:]))
	default:
		// An unknown internal subcommand must not become an agent's task
		if strings.HasPrefix(cmd, "__") {
			fmt.Fprintf(os.Stderr, "wt: unknown subcommand %s\n", cmd)
			os.Exit(2)
		}
		os.Exit(launch(strings.Join(args, " ")))
	}
}
