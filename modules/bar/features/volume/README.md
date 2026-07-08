# Volume Feature

## What It Does

Shows output volume state in the right bar slot. Left click toggles sink mute,
scroll changes sink volume, and right click opens `pavucontrol`.

Volume state itself lives in `core/SoundService.qml` so OSD and future audio
surfaces can share the same PipeWire state instead of each asking the desktop a
slightly different question.

## Files

* `VolumeButton.qml` - bar pill, click/scroll handling, tooltip wiring.
* `VolumeTheme.qml` - icon sizing and spacing.
* `core/SoundService.qml` - shared PipeWire sink/source state and controls.

## Wiring

`modules/bar/Bar.qml` creates `core/SoundService`, passes it to `VolumeButton`,
opens `pavucontrol` on right click, and forwards volume feedback to
`modules/osd/Osd.qml` through `shell.qml`.

This is a bar-owned feature, with shared audio state in `core/`.

Theme is exposed through:

```qml
readonly property QtObject volume: VolumeFeature.VolumeTheme {
    qreep: rootBarTheme.qreep
}
```

## Service Notes

`SoundService.qml` uses:

```qml
import Quickshell.Services.Pipewire
```

It exposes sink/source volume, mute state, labels, icons, and helper methods for
changing volume or mute state. `VolumeButton.qml` currently uses the sink side.

There is no IPC target for volume yet. Use the bar control or OSD helper paths.
