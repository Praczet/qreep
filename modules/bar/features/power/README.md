# Power Feature

## What It Does

Shows the power button in the right bar slot. Clicking opens the normal
right-side power panel. `qreep-power toggleFullscreen` opens the same action
card on a full-screen layer surface. Destructive actions require confirmation.
Nobody wants an accidental reboot because a pointer had opinions.

## Files

* `Power.qml` - feature controller, service owner, and lazy panel host.
* `PowerButton.qml` - bar button.
* `PowerPanel.qml` - standalone layer panel with namespace `qreep-popup-power`.
* `PowerService.qml` - executes system commands.
* `PowerTheme.qml` - button, sidebar, card, and action tokens.

## Where To Change Things

Change panel width, margin, radius, opacity, and action sizing in
`PowerTheme.qml`.

Change the action list or confirmation copy in `PowerPanel.qml`. Change the
commands in `PowerService.qml`.

Keyboard behavior lives in `PowerPanel.qml`:

* `Up` / `Down` moves through actions.
* `Enter` / `Space` activates the selected action.
* Destructive actions open confirmation with `Cancel` selected first.
* `Left` / `Right` / `Tab` switches between `Cancel` and `Confirm`.
* `Escape` cancels confirmation first, then closes the panel.

## Wiring

`modules/bar/Bar.qml` creates `Power`, passes `power.service` to `PowerButton`,
and asks the controller to toggle the panel. The controller keeps `PowerService`
always alive and creates `PowerPanel` through a `LazyLoader` only while the panel
is open.

Note: This is a bar-owned feature. Sources live under `modules/bar/features/power/`.

Theme is exposed through:

```qml
readonly property QtObject power: PowerFeature.PowerTheme {}
```

## Service Notes

`PowerService.qml` uses `Quickshell.Io.Process` to run:

* `loginctl lock-session`
* `hyprctl dispatch exit`
* `systemctl suspend`
* `systemctl reboot`
* `systemctl poweroff`

`PowerPanel.qml` is a `PanelWindow`, not a `PopupWindow`, so it can have its own
Hyprland layer rule:

```lua
match = { namespace = "qreep-popup-power" }
```

Blur this layer if desired. Do not blur the bar just to make this panel pretty.

IPC:

```bash
quickshell ipc call qreep-power toggle
quickshell ipc call qreep-power toggleFullscreen
```
