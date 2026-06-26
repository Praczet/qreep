# Power Feature

## What It Does

Shows the power button in the right bar slot. Clicking opens a full-height
right-side power panel. Destructive actions require confirmation. Nobody wants
an accidental reboot because a pointer had opinions.

## Files

* `PowerButton.qml` - bar button.
* `PowerPanel.qml` - standalone layer panel with namespace `qreep-popup-power`.
* `PowerService.qml` - executes system commands.
* `PowerTheme.qml` - button, sidebar, card, and action tokens.

## Where To Change Things

Change panel width, margin, radius, opacity, and action sizing in
`PowerTheme.qml`.

Change the action list or confirmation copy in `PowerPanel.qml`. Change the
commands in `PowerService.qml`.

## Wiring

`modules/bar/Bar.qml` creates `PowerService`, hosts `PowerButton`, and hosts
`PowerPanel`.

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
