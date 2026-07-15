# Upchecker Feature

## What It Does

Shows update status in the right bar slot and opens a standalone update panel.
The panel lists packages, shows details, supports filtering, and can launch the
configured update command.

## Files

* `UpcheckerButton.qml` - bar button.
* `Upchecker.qml` - feature controller, service owner, and lazy panel host.
* `UpcheckerPanel.qml` - standalone layer panel.
* `UpcheckerService.qml` - update/restart checks, package details, commands.
* `UpcheckerTheme.qml` - panel layout, command names, and visual tokens.

## Where To Change Things

Change commands and restart package groups in `UpcheckerTheme.qml`. The
controller passes those theme values into `UpcheckerService`.

Change package parsing, restart logic, caching, and IPC in
`UpcheckerService.qml`. Change panel layout and filter behavior in
`UpcheckerPanel.qml`.

## Wiring

`modules/bar/Bar.qml` creates `Upchecker`, passes `upchecker.service` to
`UpcheckerButton`, and asks the controller to toggle the panel. The controller
keeps `UpcheckerService` always alive and creates `UpcheckerPanel` through a
`LazyLoader` only while the panel is open.

Note: This is a bar-owned feature. Sources live under `modules/bar/features/upchecker/`.

Theme is exposed through:

```qml
readonly property QtObject upchecker: UpcheckerFeature.UpcheckerTheme {}
```

## Service Notes

The service uses `Quickshell.Io.Process` to run `checkupdates`, package detail
commands, restart checks, and the configured update command.

The default update path is:

```text
Upchecker Update button -> ghostty -e update-btw
```

`update-btw` is Adam's local helper at `~/.local/bin/update-btw`, not a repo
script. For Qreep Polkit to handle the password prompt, that helper runs `paru`
with `pkexec` as its privileged command:

```bash
paru --sudo /usr/bin/pkexec -Syu --needed
```

That keeps `paru` running as the user while the root-owned pacman step asks
Polkit for authentication. Qreep's Polkit module does not grant root access to
Upchecker directly; it only becomes the graphical agent for commands that
already use Polkit. If `update-btw` goes back to plain `sudo`, the nice dialog
will sit there looking unemployed.

IPC target:

```bash
quickshell ipc call qreep-upchecker refresh
quickshell ipc call qreep-upchecker toggle
quickshell ipc call qreep-upchecker update
```

The panel namespace is:

```qml
WlrLayershell.namespace: "qreep-popup-upchecker"
```
