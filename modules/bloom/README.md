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

## IPC

```bash
quickshell --path . ipc call qreep-bloom showBloom <profile> <wallpaper>
quickshell --path . ipc call qreep-bloom doneBloom
quickshell --path . ipc call qreep-bloom hideBloom
quickshell --path . ipc call qreep-bloom pickupBloom
quickshell --path . ipc call qreep-bloom showMe
quickshell --path . ipc call qreep-bloom hideMe
```

The file watcher is the important path. IPC is mainly for manual nudges or a
future notify wrapper if `~/.config/unclaimed-bloom/notify.json` moves from AGS
to Qreep.
