local terminal = "com.superlogical.terminal"

-- The rex server's PATH is only /usr/bin:/bin, so use full paths.
local bin = "/etc/profiles/per-user/" .. os.getenv("USER") .. "/bin/"

-- The focused pane's working directory, if rex can read it
local function cwd_of(block_id)
  local info = block_id and rex.block.call(terminal, "process", { block_id = block_id })
  return info and ((info.foreground and info.foreground.cwd) or (info.child and info.child.cwd))
end

-- ------------------------------------------------------------------ wt ---
-- wt (rex.nix) does the repo work; these actions ask the questions in the
-- command palette with rex.ui.
--
-- wt runs in a fish login shell: rex runs commands with its own bare
-- environment, which misses home.sessionVariables and the PATH that
-- finds fm (wt's branch naming) and the agent.
local function wt_argv(args)
  local argv = { bin .. "fish", "-l", "-c", "exec $argv", "wt" }
  for _, a in ipairs(args) do argv[#argv + 1] = a end
  return argv
end

-- Runs wt and decodes the JSON it prints, or returns nil and why not
local function wt_json(args)
  local r, err = rex.exec(wt_argv(args), { timeout = 10 })
  if not r then return nil, err end
  if not r.ok then return nil, (r.stderr:gsub("%s+$", "")) end
  return rex.json.decode(r.stdout)
end

-- Starts wt detached: it outlives the action, past the action's 30
-- second limit, and reports back with a notification
local function wt_start(args, opts)
  opts = opts or {}
  opts.detach, opts.stdout, opts.stderr = true, false, false
  local h, err = rex.exec.start(wt_argv(args), opts)
  if not h then error("wt: " .. err, 0) end
end

local function notify(msg)
  rex.exec.start(wt_argv{ "__notify", msg }, { detach = true, stdout = false, stderr = false })
end

-- answer passes a rex.ui result through. A prompt that ended without an
-- answer gives nil; anything but the person cancelling is reported.
local function answer(value, why)
  if value == nil and why ~= "cancelled" then
    notify("no answer from the prompt (" .. tostring(why) .. ")")
  end
  return value
end

-- New Agent: pick a project (the focused pane's first), describe a task,
-- and wt launches a worktree with an agent working on it in a new
-- session. With no task, asks for a worktree title instead.
rex.action{
  name     = "agent",
  title    = "New Agent…",
  keywords = "wt worktree workspace agent task",
  run      = function(ctx)
    local cwd = cwd_of(ctx.block_id)
    local here = cwd and wt_json{ "__info", cwd }
    local projects, err = wt_json{ "__projects" }

    local items = {}
    if here then
      items[1] = { id = here.root, title = "Current project: " .. here.name,
                   subtitle = here.root, icon = "star" }
    end
    for _, p in ipairs(projects or {}) do
      if #items >= 2000 then break end
      if not (here and p.path == here.root) then
        items[#items + 1] = { id = p.path, title = p.name, subtitle = p.path, icon = "folder" }
      end
    end
    if #items == 0 then
      notify("no projects: " .. tostring(err))
      return
    end

    local dir = answer(rex.ui.pick{
      title       = "Where should the agent work?",
      placeholder = "Filter projects",
      confirm     = "Choose project",
      items       = items,
    })
    if dir == nil then return end

    local prompt = answer(rex.ui.input{
      title       = "Task for the agent",
      placeholder = "Describe the task…  (empty for a plain worktree)",
      confirm     = "Start agent",
    })
    if prompt == nil then return end

    local title = ""
    if not prompt:match("%S") then
      title = answer(rex.ui.input{
        title       = "Worktree title",
        placeholder = "Fix login bug",
        confirm     = "Create worktree",
      })
      if title == nil or not title:match("%S") then return end
    end

    wt_start{ "__create", dir, title, prompt }
  end,
}

rex.bind("cmd+shift+a", "agent")

-- Remove Worktree: pick one of the focused project's worktrees (the one
-- the pane is in, first), confirm, and wt removes it and closes its
-- session.
rex.action{
  name     = "agent_remove",
  title    = "Remove Worktree…",
  keywords = "wt rm worktree workspace agent remove delete",
  run      = function(ctx)
    local cwd = cwd_of(ctx.block_id)
    if not cwd then
      notify("rm: can't read the focused pane's directory")
      return
    end
    local here, err = wt_json{ "__info", cwd }
    if not here then
      notify("rm: " .. tostring(err))
      return
    end
    if #here.worktrees == 0 then
      notify("rm: " .. here.name .. " has no worktrees")
      return
    end

    local items = {}
    for _, name in ipairs(here.worktrees) do
      local item = { id = name, title = name, icon = "branch" }
      if name == here.current then
        item.detail = "this pane"
        table.insert(items, 1, item)
      else
        items[#items + 1] = item
      end
    end
    local name = answer(rex.ui.pick{
      title       = "Remove which worktree of " .. here.name .. "?",
      placeholder = "Filter worktrees",
      confirm     = "Choose worktree",
      items       = items,
    })
    if name == nil then return end

    local sure = answer(rex.ui.pick{
      title = "Remove worktree '" .. name .. "' and close its rex session?",
      items = {
        { id = "yes", title = "Remove " .. name },
        { id = "no",  title = "Keep it" },
      },
    })
    if sure ~= "yes" then return end

    wt_start({ "rm", "-y", "--notify", name }, { cwd = here.root })
  end,
}

-- Open Project: open rex sessions, then wt's projects. Picking a
-- project with no session opens one (a fish shell in its directory).
local function session_labeled(label)
  local list, err = rex.call("session.list")
  if err ~= nil then error(err, 0) end
  for _, session in ipairs(list.sessions) do
    if session.label == label then return session.session_id end
  end
end

local function open_session(label, dir)
  local id = session_labeled(label)
  if not id then
    local created, err = rex.call("session.create", {
      label = label,
      initial_windows = {{
        window_label = "Terminal",
        layout = rex.layout.block{
          flavor  = terminal .. ".shell",
          options = { cwd = dir, shell = bin .. "fish" },
        },
      }},
    })
    if err ~= nil then error(err, 0) end
    id = created.session_id
  end
  rex.client.queue("session.select", { session_id = id })
end

rex.action{
  name     = "sesh",
  title    = "Open Project",
  keywords = "wt sesh session project switch",
  run      = function(ctx)
    local list, err = rex.call("session.list")
    if err ~= nil then error(err, 0) end
    local projects = wt_json{ "__projects" } or {}

    -- A project whose session is open is listed once, as the session
    local items, open = {}, {}
    for _, s in ipairs(list.sessions) do
      open[s.label] = true
      items[#items + 1] = { id = "session:" .. s.session_id, title = s.label, icon = "terminal",
                            detail = s.session_id == ctx.session_id and "current" or nil }
    end
    for _, p in ipairs(projects) do
      if #items >= 2000 then break end
      if not open[p.label] then
        items[#items + 1] = { id = "dir:" .. p.path, title = p.name, subtitle = p.path, icon = "folder" }
      end
    end

    local pick = answer(rex.ui.pick{
      title       = "Open Project",
      placeholder = "Filter sessions and projects",
      items       = items,
    })
    if pick == nil then return end

    local session = pick:match("^session:(.*)")
    if session then
      rex.client.queue("session.select", { session_id = session })
      return
    end
    local dir = pick:match("^dir:(.*)")
    for _, p in ipairs(projects) do
      if p.path == dir then return open_session(p.label, dir) end
    end
  end,
}
rex.bind("cmd+alt+p", "sesh")

-- Vim-style hjkl mirrors of the default arrow bindings: cmd+alt focuses,
-- cmd+shift splits, cmd+alt+shift moves. (Not ctrl: ctrl+h is backspace
-- and alt alone trips readline word-motion in terminals.)
local directions = { h = "left", j = "down", k = "up", l = "right" }
for key, direction in pairs(directions) do
  rex.bind("cmd+alt+" .. key, "pane.focus." .. direction)
  rex.bind("cmd+shift+" .. key, "pane.split." .. direction)
  rex.bind("cmd+alt+shift+" .. key, "pane.move." .. direction)
end
