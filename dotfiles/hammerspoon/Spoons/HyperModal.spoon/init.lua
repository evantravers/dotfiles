--- === HyperModal ===

local m = hs.hotkey.modal.new({}, nil)

m.name = "HyperModal"
m.version = "0.0.1"
m.author = "Evan Travers <evantravers@gmail.com>"
m.license = "MIT <https://opensource.org/licenses/MIT>"
m.homepage = "https://github.com/evantravers/hammerspoon-config/Spoons/HyperModal/"

-- initialize it as "closed"
m.isOpen = false

function m:entered()
  m.isOpen = true

  local f = hs.window.focusedWindow():frame()

  -- https://github.com/Hammerspoon/hammerspoon/issues/2214
  m.indicator = hs.canvas.new(f):appendElements({
    type = "rectangle",
    action="stroke",
    strokeWidth=4.0,
    strokeColor= {hex = "#F74F9E", alpha=0.7},
    roundedRectRadii = {xRadius=14.0, yRadius=14.0},
    frame = f
  }):show()

  return self
end

function m:exited()
  m.isOpen = false

  m.indicator:delete()

  return self
end

function m:toggle()
  if m.isOpen then
    m:exit()
  else
    m:enter()
  end

  return self
end

function m:start()
  -- disable animations
  hs.window.animationDuration = 0

  -- provide alternate escapes
  m
  :bind('ctrl', '[', function() m:exit() end)
  :bind('', 'escape', function() m:exit() end)

  return self
end

function m:bindHotKeys(mapping)
  local spec = {
    toggle = hs.fnutils.partial(self.toggle, self)
  }

  hs.spoons.bindHotkeysToSpec(spec, mapping)

  return self
end

return m
