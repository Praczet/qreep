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
quickshell ipc --path . call qreep-bloom showBloom <profile> <wallpaper>
quickshell ipc --path . call qreep-bloom doneBloom
quickshell ipc --path . call qreep-bloom hideBloom
quickshell ipc --path . call qreep-bloom pickupBloom
```

The file watcher is the important path. IPC is mainly for manual nudges or a
future notify wrapper if `~/.config/unclaimed-bloom/notify.json` moves from AGS
to Qreep.
