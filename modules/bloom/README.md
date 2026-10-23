# Bloom Module

Qreep Bloom is the Unclaimed Bloom progress OSD.

It watches the same cache files as the AGS Bloom OSD:

```text
~/.cache/unclaimed-bloom/state.json
~/.cache/unclaimed-bloom/state-sow.json
~/.cache/unclaimed-bloom/state-grow.json
~/.cache/unclaimed-bloom/state-plant.json
~/.cache/unclaimed-bloom/current-wallpaper
~/.cache/unclaimed-bloom/current-profile
```

The module is hosted directly by `shell.qml`. It is not a bar feature. The bar
has enough hobbies.

The card is translucent (background alpha 0.75) so Hyprland can blur behind
it. The layer is a transparent top strip with namespace `qreep-bloom`; give it
`blur = true, ignore_alpha = 0.1` and only the card gets blurred.

## IPC

```bash
quickshell --path . ipc call qreep-bloom showBloom <profile> <wallpaper>
quickshell --path . ipc call qreep-bloom doneBloom
quickshell --path . ipc call qreep-bloom hideBloom
quickshell --path . ipc call qreep-bloom pickupBloom
quickshell --path . ipc call qreep-bloom toggle
quickshell --path . ipc call qreep-bloom showMe
quickshell --path . ipc call qreep-bloom hideMe
```

The file watcher is the important path. IPC is for manual nudges and for
`scripts/qreep-bloom-notify`, the wrapper that
`~/.config/unclaimed-bloom/notify.json` points at. It translates Unclaimed
Bloom's `bloom-show`, `bloom-done`, `bloom-hide`, and `bloom-pickup` into the
IPC calls above. `scripts/install` also copies it to `~/.local/bin`.
