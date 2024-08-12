hs.loadSpoon('Hyper')
hs.loadSpoon('Headspace'):start()
hs.loadSpoon('Teamz'):start()
hs.loadSpoon('HyperModal')

-- bundleID, global, local
Bindings = {
  {'com.agiletortoise.Drafts-OSX', 'd', {'x', 'n'}},
  {'com.apple.MobileSMS', 'q', nil},
  {'com.apple.finder', 'f', nil},
  {'com.apple.mail', 'e', nil},
  {'com.culturedcode.ThingsMac', 't', {',', '.'}},
  {'com.flexibits.cardhop.mac', nil, {'u'}},
  {'com.flexibits.fantastical2.mac', 'y', {'/'}},
  {'com.github.wez.wezterm', 'j', nil},
  {'com.goodsnoze.MacWhisper', nil, {'a'}},
  {'com.joehribar.toggl', 'r', nil},
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

-- provide the ability to override config per computer
if (hs.fs.displayName('./localConfig.lua')) then
  require('localConfig')
end

-- https://github.com/dmitriiminaev/Hammerspoon-HyperModal/blob/master/.hammerspoon/yabai.lua
local yabai = function(args, completion)
  local yabai_output = ""
  local yabai_error = ""
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

HyperModal = spoon.HyperModal
HyperModal
  :start()
  :bind('', "a", function()
    yabai({"-m", "window", "--swap", "first"})
    HyperModal:exit()
  end)
  :bind('', "z", function()
    yabai({"-m", "window", "--toggle", "zoom-parent"})
    HyperModal:exit()
  end)
  :bind('', "f", function()
    yabai({"-m", "window", "--toggle", "float"})
    HyperModal:exit()
  end)
  :bind('', "v", function()
    yabai({"-m", "space", "--mirror", "y-axis"})
    HyperModal:exit()
  end)
  :bind({"shift"}, "v", function()
    yabai({"-m", "space", "--mirror", "x-axis"})
    HyperModal:exit()
  end)
  :bind('', "x", function()
    yabai({"-m", "window", "--toggle", "split"})
    HyperModal:exit()
  end)
  :bind('', "space", function()
    yabai({"-m", "window", "--toggle", "zoom-fullscreen"})
    HyperModal:exit()
  end)
  :bind('', "h", function()
    yabai({"-m", "window", "--swap", "west"})
    HyperModal:exit()
  end)
  :bind('', "j", function()
    yabai({"-m", "window", "--swap", "south"})
    HyperModal:exit()
  end)
  :bind('', "k", function()
    yabai({"-m", "window", "--swap", "north"})
    HyperModal:exit()
  end)
  :bind('', "l", function()
    yabai({"-m", "window", "--swap", "east"})
    HyperModal:exit()
  end)
  :bind({"control"}, "h", function()
    yabai({"-m", "window", "--insert", "west"})
    HyperModal:exit()
  end)
  :bind({"control"}, "j", function()
    yabai({"-m", "window", "--insert", "south"})
    HyperModal:exit()
  end)
  :bind({"control"}, "k", function()
    yabai({"-m", "window", "--insert", "north"})
    HyperModal:exit()
  end)
  :bind({"control"}, "l", function()
    yabai({"-m", "window", "--insert", "east"})
    HyperModal:exit()
  end)
  :bind({"alt"}, "h", function()
    yabai({"-m", "window", "--warp", "west"})
    HyperModal:exit()
  end)
  :bind({"alt"}, "j", function()
    yabai({"-m", "window", "--warp", "south"})
    HyperModal:exit()
  end)
  :bind({"alt"}, "k", function()
    yabai({"-m", "window", "--warp", "north"})
    HyperModal:exit()
  end)
  :bind({"alt"}, "l", function()
    yabai({"-m", "window", "--warp", "east"})
    HyperModal:exit()
  end)
  :bind({'shift'}, "l", function()
    yabai({"-m", "window", "--display", "east"})
    HyperModal:exit()
  end)
  :bind({'shift'}, "h", function()
    yabai({"-m", "window", "--display", "west"})
    HyperModal:exit()
  end)
  :bind("", "s", function()
    yabai({"-m", "window", "--stack", "mouse"})
    HyperModal:exit()
  end)
  :bind("", "1", function()
    yabai({"-m", "window", "--ratio", "abs:0.3"})
    HyperModal:exit()
  end)
  :bind("", "2", function()
    yabai({"-m", "window", "--ratio", "abs:0.5"})
    HyperModal:exit()
  end)
  :bind("", "3", function()
    yabai({"-m", "window", "--ratio", "abs:0.7"})
    HyperModal:exit()
  end)
  :bind("", "4", function()
    yabai({"-m", "window", "--ratio", "abs:0.8"})
    HyperModal:exit()
  end)
  :bind({"alt"}, "r", function()
    yabai({"-m", "space", "--balance"})
    HyperModal:exit()
  end)
  :bind({"shift"}, "b", function()
    yabai({"-m", "space", "--layout", "stack"})
    HyperModal:exit()
  end)
  :bind("", "b", function()
    yabai({"-m", "space", "--layout", "bsp"})
    HyperModal:exit()
  end)
  :bind({"control"}, "b", function()
    yabai({"-m", "space", "--layout", "float"})
    HyperModal:exit()
  end)
  :bind('', ';', function()
    hs.urlevent.openURL("raycast://extensions/raycast/system/toggle-system-appearance")
    HyperModal:exit()
  end)

Hyper:bind({}, 'm', function() HyperModal:toggle() end)

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
    print("Setting options...")
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
    'org.mozilla.firefox'
  })

hyperGroup('i', {
    'com.microsoft.teams2'
  })

-- Jump to google hangout or zoom
Z_count = 0
Hyper:bind({}, 'z', nil, function()
  Z_count = Z_count + 1

  hs.timer.doAfter(0.2, function()
    Z_count = 0
  end)

  if Z_count == 2 then
    spoon.ElgatoKey:toggle()
  else
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
  end
end)

-- Jump to figma
Hyper:bind({}, 'v', nil, function()
  if hs.application.find('com.figma.Desktop') then
    hs.application.launchOrFocusByBundleID('com.figma.Desktop')
  elseif hs.application.find('com.electron.realtimeboard') then
    hs.application.launchOrFocusByBundleID('com.electron.realtimeboard')
  elseif hs.application.find('com.adobe.LightroomClassicCC7') then
    hs.application.launchOrFocusByBundleID('com.adobe.LightroomClassicCC7')
  else
    brave.jump("lucidchart.com|figma.com")
  end
end)

Hyper:bind({}, 'h', nil, function()
  if brave.jump("devdocs.io") then
    return true
  else
    hs.urlevent.openURL("http://devdocs.io")
  end
end)

Hyper:bind({}, 'p', nil, function()
  if brave.jump("chatgpt.com") then
    return true
  else
    hs.urlevent.openURL("https://chatgpt.com")
  end
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
