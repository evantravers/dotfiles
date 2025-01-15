hs.loadSpoon('Hyper')
hs.loadSpoon('Headspace'):start()

-- bundleID, global, local
Bindings = {
  {'com.agiletortoise.Drafts-OSX', 'd', {'x', 'n'}},
  {'com.apple.MobileSMS', 'q', nil},
  {'com.apple.finder', 'f', nil},
  {'com.apple.mail', 'e', nil},
  {'com.flexibits.cardhop.mac', nil, {'u'}},
  {'com.flexibits.fantastical2.mac', 'y', {'/'}},
  {'com.mitchellh.ghostty', 'j', {'return'}},
  {'com.goodsnoze.MacWhisper', nil, {'a'}},
  {'com.toggl.daneel', 'r', nil},
  {'com.raycast.macos', nil, {'c', 'space'}},
  {'com.superultra.Homerow', nil, {'l'}},
  {'com.surteesstudios.Bartender', nil, {'b'}},
  {'md.obsidian', 'g', nil},
}

Hyper = spoon.Hyper

Hyper:bindHotKeys({hyperKey = {{}, 'F19'}})

hs.fnutils.each(Bindings, function(bindingTable)
  local bundleID, globalBind, localBinds = table.unpack(bindingTable)
  if globalBind then
    Hyper:bind({}, globalBind, function() hs.application.launchOrFocusByBundleID(bundleID) end)
  end
  if localBinds then
    hs.fnutils.each(localBinds, function(key)
      Hyper:bindPassThrough(key, bundleID)
    end)
  end
end)

Hyper:bind({}, '.', function()
  Hyper:exit()
  hs.shortcuts.run("Capture")
end)
Hyper:bind({}, ',', function()
  Hyper:exit()
  hs.shortcuts.run("Smart Capture")
end)
Hyper:bind({}, 't', function()
  hs.urlevent.openURL("obsidian://open?vault=wiki&file=templates%2Ftasks%2FToday")
  Hyper:exit()
end)

-- provide the ability to override config per computer
if (hs.fs.displayName('./localConfig.lua')) then
  require('localConfig')
end

-- https://github.com/dmitriiminaev/Hammerspoon-HyperModal/blob/master/.hammerspoon/yabai.lua
local yabai = function(args, completion)
  local yabai_output = ""
  local yabai_error  = ""
  -- Runs in background very fast
  local yabai_task = hs.task.new("/run/current-system/sw/bin/yabai", function(err, stdout, stderr)
    print()
  end, function(task, stdout, stderr)
      -- print("stdout:"..stdout, "stderr:"..stderr)
      if stdout ~= nil then
        yabai_output = yabai_output .. stdout
      end
      if stderr ~= nil then
        yabai_error = yabai_error .. stderr
      end
      return true
    end, args)
  if type(completion) == "function" then
    yabai_task:setCallback(function()
      completion(yabai_output, yabai_error/run/current-system/sw/bin/yabai)
    end)
  end
  yabai_task:start()
end

-- window bindings via yabai above
-- we are using jankyborders to highlight which is focused
local Yabai =
  hs.hotkey.modal.new({}, nil)

  function Yabai:entered()
    Yabai.enabled = true
    local f = hs.window.focusedWindow():screen():frame()
    Yabai.indicator = hs.canvas.new(f):appendElements({
      type = "rectangle",
      action="stroke",
      strokeWidth=4.0,
      strokeColor= {hex = "#F74F9E", alpha=0.7},
      roundedRectRadii = {xRadius=14.0, yRadius=14.0},
      frame = f
    }):show()

  end
  function Yabai:exited()
    Yabai.enabled = false
    Yabai.indicator:delete()
  end

  Yabai
  :bind({"control"}, "c", function()
    Yabai:exit()
  end)
  :bind({}, "escape", function()
    Yabai:exit()
  end)
  :bind({}, "h", function()
    yabai({"-m", "window", "--focus", "west"})
  end)
  :bind({}, "j", function()
    yabai({"-m", "window", "--focus", "south"})
  end)
  :bind({}, "k", function()
    yabai({"-m", "window", "--focus", "north"})
  end)
  :bind({}, "l", function()
    yabai({"-m", "window", "--focus", "east"})
  end)
  :bind({"shift"}, "h", function()
    yabai({"-m", "window", "--swap", "west"})
  end)
  :bind({"shift"}, "j", function()
    yabai({"-m", "window", "--swap", "south"})
  end)
  :bind({"shift"}, "k", function()
    yabai({"-m", "window", "--swap", "north"})
  end)
  :bind({"shift"}, "l", function()
    yabai({"-m", "window", "--swap", "east"})
  end)
  :bind({"control"}, "h", function()
    yabai({"-m", "window", "--warp", "west"})
  end)
  :bind({"control"}, "j", function()
    yabai({"-m", "window", "--warp", "south"})
  end)
  :bind({"control"}, "k", function()
    yabai({"-m", "window", "--warp", "north"})
  end)
  :bind({"control"}, "l", function()
    yabai({"-m", "window", "--warp", "east"})
  end)
  :bind({}, "x", function()
    yabai({"-m", "window", "--toggle", "split"})
  end)
  :bind({}, "z", function()
    yabai({"-m", "window", "--toggle", "zoom-parent"})
  end)
  :bind({}, "f", function()
    yabai({"-m", "window", "--toggle", "float"})
  end)
  :bind({}, "u", function()
    yabai({"-m", "window", "--ratio", "abs:0.3"})
  end)
  :bind({}, "i", function()
    yabai({"-m", "window", "--ratio", "abs:0.5"})
  end)
  :bind({}, "o", function()
    yabai({"-m", "window", "--ratio", "abs:0.7"})
  end)
  :bind({}, "p", function()
    yabai({"-m", "window", "--ratio", "abs:0.8"})
  end)
  :bind({}, "space", function()
    if Hyper.layout and Hyper.layout == "bsp" then
      Hyper.layout = "stack"
      yabai({"-m", "space", "--layout", "stack"})
    else
      Hyper.layout = "bsp"
      yabai({"-m", "space", "--layout", "bsp"})
    end
  end)
  :bind({}, "tab", function()
    yabai({"-m", "window", "--display", "recent", "--focus"})
  end)

Hyper:bind({}, "m", function()
  if Yabai.enabled then
    Yabai:exit()
  else
    Yabai:enter()
  end
end)

local brave = require('brave')

-- Random bindings
local chooseFromGroup = function(choice)
  local name = hs.application.nameForBundleID(choice.bundleID)

  hs.notify.new(nil)
  :title("Switching ✦-" .. choice.key .. " to " .. name)
  :contentImage(hs.image.imageFromAppBundle(choice.bundleID))
  :send()

  hs.settings.set("hyperGroup." .. choice.key, choice.bundleID)
  hs.application.launchOrFocusByBundleID(choice.bundleID)
end

local hyperGroup = function(key, group)
  Hyper:bind({}, key, nil, function()
    hs.application.launchOrFocusByBundleID(hs.settings.get("hyperGroup." .. key))
  end)
  Hyper:bind({'option'}, key, nil, function()
    print("Setting options…")
    local choices = {}
    hs.fnutils.each(group, function(bundleID)
      table.insert(choices, {
        text = hs.application.nameForBundleID(bundleID),
        image = hs.image.imageFromAppBundle(bundleID),
        bundleID = bundleID,
        key = key
      })
    end)

    if #choices == 1 then
      chooseFromGroup(choices[1])
    else
      hs.chooser.new(chooseFromGroup)
      :placeholderText("Choose an application for hyper+" .. key .. ":")
      :choices(choices)
      :show()
    end
  end)
end

hyperGroup('k', {
    'com.apple.Safari',
    'com.brave.Browser',
    'com.google.Chrome',
    'org.mozilla.firefox',
    'company.thebrowser.Browser',
    'org.mozilla.com.zen.browser'
  })

hyperGroup('i', {
    'com.microsoft.teams2'
  })

-- Jump to google hangout or zoom
Z_count = 0
Hyper:bind({}, 'z', nil, function()
  -- start a timer
  -- if not pressed again then
  if hs.application.find('us.zoom.xos') then
    hs.application.launchOrFocusByBundleID('us.zoom.xos')
  elseif hs.application.find('com.microsoft.teams2') then
    hs.application.launchOrFocusByBundleID('com.microsoft.teams2')
    local call = hs.settings.get("call")
    call:focus()
  else
    brave.jump("meet.google.com|hangouts.google.com.call")
  end
end)

-- Jump to figma
local designApps = {
  'com.figma.Desktop',
  'com.electron.realtimeboard',
  'com.adobe.LightroomClassicCC7'
}
Hyper:bind({}, 'v', nil, function()
  local appFound = hs.fnutils.find(designApps, function(bundleID)
    return hs.application.find(bundleID)
  end)

  if appFound then
    hs.application.launchOrFocusByBundleID(appFound)
  else
    brave.jump("lucidchart.com|figma.com")
  end
end)

jumpOrOpen = function(url)
  if brave.jump(url) then
    return true
  else
    hs.urlevent.openURL("https://" .. url)
  end
end

Hyper:bind({}, 'h', nil, function()
  jumpOrOpen("devdocs.io")
end)

Hyper:bind({}, 'p', nil, function()
  jumpOrOpen("chatgpt.com")
end)

Hyper:bind({"alt"}, 'p', nil, function()
  jumpOrOpen("claude.ai")
end)

Hyper:bind({"control"}, 'p', nil, function()
  jumpOrOpen("gemini.google.com")
end)

require('browserSnip')

-- change audio settings based on output
hs.audiodevice.watcher.setCallback(function(event)
  if event == "dOut" then
    local name = hs.audiodevice.defaultOutputDevice():name()
    if name == "WH-1000XM4" then
      hs.shortcuts.run("XM4")
    end
    if name == "MacBook Pro Speakers" then
      hs.shortcuts.run("Macbook Pro Speakers")
    end
  end
end)
hs.audiodevice.watcher.start()
