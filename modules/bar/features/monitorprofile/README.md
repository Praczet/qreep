# MonitorProfile Feature

## What It Does

Shows the active monitor layout as compact display icons. External displays use
`󰍹`; internal displays use `󰌢`. The service sorts monitors by layout position
before rendering, because unordered monitor icons are a small crime.

## Files

* `MonitorProfileButton.qml` - bar pill.
* `MonitorProfileService.qml` - watches runtime JSON and derives display text.
* `MonitorProfileTheme.qml` - icon size and pulse animation tokens.

## Where To Change Things

Change icon sizes and animation timings in `MonitorProfileTheme.qml`. Change
JSON interpretation, sorting, tooltip text, or icon mapping in
`MonitorProfileService.qml`.

## Wiring

`modules/bar/Bar.qml` creates `MonitorProfileService` and passes it to
`MonitorProfileButton`.

Note: This is a bar-owned feature. Sources live under `modules/bar/features/monitorprofile/`.

Theme is exposed through:

```qml
readonly property QtObject monitorProfile: MonitorProfileFeature.MonitorProfileTheme {}
```

## Service Notes

The service reads:

```text
${XDG_RUNTIME_DIR:-/tmp}/hypr-monitor-profile-qreep.json
```

QML does not expand that shell expression, so the service uses:

```qml
Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
```

It exposes IPC:

```bash
quickshell ipc call qreep-monitor-profile refresh
quickshell ipc call qreep-monitor-profile update
```

The expected JSON has `profile`, `reason`, `detail`, and a `layout` array with
positions and display metadata.
