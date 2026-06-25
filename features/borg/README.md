# Borg Feature

## What It Does

Shows Borg backup status in the right bar slot. Left click refreshes status.
Right click starts the configured backup command.

## Files

* `Borg.qml` - bar pill.
* `BorgService.qml` - runs status/backup commands and owns parsed state.
* `BorgTooltip.qml` - rich QML tooltip renderer for structured Borg rows.
* `BorgTheme.qml` - Borg-specific sizes, colors, timings, and commands.

## Where To Change Things

Change commands and timings in `BorgTheme.qml`:

```qml
backupCommand
backupStatusBackend
refreshInterval
```

Change status parsing in `BorgService.qml`. Change the pill icon/text rendering
in `Borg.qml`. Change rich tooltip layout in `BorgTooltip.qml`.

## Wiring

`panels/Bar.qml` creates `BorgService`, passes it to `Borg`, and hosts
`BorgTooltip`.

Theme is exposed through:

```qml
readonly property QtObject borg: BorgFeature.BorgTheme {}
```

## Service Notes

`BorgService.qml` uses `Quickshell.Io.Process` to run `borg-pulse --qreep` and
expects JSON. It exposes an IPC target:

```bash
quickshell ipc call qreep-borg refresh
```

The service deliberately prefers structured JSON. Parsing Pango text is a hobby
for people with stronger wrists.
