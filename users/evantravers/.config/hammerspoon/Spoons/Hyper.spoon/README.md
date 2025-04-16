# Hyper

Hyper is a wrapper on
[hs.hotkey.modal](https://www.hammerspoon.org/docs/hs.hotkey.modal) that
enables PTT-style momentary access to lua automation, with an optional
`bindPassThrough` that lets you send a "Hyper chord" to an OSX application.

I chiefly use it to launch applications quickly from a single press, although I
also use it to create "universal" local bindings inspired by [Shawn Blanc's
OopsieThings](https://thesweetsetup.com/oopsiethings-applescript-for-things-on-mac/).

A simple example:

```lua
hs.loadSpoon('Hyper')

App   = hs.application
Hyper = spoon.Hyper

Hyper:bindHotKeys({hyperKey = {{}, 'F19'}})

Hyper:bind({}, 'j', function()
  App.launchOrFocusByBundleID('net.kovidgoyal.kitty')
end)
Hyper:bind({}, 'return', nil, autolayout.autoLayout)
Hyper:bindPassThrough('.', 'com.culturedcode.ThingsMac')
```

## 📦 Installation

Just download [the latest release](https://github.com/evantravers/Hyper.spoon/releases/latest/download/Hyper.spoon.zip), double click to unzip and double-click the resulting Hyper.spoon. It will be installed automatically by hammerspoon.

## ⚠ Migration from 1.0

2.0 no longer requires using exact same configuration table that I specified in
1.0, you are free to use whatever scheme you want!

If you have a 1.0 style configuration table, you can use a quick transformation
function to keep your setup working with 2.0:

```lua
hs.loadSpoon('Hyper')

Config = {
  applications = {
    ['com.culturedcode.ThingsMac'] = {
      bundleID = 'com.culturedcode.ThingsMac',
      hyperKey = 't',
      localBindings = {',', '.'},
    }
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
```

## Resources

- [Original Blog Post](http://evantravers.com/articles/2020/06/08/hammerspoon-a-better-better-hyper-key/)
