--- === HyperModal ===

local m = hs.hotkey.modal.new({}, nil)

m.name = "HyperModal"
m.version = "0.0.1"
m.author = "Evan Travers <evantravers@gmail.com>"
m.license = "MIT <https://opensource.org/licenses/MIT>"
m.homepage = "https://github.com/evantravers/hammerspoon-config/Spoons/HyperModal/"

-- initialize it as "closed"
m.isOpen = false

m.style = {
  strokeWidth  = 0,
  strokeColor = { white = 1, alpha = 0 },
  fillColor   = { white = 0, alpha = 0.35 },
  textColor = { white = 1, alpha = 1 },
  textFont  = ".AppleSystemUIFont",
  textSize  = 54,
  radius = 28,
  atScreenEdge = 0,
  fadeInDuration = 0,
  fadeOutDuration = 0,
  padding = nil,
}

function m:entered()
  m.isOpen = true

  local win = hs.window.focusedWindow()
  local screen = win:screen()
  local max = screen:fullFrame()
  local f = win:frame()

  -- https://github.com/Hammerspoon/hammerspoon/issues/2214
  m.indicator = hs.canvas.new{x=max.x, y=max.y, h=max.h, w=max.w}:appendElements({
    type = "rectangle",
    action="stroke",
    strokeWidth=4.0,
    strokeColor= {white=0.5, alpha=0.7},
    roundedRectRadii = {xRadius=14.0, yRadius=14.0},
    frame = {x=f.x, y=f.y, h=f.h, w=f.w}
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
