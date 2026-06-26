# Dashboard Module

Qreep dashboard is a top-level shell surface, not a bar-owned popup.

The first draft is deliberately fake: it loads configured blocks and proves the
canvas, card sizing, positioning, title/chrome flags, and entry animation. Real
blocks can arrive after the surface stops doing interpretive dance.

## IPC

```bash
quickshell ipc call qreep-dashboard toggle
quickshell ipc call qreep-dashboard show
quickshell ipc call qreep-dashboard hide
quickshell ipc call qreep-dashboard refresh
```

## Config

The draft config lives at:

```text
modules/dashboard/dashboard.json
```

This is repo-local for now so it can be reviewed with the module. User config can
move to `~/.config/quickshell/qreep/dashboard.json` once the schema is less
likely to change every time someone looks at it funny.

## Hyprland

Layer namespace:

```text
qreep-dashboard
```

Blur belongs in Hyprland layer rules. QML should control the overlay opacity and
card surfaces; Hyprland can do the blur without QML pretending to be a compositor
with hobbies.
