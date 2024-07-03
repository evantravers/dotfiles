hs.loadSpoon('Hyper')
hs.loadSpoon('Headspace'):start()
hs.loadSpoon('Teamz'):start()
hs.loadSpoon('HyperModal')

Config = {}
Config.applications = {
  ['com.raycast.macos'] = {
    bundleID = 'com.raycast.macos',
    localBindings = {'c', 'space'}
  },
  ['com.github.wez.wezterm'] = {
    bundleID = 'com.github.wez.wezterm',
    hyperKey = 'j',
    tags = {'coding'}
  },
  ['com.brave.Browser'] = {
    bundleID = 'com.brave.Browser',
    tags = {'browsers'},
  },
  ['org.mozilla.firefox'] = {
    bundleID = 'org.mozilla.firefox',
    tags = {'browsers'}
  },
  ['com.apple.Safari'] = {
    bundleID = 'com.apple.Safari',
    tags = {'browsers'}
  },
  ['com.google.Chrome'] = {
    bundleID = 'com.google.Chrome',
    tags = {'browsers'}
  },
  ['com.microsoft.teams2'] = {
    bundleID = 'com.microsoft.teams2',
    tags = {'communication', 'chat'}
  },
  ['com.apple.mail'] = {
    bundleID = 'com.apple.mail',
    hyperKey = 'e',
    tags = {'communication', 'distraction'}
  },
  ['com.flexibits.fantastical2.mac'] = {
    bundleID = 'com.flexibits.fantastical2.mac',
    hyperKey = 'y',
    localBindings = {'/'},
    tags = {'planning', 'review', 'calendar'},
    whitelisted = true,
  },
  ['com.apple.finder'] = {
    bundleID = 'com.apple.finder',
    hyperKey = 'f'
  },
  ['com.hnc.Discord'] = {
    bundleID = 'com.hnc.Discord',
    tags = {'distraction', 'chat'},
  },
  ['com.tinyspeck.slackmacgap'] = {
    bundleID = 'com.tinyspeck.slackmacgap',
    tags = {'distraction', 'communication', 'chat'},
  },
  ['com.tapbots.Tweetbot3Mac'] = {
    bundleID = 'com.tapbots.Tweetbot3Mac',
    tags = {'distraction', 'socialmedia'},
  },
  ['com.culturedcode.ThingsMac'] = {
    bundleID = 'com.culturedcode.ThingsMac',
    hyperKey = 't',
    tags = {'planning', 'review', 'tasks'},
    whitelisted = true,
    localBindings = {',', '.'},
  },
  ['com.agiletortoise.Drafts-OSX'] = {
    bundleID = 'com.agiletortoise.Drafts-OSX',
    hyperKey ='d',
    tags = {'review', 'writing', 'research', 'notes'},
    whitelisted = true,
    localBindings = {'x', 'n'}
  },
  ['com.joehribar.toggl'] = {
    bundleID = 'com.joehribar.toggl',
    hyperKey = 'r'
  },
  ['com.ideasoncanvas.mindnode.macos'] = {
    bundleID = 'com.ideasoncanvas.mindnode.macos',
    tags = {'research'},
  },
  ['com.apple.MobileSMS'] = {
    bundleID = 'com.apple.MobileSMS',
    tags = {'communication', 'distraction', 'personal'},
  },
  ['com.valvesoftware.steam'] = {
    bundleID = 'com.valvesoftware.steam',
    tags = {'distraction'}
  },
  ['net.battle.app'] = {
    bundleID = 'net.battle.app',
    tags = {'distraction'}
  },
  ['com.spotify.client'] = {
    bundleID = 'com.spotify.client'
  },
  ['com.figma.Desktop'] = {
    bundleID = 'com.figma.Desktop',
    tags = {'design'},
  },
  ['com.reederapp.5.macOS'] = {
    bundleID = 'com.reederapp.5.macOS',
    tags = {'distraction'},
  },
  ['md.obsidian'] = {
    bundleID = 'md.obsidian',
    hyperKey = 'g',
    tags = {'research', 'notes'},
  },
  ['us.zoom.xos'] = {
    bundleID = 'us.zoom.xos',
  },
  ['org.whispersystems.signal-desktop'] = {
    bundleID = 'org.whispersystems.signal-desktop',
    tags = {'distraction', 'communication', 'personal'}
  },
  ['ru.keepcoder.Telegram'] = {
    bundleID = 'ru.keepcoder.Telegram',
    tags = {'distraction', 'communication', 'personal'}
  },
  ['com.surteesstudios.Bartender'] = {
    bundleID = 'com.surteesstudios.Bartender',
    localBindings = {'b'}
  },
  ['company.thebrowser.Browser'] = {
    bundleID = 'company.thebrowser.Browser',
    tags = {'browsers'}
  },
  ['com.superultra.Homerow'] = {
    bundleID = 'com.superultra.Homerow',
    localBindings = {'l'}
  },
  ['com.flexibits.cardhop.mac'] = {
    bundleID = 'com.flexibits.cardhop.mac',
    localBindings = {'u'}
  },
  ['com.goodsnooze.MacWhisper'] = {
    bundleID = 'com.goodsnooze.MacWhisper',
    localBindings = {'a'}
  },
  ['com.goodsnooze.MenuGPT'] = {
    bundleID = 'com.goodsnooze.MenuGPT',
    localBindings = {'p'}
  }
}

Hyper = spoon.Hyper

Hyper:bindHotKeys({hyperKey = {{}, 'F19'}})

hs.fnutils.each(Config.applications, function(appConfig)
  if appConfig.hyperKey then
    Hyper:bind({}, appConfig.hyperKey, function() hs.application.launchOrFocusByBundleID(appConfig.bundleID) end)
  end
  if appConfig.localBindings then
    hs.fnutils.each(appConfig.localBindings, function(key)
      Hyper:bindPassThrough(key, appConfig.bundleID)
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

  hs.settings.set("group." .. choice.tag, choice.bundleID)
  hs.application.launchOrFocusByBundleID(choice.bundleID)
end

local hyperGroup = function(key, tag)
  Hyper:bind({}, key, nil, function()
    hs.application.launchOrFocusByBundleID(hs.settings.get("group." .. tag))
  end)
  Hyper:bind({'option'}, key, nil, function()
    local group =
      hs.fnutils.filter(Config.applications, function(app)
        return app.tags and
               hs.fnutils.contains(app.tags, tag) and
               app.bundleID ~= hs.settings.get("group." .. tag)
      end)

    local choices = {}
    hs.fnutils.each(group, function(app)
      table.insert(choices, {
        text = hs.application.nameForBundleID(app.bundleID),
        image = hs.image.imageFromAppBundle(app.bundleID),
        bundleID = app.bundleID,
        key = key,
        tag = tag
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

hyperGroup('q', 'personal')
hyperGroup('k', 'browsers')
hyperGroup('i', 'chat')

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
