# Potato Fast Feature

## What It Does

Shows fasting progress as the first center-slot bar pill using
`potato-fast --json`. Waybar had this as a text custom module. Qreep keeps the
useful command and replaces the block-character progress bar with a small real
fill bar, because we have pixels now and should probably use them.

## Files

* `PotatoFastButton.qml` - bar pill, icon, elapsed/remaining label, progress fill, tooltip wiring.
* `PotatoFastService.qml` - polls `potato-fast --json`, parses the status JSON, and exposes IPC refresh.
* `PotatoFastTheme.qml` - command, refresh interval, sizing, and status colors.

## Wiring

`modules/bar/Bar.qml` creates `PotatoFastService` and passes it to
`PotatoFastButton`. The button sits in the center slot before `Clock` and
`MprisButton`.

The runtime pill ID is:

```text
potato-fast
```

Use the normal bar pill IPC if the pill needs to be hidden or pinned:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar-pill togglePill potato-fast
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar-pill togglePinned potato-fast
```

Refresh the backend manually with:

```bash
quickshell ipc -c qreep call qreep-potato-fast refresh
```

That refresh also pulses the pill so there is visible proof that the command
landed. Not a parade. Just enough movement to avoid guessing.

## Backend Contract

The service expects `potato-fast --json` to print one JSON object. The useful
fields are:

```json
{
  "class": "active",
  "state": "active",
  "percentage": 63,
  "timeStr": "10h 05min",
  "remainingStr": "5h 55min",
  "tooltip": "Fasting details"
}
```

The backend can change shape later. That is fine. Keep it JSON and let Qreep
render the status like a bar, not a terminal pretending to be one.

## Sync Hook

`potato-sync` writes the POTATO cache and then calls:

```bash
quickshell ipc -c qreep call qreep-potato-fast refresh
```

The live helper at `~/.local/bin/potato-sync` runs the built POTATO entry point
from `~/Development/potato/dist/main.js`, so rebuild POTATO after changing the
hook:

```bash
cd ~/Development/potato
npm run build
```

The hook is best-effort. If Qreep is not running, sync still succeeds and the
next poll catches up. Environment knobs:

```text
POTATO_QREEP_REFRESH=0      disable Qreep refresh
POTATO_QREEP_CONFIG=qreep   choose Quickshell config target
POTATO_QREEP_PATH=/path     use a path target instead of config
```
