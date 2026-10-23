# Launcher Feature

## What It Does

Shows the launcher button in the left bar slot. Clicking opens KIP, which is
now the launcher: empty input lists apps, typing filters them, and slash
commands do the rest (see [`modules/kip/README.md`](../../../kip/README.md)).

It is deliberately small. A launcher button does not need to discover itself.

## Files

* `LauncherButton.qml` - bar button and tooltip.
* `LauncherService.qml` - detached command runner and logging.
* `LauncherTheme.qml` - button icon size.

## Wiring

`modules/bar/Bar.qml` creates `LauncherService`, hosts `LauncherButton`, and
calls `launcherService.launchLauncher()` on click.

This is a bar-owned feature. Sources live under
`modules/bar/features/launcher/`.

Theme is exposed through:

```qml
readonly property QtObject launcher: LauncherFeature.LauncherTheme {}
```

## Command

The current command is:

```qml
readonly property var launcherCommand: ["quickshell", "-c", "qreep", "ipc", "call", "qreep-kip", "toggle"]
```

Yes, Qreep calls its own IPC to open its own module. It keeps the button as
dumb as it was when it ran an external launcher, and the command still runs
detached. Change that in `LauncherService.qml` if the launcher command changes. If this
becomes configurable later, make it a theme token or a small config value, not a
new subsystem with a badge.
