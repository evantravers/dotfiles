local terminal = "com.superlogical.terminal"

-- Runs command in a focused floating layer over the active window, like
-- a tmux popup; the layer closes when the command exits. Rex draws
-- floating layers with no background, so rmx and rsesh paint every
-- cell themselves (rmx/paint.go). bounds is {x, y, w, h} as fractions
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

-- sesh picker, like the tmux C-p popup. rsesh (rex.nix) does the
-- picking and switches this client's session.
rex.action{
  name  = "sesh",
  title = "Pick a Sesh…",
  keywords = "session repository project zoxide",
  run   = function(ctx, args)
    float(ctx, "rsesh", { "rsesh", ctx.client_id }, { 0.1, 0.1, 0.8, 0.8 })
  end,
}

-- rmx (rex.nix) from the focused pane's directory, like wmx's tmux
-- popup: pick a project, describe a task, launch an agent worktree.
rex.action{
  name  = "agent",
  title = "New Agent…",
  keywords = "rmx worktree workspace agent task",
  run   = function(ctx, args)
    float(ctx, "rmx", { "rmx" }, { 0.2, 0.2, 0.6, 0.6 }, cwd_of(ctx.block_id))
  end,
}

rex.bind("cmd+p", "sesh")
rex.bind("cmd+shift+a", "agent")
