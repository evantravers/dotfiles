--- === Headspace ===
---
--- Headspace allows you to protect your focus for certain tasks by creating
--- application blacklist or whitelists.
---
--- Headspace listens for URL schemes of the following format:
--- `hammerspoon://setBlacklist?tags=comma,separated,tags&apps=comma,separated,names`
--- `hammerspoon://setWhitelist?tags=comma,separated,tags&apps=comma,separated,names`
--- `hammerspoon://stopHeadspace`
---
--- `setBlacklist` and `setWhitelist` are exclusive. Setting a new list will
--- wipe out the previous settings. If an app is either tagged in the
--- filesystem with a matching tag or it's name is in the `apps` list it will
--- be matched and the rules applied.

local m = {
  name = "Headspace",
  version = "2.0",
  author = "Evan Travers <evantravers@gmail.com>",
  license = "MIT <https://opensource.org/licenses/MIT>",
  homepage = "https://github.com/evantravers/headspace.spoon",
}

-- CONFIG ==============

local fn    = require('hs.fnutils')

local moduleStyle = fn.copy(hs.alert.defaultStyle)
      moduleStyle.atScreenEdge = 1
      moduleStyle.strokeColor = { white = 1, alpha = 0 }
      moduleStyle.textSize = 36
      moduleStyle.radius = 9
      moduleStyle.padding = 36

-- API =================

--- Headspace:start() -> table
--- Method
--- Starts the application watcher that "blocks" applications and sets up
--- bindings for URL schemes.
---
--- Returns:
---  * self
function m:start()
  m.watcher = hs.application.watcher.new(function(appName, event, hsapp)
    if event == hs.application.watcher.launched then
      if not m.allowed(hsapp) then
        hs.alert(
          "🛑: " .. hsapp:name(),
          moduleStyle
        )
        hsapp:kill()
      end
    end
  end):start()

  hs.urlevent.bind("setBlacklist", m.setBlacklist)
  hs.urlevent.bind("setWhitelist", m.setWhitelist)
  hs.urlevent.bind("stopHeadspace", m.stopHeadspace)

  return self
end

--- Headspace:stop() -> table
--- Method
---
--- Returns:
---  * self
function m:stop()
  -- kill any watchers
  m.watcher = nil

  -- clear residual spaces
  hs.settings.clear("headspace")

  -- destroy URL watchers
  hs.urlevent.bind("setBlacklist", nil)
  hs.urlevent.bind("setWhitelist", nil)
  hs.urlevent.bind("stopHeadspace", nil)

  return self
end

m.getWhitelist = function()
  if hs.settings.get("headspace") then
    return hs.settings.get("headspace")["whitelist"]
  end
end

m.getBlacklist = function()
  if hs.settings.get("headspace") then
    return hs.settings.get("headspace")["blacklist"]
  end
end

m.allowed = function(app)
  local tags = hs.fs.tagsGet(app:path())
  local name = app:name()

  if tags and fn.contains(tags, "whitelisted") then
    return true
  end

  if m.getWhitelist() then
    local appAllowed = false
    local tagAllowed = false

    if m.getWhitelist().apps then
      appAllowed = fn.contains(m.getWhitelist().apps, name)
    end
    if m.getWhitelist().tags and tags then
      tagAllowed = fn.some(m.getWhitelist().tags, function(tag)
        return fn.contains(tags, tag)
      end)
    end

    return tagAllowed or appAllowed
  end

  if m.getBlacklist() then
    local appBlocked = false
    local tagBlocked = false

    if m.getBlacklist().apps then
      appBlocked = fn.contains(m.getBlacklist().apps, name)
    end

    if m.getBlacklist().tags and tags then
      tagBlocked = fn.some(m.getBlacklist().tags, function(tag)
        return fn.contains(tags, tag)
      end)
    end

    return (not appBlocked) and (not tagBlocked)
  end

  return true
end

m.dockedAndNotFinder = function(app)
  return app:bundleID() ~= "com.apple.finder" and app:kind() == 1
end

m.killBlockedDockedApps = function()
  local dockedAndBlocked =
    fn.filter(hs.application.runningApplications(), function(app)
      return m.dockedAndNotFinder(app) and not m.allowed(app)
    end)

  fn.each(dockedAndBlocked, function(app) app:kill() end)
end

function m.setBlacklist(_eventName, params)
  local list = {}

  if params["tags"] then
    list["tags"] = fn.split(params["tags"], ",")
  end
  if params["apps"] then
    list["apps"] = fn.split(params["apps"], ",")
  end

  hs.settings.set("headspace", { ["blacklist"] = list })

  if params["kill"] then
    m.killBlockedDockedApps()
  end
end

function m.setWhitelist(_eventName, params)
  local list = {}

  if params["tags"] then
    list["tags"] = fn.split(params["tags"], ",")
  end
  if params["apps"] then
    list["apps"] = fn.split(params["apps"], ",")
  end

  hs.settings.set("headspace", { ["whitelist"] = list })

  if params["kill"] then
    m.killBlockedDockedApps()
  end
end

function m.stopHeadspace(_eventName, _params)
  hs.settings.clear("headspace")
end

return m
