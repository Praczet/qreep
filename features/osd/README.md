# OSD Feature

## What It Does

Shows a Quickshell on-screen display message. It supports plain text and JSON
payloads through IPC. The left bar has a test button because sometimes the
fastest validation is poking the thing with a stick.

## Files

* `Osd.qml` - layer surface, IPC handler, positioning, and animation.
* `OsdTestButton.qml` - bar test button.
* `OsdTheme.qml` - sizes, positions, durations, and colors.

## Where To Change Things

Change default position, duration, icon sizing, and panel dimensions in
`OsdTheme.qml`. Change IPC payload handling in `Osd.qml`.

## Wiring

`shell.qml` hosts `Osd.qml`. `panels/Bar.qml` hosts `OsdTestButton` and emits a
test request.

Theme is exposed through:

```qml
readonly property QtObject osd: OsdFeature.OsdTheme {}
```

## Service Notes

`Osd.qml` exposes IPC target `osd`:

```bash
quickshell ipc call osd showMessage "Message" 3000
```

JSON payloads may include `message`, `durationMs`, `position`, `title`, `icon`,
and `iconSize`.
