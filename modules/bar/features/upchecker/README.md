# Upchecker Feature

## What It Does

Shows update status in the right bar slot and opens a standalone update panel.
The panel lists packages, shows details, supports filtering, and can launch the
configured update command.

## Files

* `UpcheckerButton.qml` - bar button.
* `UpcheckerPanel.qml` - standalone layer panel.
* `UpcheckerService.qml` - update/restart checks, package details, commands.
* `UpcheckerTheme.qml` - panel layout, command names, and visual tokens.

## Where To Change Things

Change commands and restart package groups in `UpcheckerTheme.qml` or the
matching service properties passed from `Bar.qml`.

Change package parsing, restart logic, caching, and IPC in
`UpcheckerService.qml`. Change panel layout and filter behavior in
`UpcheckerPanel.qml`.

## Wiring

`panels/Bar.qml` creates `UpcheckerService`, passes it to `UpcheckerButton`, and
hosts `UpcheckerPanel`.

Theme is exposed through:

```qml
readonly property QtObject upchecker: UpcheckerFeature.UpcheckerTheme {}
```

## Service Notes

The service uses `Quickshell.Io.Process` to run `checkupdates`, package detail
commands, restart checks, and the configured update command.

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
