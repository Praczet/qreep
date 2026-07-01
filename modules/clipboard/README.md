# Clipboard

`qreep-clipboard` is a shell-level clipboard picker backed by `clipvault`.

It is hosted directly by `shell.qml`, not by the bar. No bar button is planned.
The clipboard is opened through IPC and, eventually, a Hyprland binding. The bar
has enough things trying to become jewelry.

## Files

```text
modules/clipboard/
├── Clipboard.qml          # Scope/controller, IPC, open state, lazy panel
├── ClipboardPanel.qml     # bottom PanelWindow, search, grid, keyboard handling
├── ClipboardService.qml   # clipvault calls, filtering, restore/delete/pins
├── ClipboardCard.qml      # text/code/color/image card rendering
├── ClipboardTheme.qml     # sizes, colors, placement, timing
└── README.md
```

## Backend

Required commands:

```bash
clipvault
wl-copy
notify-send
```

Current backend behavior:

- `clipvault list` loads recent entries;
- `clipvault get | wl-copy` restores the selected entry;
- `clipvault delete` deletes the selected entry when supported by the backend;
- pins are stored as entry IDs in `~/.local/share/clipvault/pinned.json`;
- image previews are exported from `clipvault get` into `$XDG_RUNTIME_DIR/qreep-clipboard-previews`.

The exported image previews are runtime files, not a second clipboard database.
Do not make clipboard history durable in QML because a thumbnail looked lonely.

## IPC

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard show
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard hide
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard refresh
```

## Current Behavior

- bottom overlay panel;
- refreshes entries when shown;
- search filters immediately;
- pins filter shows starred entries only;
- pinned entries sort first;
- text, code, color, and image cards;
- image cards show runtime previews plus dimensions/mime metadata;
- Escape closes;
- outside click closes;
- Enter restores the selected card and closes the panel;
- restore success sends a notification:
  - title: `Qreep-Clipboard`;
  - body: `Image [id] copied`, `Text [id] copied`, `Code [id] copied`, or `Color [id] copied`;
  - icon: `edit-paste-symbolic`.

## Keyboard

- panel opens with search focused;
- `Down` or `Tab` moves focus from search into the card grid;
- arrow keys move selection in the grid;
- `Enter` restores the selected card;
- `Escape` closes the panel;
- `Ctrl+S` or `Alt+S` toggles star on the selected card;
- `Shift+Delete` deletes the selected card;
- printable typing while cards are focused returns focus to search and appends the typed character.

## Hyprland Binding

Suggested shape:

```ini
bind = CTRL SUPER, V, exec, quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard toggle
```

Adjust the config syntax to match whichever Hyprland config layer is currently
holding the steering wheel.

## Next Steps

These are follow-ups, not v1 blockers:

1. Watch image preview cost with large screenshot history. If it feels heavy, add deliberate thumbnail sizing/caching instead of creating a second clipboard store by accident.
2. Decide whether pins should become durable content later. Adam has seen `clipvault` prune old starred entries; solving that means privacy design, not a cute star icon with a database taped to it.
3. Consider a type-to-search overlay if the visible search row starts feeling too chunky.
4. Add richer image handling only if the simple runtime preview path proves too limited.
