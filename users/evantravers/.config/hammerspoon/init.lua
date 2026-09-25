hs.loadSpoon('Hyper')

-- bundleID, global, local
Bindings = {
  {'com.apple.MobileSMS', 'q', nil},
  {'com.apple.finder', 'f', nil},
  {'com.apple.mail', 'e', nil},
  {'com.flexibits.cardhop.mac', nil, {'u'}},
  {'com.flexibits.fantastical2.mac', 'y', {'/'}},
  {'com.mitchellh.ghostty', 'j', nil},
  {'com.toggl.daneel', 'r', nil},
  {'com.raycast.macos', nil, {'c', 'n', 'space'}},
  {'com.superultra.Homerow', nil, {'return', 'tab', ';'}},
  {'md.obsidian', 'g', nil}
}

Hyper = spoon.Hyper

Hyper:bindHotKeys({hyperKey = {{}, 'F19'}})

-- MoveWindows: toggle-style window mode on F18, ported from my old
-- movewindows.lua / MoveWindows.spoon. F18 toggles the mode on/off; while
-- active, shows the focused app on every screen.
MoveWindows = hs.hotkey.modal.new({}, nil)
MoveWindows.isOpen = false

function MoveWindows:entered()
  self.isOpen = true
  self.alertUuids = hs.fnutils.map(hs.screen.allScreens(), function(screen)
    local prompt = string.format("🖥 : %s",
                                 hs.window.focusedWindow():application():title())
    return hs.alert.show(prompt, hs.alert.defaultStyle, screen, true)
  end)
end

function MoveWindows:exited()
  self.isOpen = false
  hs.fnutils.ieach(self.alertUuids, function(uuid)
    hs.alert.closeSpecific(uuid)
  end)
end

function MoveWindows:toggle()
  if self.isOpen then
    self:exit()
  else
    self:enter()
  end
end

hs.window.animationDuration = 0

hs.hotkey.bind({}, 'F18', function() MoveWindows:toggle() end)

-- Directional halves with modifier-driven sizing:
--   (none)      = 50%
--   shift       = 30%
--   shift+ctrl  = 70%
-- Adding alt performs the same snap on the next display.
MoveWindows.directional = {
  { key = 'h', side = 'left' },
  { key = 'l', side = 'right' },
  { key = 'k', side = 'top' },
  { key = 'j', side = 'bottom' },
}

local function unitFor(side, size)
  if side == 'left'   then return hs.geometry.rect(0, 0, size, 1) end
  if side == 'right'  then return hs.geometry.rect(1 - size, 0, size, 1) end
  if side == 'top'    then return hs.geometry.rect(0, 0, 1, size) end
  if side == 'bottom' then return hs.geometry.rect(0, 1 - size, 1, size) end
end

local function snap(entry, size, otherMonitor)
  local win = hs.window.focusedWindow()
  if win then
    if otherMonitor then win:moveToScreen(win:screen():next()) end
    win:moveToUnit(entry.unit or unitFor(entry.side, size))
  end
  MoveWindows:exit()
end

hs.fnutils.each(MoveWindows.directional, function(entry)
  MoveWindows:bind({}, entry.key, function() snap(entry, 0.5, false) end)
  MoveWindows:bind({'shift'}, entry.key, function() snap(entry, 0.3, false) end)
  MoveWindows:bind({'shift', 'ctrl'}, entry.key, function() snap(entry, 0.7, false) end)
  MoveWindows:bind({'alt'}, entry.key, function() snap(entry, 0.5, true) end)
  MoveWindows:bind({'alt', 'shift'}, entry.key, function() snap(entry, 0.3, true) end)
  MoveWindows:bind({'alt', 'shift', 'ctrl'}, entry.key, function() snap(entry, 0.7, true) end)
end)

-- Center the focused window at a fixed ratios
MoveWindows:bind({}, 'c', function()
  local win = hs.window.focusedWindow()
  win:setSize({ w = 1024, h = 768 }):centerOnScreen()
  MoveWindows:exit()
end)
MoveWindows:bind({'shift'}, 'c', function()
  local win = hs.window.focusedWindow()
  win:setSize({ w = 1440, h = 900 }):centerOnScreen()
  MoveWindows:exit()
end)


MoveWindows.grid = {
  { key = 'space', unit = hs.layout.maximized },
}

hs.fnutils.each(MoveWindows.grid, function(entry)
  MoveWindows:bind({}, entry.key, function() snap(entry, nil, false) end)
  MoveWindows:bind({'alt'}, entry.key, function() snap(entry, nil, true) end)
end)

MoveWindows
  :bind({'ctrl'}, '[', function() MoveWindows:exit() end)
  :bind({}, 'escape', function() MoveWindows:exit() end)
  :bind({}, ',', function()
    hs.window.focusedWindow()
      :application()
      :selectMenuItem("Left of Screen")
    MoveWindows:exit()
  end)
  :bind({}, '.', function()
    hs.window.focusedWindow()
      :application()
      :selectMenuItem("Right of Screen")
    MoveWindows:exit()
  end)
  :bind({}, 'tab', function()
    hs.window.focusedWindow():centerOnScreen()
    MoveWindows:exit()
  end)

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

Hyper:bind({}, ',', function()
  Hyper:exit()
  hs.shortcuts.run("Smart Capture")
end)
Hyper:bind({}, '.', function()
  Hyper:exit()
  hs.shortcuts.run("Quick Note")
end)

-- provide the ability to override config per computer
if (hs.fs.displayName('./localConfig.lua')) then
  require('localConfig')
end

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
  'com.google.Chrome',
  'org.nixos.firefox',
})

hyperGroup('i', {
  'com.microsoft.teams2',
  'com.tinyspeck.slackmacgap',
  'com.hnc.Discord'
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
  end
end)

Hyper:bind({'shift'}, 'e', nil, function()
  hs.urlevent.openURL("https://outlook.office365.com/mail/")
end)

Hyper:bind({}, 't', nil, function()
  hs.urlevent.openURL("obsidian://open?vault=wiki&file=templates%2Ftasks%2FToday%20Tasks")
end)


Hyper:bind({}, 'h', nil, function()
  hs.urlevent.openURL("https://devdocs.io")
end)

Hyper:bind({}, 'p', nil, function()
  hs.urlevent.openURL("https://claude.ai")
end)

-- Add new functionality to the OSX Move Windows commands
local function eventTapWatcher(event)
  local eventType = event:getType()

  -- Only process keyDown events, not flagsChanged
  if eventType == hs.eventtap.event.types.keyDown then
    local keyCode = event:getKeyCode()
    local flags = event:getFlags()

    -- keyCode 2 is 'd' - move window to next display
    if keyCode == 2 and flags['fn'] and flags['ctrl'] then
      local win = hs.window.focusedWindow()
      if win then
        local screen = win:screen()
        local nextScreen = screen:next()
        win:moveToScreen(nextScreen)
      end
      return true  -- Delete the event, preventing it from being passed to other applications
    end
  end

  return false  -- Allow other events to pass through
end

-- Store event tap in a variable to prevent garbage collection
windowActionsWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged, hs.eventtap.event.types.keyDown}, eventTapWatcher):start()
