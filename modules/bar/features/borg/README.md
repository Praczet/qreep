# Borg Feature

## What It Does

Shows Borg backup status in the right bar slot. Left click refreshes status.
Right click starts the configured backup command and shows a small progress
popup while the backup state file reports active work.

## Files

* `Borg.qml` - bar pill.
* `BorgService.qml` - runs status/backup commands and owns parsed state.
* `BorgProgressPopup.qml` - anchored backup progress/result popup.
* `BorgTooltip.qml` - rich QML tooltip renderer for structured Borg rows.
* `BorgTheme.qml` - Borg-specific sizes, colors, timings, and commands.

## Where To Change Things

Change commands and timings in `BorgTheme.qml`:

```qml
backupCommand
backupStatusBackend
backupStatePath
backupPanelHideDelay
refreshInterval
```

Change status parsing in `BorgService.qml`. Change the pill icon/text rendering
in `Borg.qml`. Change rich tooltip layout in `BorgTooltip.qml`.

## Wiring

`modules/bar/Bar.qml` creates `BorgService`, passes it to `Borg`, and hosts
`BorgTooltip`.

Note: This is a bar-owned feature. Sources live under `modules/bar/features/borg/`.

Theme is exposed through:

```qml
readonly property QtObject borg: BorgFeature.BorgTheme {}
```

## Service Notes

`BorgService.qml` uses `Quickshell.Io.Process` to run `borg-pulse --qreep` and
expects JSON. It exposes an IPC target:

```bash
quickshell ipc call qreep-borg refresh
quickshell ipc call qreep-borg showProgress
quickshell ipc call qreep-borg hideProgress
quickshell ipc call qreep-borg toggleProgress
```

The service deliberately prefers structured JSON. Parsing Pango text is a hobby
for people with stronger wrists.

## Backup Progress State

`BorgService.qml` polls:

```text
~/.cache/qreep/borg/state.json
```

That file is the bridge between `borg-to-borg-backup` and Qreep. It also means a
backup started from cron or a systemd service can still update the bar. The Borg
pill is not the center of the universe, despite its ambitions.

If `state.json` says `running` but `final.json` contains a finished archive with
the same archive name, Qreep treats the backup as successful. This is a guard
against interrupted shell wrappers and atomic state writes getting out of order.
Small mercy, but we take those.

Expected state shape:

```json
{
  "state": "running",
  "archive": "arch-adam-2026-07-01-145501",
  "profile": "work",
  "updatedAt": "2026-07-01T12:55:12Z",
  "message": "Starting Borg backup",
  "currentPath": "/home/adam/example",
  "files": 1234,
  "originalSize": 123456789,
  "compressedSize": 1234567,
  "deduplicatedSize": 12345
}
```

Terminal states use:

```json
{
  "state": "success",
  "archive": "arch-adam-2026-07-01-145501",
  "profile": "work",
  "finishedAt": "2026-07-01T12:58:12Z",
  "rc": 0
}
```

Supported states:

* `running` - opens/keeps the progress popup visible.
* `success` - shakes the pill, refreshes normal Borg status, waits two seconds,
  then hides the popup.
* `error` / `failed` - same as success, but styled as failure.

While `state` is `running`, `BorgService.qml` treats that state file as
authoritative and skips normal `borg-pulse` refreshes. `borg-pulse` checks the
latest archive and may fail while the backup command owns the Borg lock. That is
not a real backup failure; it is Borg saying “occupied, go bother someone else.”

The `profile` field should be `home`, `work`, or `unknown`. `borg-env` already
sets `BORG_TARGET`, and `borg-to-borg-backup` writes that value into the state
file.
