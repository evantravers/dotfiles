hs.loadSpoon('Hyper')

-- bundleID, global, local
Bindings = {
  -- {'com.agiletortoise.Drafts-OSX', 'd', {'x', 'n'}},
  {'com.apple.MobileSMS', 'q', nil},
  {'com.apple.finder', 'f', nil},
  {'com.apple.mail', 'e', nil},
  {'com.flexibits.cardhop.mac', nil, {'u'}},
  {'com.flexibits.fantastical2.mac', 'y', {'/'}},
  {'com.mitchellh.ghostty', 'j', nil},
  {'com.toggl.daneel', 'r', nil},
  {'com.raycast.macos', nil, {'c', 'n', 'space', ';'}},
  {'com.superultra.Homerow', nil, {'return', 'tab'}},
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

Hyper:bind({}, 't', nil, function()
  hs.urlevent.openURL("https://app.todoist.com/app/today")
end)

Hyper:bind({}, 'h', nil, function()
  hs.urlevent.openURL("https://devdocs.io")
end)

Hyper:bind({}, 'p', nil, function()
  hs.urlevent.openURL("https://claude.ai")
end)

Hyper:bind({"shift"}, 'p', nil, function()
  hs.urlevent.openURL("https://perplexity.ai")
end)

Hyper:bind({"control"}, 'p', nil, function()
  hs.urlevent.openURL("https://gemini.google.com")
end)

Hyper:bind({"alt"}, 'p', nil, function()
  hs.urlevent.openURL("https://chatgpt.com")
end)

Hyper:bind({"command"}, 'p', nil, function()
  hs.urlevent.openURL("https://x.com/i/grok")
end)
