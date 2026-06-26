# OSD Feature

## What It Does

Shows a Quickshell on-screen display message. It supports plain text and JSON
payloads through IPC. The left bar has a test button because sometimes the
fastest validation is poking the thing with a stick.

## Files

* `Osd.qml` - layer surface, positioning, display state, and animation.
* `OsdService.qml` - IPC handler, command runners, parsing, and OSD message
  construction.
* `OsdTestButton.qml` - bar test button.
* `OsdTheme.qml` - sizes, positions, durations, and colors.

## Where To Change Things

Change default position, duration, icon sizing, and panel dimensions in
`OsdTheme.qml`. Change IPC payload handling and backend command parsing in
`OsdService.qml`.

## Wiring

`shell.qml` hosts `Osd.qml`. `modules/bar/Bar.qml` hosts `OsdTestButton` and emits a
test request.

Note: This is a bar-owned feature. Sources live under `modules/bar/features/osd/`.

Theme is exposed through:

```qml
readonly property QtObject osd: OsdFeature.OsdTheme {}
```

## Service Notes

`OsdService.qml` exposes IPC target `osd`:

```bash
quickshell ipc call osd showMessage "Message" 3000
```

JSON payloads may include `message`, `durationMs`, `position`, `title`, `icon`,
`icon`, `iconSize`, and `progress`.

Progress and system-control helpers are also exposed:

```bash
quickshell ipc call osd osdVolume "" ""
quickshell ipc call osd osdMic "" ""
quickshell ipc call osd osdBrightness 75
quickshell ipc call osd osdPlayer play-pause
```

Volume and microphone calls may receive explicit values and mute state. Without
explicit values, the service asks `wpctl` for the current default sink/source.
Player calls ask `playerctl` for metadata. Tiny command wrappers: useful until
they grow teeth.
