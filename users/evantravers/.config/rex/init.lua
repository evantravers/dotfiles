local terminal = "com.superlogical.terminal"

-- Runs command in a focused floating layer over the active window, like
-- a tmux popup; the layer closes when the command exits. bounds is
-- {x, y, w, h} as fractions of the window.
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

-- wt (rex.nix) from the focused pane's directory: pick a project,
-- describe a task, launch an agent worktree.
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

rex.bind("cmd+shift+a", "agent")

-- zoxide directories in the command palette: one "Directories" action
-- per entry opens a session there (a fish shell), or switches to it if
-- it's open. Labels match wt sesh's (the basename). The list is read at
-- load, so new zoxide entries show up after `rex config reload`.
--
-- The rex server's PATH is only /usr/bin:/bin, so use full paths.
local bin = "/etc/profiles/per-user/" .. os.getenv("USER") .. "/bin/"
local home = os.getenv("HOME")

local function session_labeled(label)
  local list, err = rex.call("session.list")
  if err ~= nil then error(err, 0) end
  for _, session in ipairs(list.sessions) do
    if session.label == label then return session.session_id end
  end
end

local function open_dir(dir)
  rex.exec{ bin .. "zoxide", "add", dir }
  local label = dir:match("([^/]+)/*$") or dir
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

-- Only projects, ~/src/<host>/<user>/<project>, shown as <user>/<project>.
local src = home .. "/src/"
local zoxide = rex.exec{ bin .. "zoxide", "query", "--list" }
if zoxide and zoxide.ok then
  for dir in zoxide.stdout:gmatch("[^\n]+") do
    local project = dir:sub(1, #src) == src
      and dir:sub(#src + 1):match("^[^/]+/([^/]+/[^/]+)$")
    if project then
      rex.action{
        -- The palette runs an entry by name, so the name has to stay the
        -- same for a directory across reloads: hex-encode the path.
        name     = "dir_" .. dir:gsub(".", function(c) return ("%02x"):format(c:byte()) end),
        title    = project,
        category = "Directories",
        keywords = dir,
        run      = function() open_dir(dir) end,
      }
    end
  end
end

-- Vim-style hjkl mirrors of the default arrow bindings: cmd+alt focuses,
-- cmd+shift splits, cmd+alt+shift moves. (Not ctrl: ctrl+h is backspace
-- and alt alone trips readline word-motion in terminals.)
local directions = { h = "left", j = "down", k = "up", l = "right" }
for key, direction in pairs(directions) do
  rex.bind("cmd+alt+" .. key, "pane.focus." .. direction)
  rex.bind("cmd+shift+" .. key, "pane.split." .. direction)
  rex.bind("cmd+alt+shift+" .. key, "pane.move." .. direction)
end
