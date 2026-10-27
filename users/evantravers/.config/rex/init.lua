local terminal = "com.superlogical.terminal"

-- Runs command in a focused floating layer over the active window, like
-- a tmux popup; the layer closes when the command exits. Rex draws
-- floating layers with no background, so wt and wt sesh paint every
-- cell themselves (wt/paint.go). bounds is {x, y, w, h} as fractions
-- of the window.
local function float(ctx, label, command, bounds, cwd)
  local view = rex.call("session.view", { session_id = ctx.session_id })
  local _, err = rex.call("session.new_layer", {
    session_id = ctx.session_id,
    window_id  = view and view.active_window_id,
    bounds     = bounds,
    focus      = true,
    layout     = rex.layout.block{
      flavor  = terminal .. ".shell",
      label   = label,
      options = { command = command, cwd = cwd, exit = { on_completion = true } },
    },
  })
  if err ~= nil then error(err, 0) end
end

-- The focused pane's working directory, if rex can read it
local function cwd_of(block_id)
  local info = block_id and rex.block.call(terminal, "process", { block_id = block_id })
  return info and ((info.foreground and info.foreground.cwd) or (info.child and info.child.cwd))
end

-- sesh picker, like the tmux C-p popup. wt sesh (rex.nix) does the
-- picking and switches this client's session.
rex.action{
  name  = "sesh",
  title = "Pick a Sesh…",
  keywords = "session repository project zoxide",
  run   = function(ctx, args)
    float(ctx, "wt sesh", { "wt", "sesh", ctx.client_id }, { 0.1, 0.1, 0.8, 0.8 })
  end,
}

-- wt (rex.nix) from the focused pane's directory, like wmx's tmux
-- popup: pick a project, describe a task, launch an agent worktree.
--
-- It runs in a fish login shell: rex runs commands through the account
-- shell (zsh), which home-manager doesn't manage, so it misses
-- home.sessionVariables (pi's PI_CODING_AGENT_DIR, without which wt's
-- `pi -p` branch naming finds no API key).
rex.action{
  name  = "agent",
  title = "New Agent…",
  keywords = "wt worktree workspace agent task",
  run   = function(ctx, args)
    float(ctx, "wt", { "fish", "-l", "-c", "exec $argv", "wt" }, { 0.2, 0.2, 0.6, 0.6 }, cwd_of(ctx.block_id))
  end,
}

rex.bind("cmd+p", "sesh")
rex.bind("cmd+shift+a", "agent")

-- Vim-style hjkl mirrors of the default arrow bindings: cmd+alt focuses,
-- cmd+shift splits, cmd+alt+shift moves. (Not ctrl: ctrl+h is backspace
-- and alt alone trips readline word-motion in terminals.)
local directions = { h = "left", j = "down", k = "up", l = "right" }
for key, direction in pairs(directions) do
  rex.bind("cmd+alt+" .. key, "pane.focus." .. direction)
  rex.bind("cmd+shift+" .. key, "pane.split." .. direction)
  rex.bind("cmd+alt+shift+" .. key, "pane.move." .. direction)
end
