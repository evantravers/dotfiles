# Headspace

Protect your focus and keep your head in the right space by blocking distracting applications from even opening.

## Controls

Headspace listens for URL schemes of the following format:

- `hammerspoon://setBlacklist?tags=comma,separated,tags&apps=comma,separated,names&kill=<true or false>`
- `hammerspoon://setWhitelist?tags=comma,separated,tags&apps=comma,separated,names&kill=<true or false>`
- `hammerspoon://stopHeadspace`

`setBlacklist` and `setWhitelist` are exclusive. Setting a new list will wipe out the previous settings.

If you pass `kill=true` in the URL, Headspace will apply your new rules to any running applications in your OSX Dock, immediately killing matching applications.

If an app is either [tagged in the MacOS filesystem](https://support.apple.com/guide/mac-help/tag-files-and-folders-mchlp15236/mac) with a matching tag or it's name is in the `apps` list it will be matched and the rules applied.

MacOS doesn't let you tag built-in applications (Messages.app, Mail.app, etc.) so you can use the `apps` list to block them.

Optionally, if you filesystem tag an application `whitelisted` no rules will ever be applied to it. This is useful for things like launchers or other tools you always want available.

## Usage

Using the URL scheme means that you can use _any_ tool as your main interface for Headspace:

- [Bunch](https://bunchapp.co/) has [simple URL interactions](https://bunchapp.co/docs/bunch-files/opening-web-pages/).
- [Shortcuts](https://support.apple.com/guide/shortcuts-mac/intro-to-shortcuts-apdf22b0444c/mac) using [the `Open URLs` action](https://support.apple.com/guide/shortcuts/intro-to-url-schemes-apd621a1ad7a/ios).
- [Alfred Workflows](https://www.alfredapp.com/workflows/)
- and more!

## Examples

Block distracting communications tools:  
`hammerspoon://setBlacklist?tags=communication,distraction&apps=Mail,Messages`

Only permit applications tagged `writing`, and quit any other apps for a Hemingway writing session:  
`hammerspoon://setWhitelist?tags=writing&kill=true`

## Install

1. MacOS
2. [Hammerspoon](https://www.hammerspoon.org/go/) installed
3. Download a [release](https://github.com/evantravers/Headspace.spoon/releases) to `~/.hammerspoon/Spoons/Headspace.spoon`
4. Load the Spoon by adding the following code snippet to `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon('Headspace'):start()
```

## Looking for the old version?

The [older version](https://evantravers.com/articles/2021/03/20/headspace-v1-0/) (integrated UI chooser and toggl tracker) is available for viewing here: [Version 1.1.4](https://github.com/evantravers/Headspace.spoon/tree/1.1.4)
