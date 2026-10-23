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
├── clipboard-pins         # pin store: pin / unpin / restore / list / migrate
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
- pins are copies of the content in `~/.local/share/qreep/clipboard-pins/`
  (`index.json` plus one file per pin), made by the `clipboard-pins` worker
  next to the QML. clipvault prunes old entries and renumbers its ids, so the
  old id-only `pinned.json` lost pins; it is migrated once (whatever clipvault
  still had) and renamed `pinned.json.migrated`. Restoring a pin runs
  `wl-copy` from the file; deleting a pin unpins it; a history entry with the
  same preview as a pin is hidden behind the pin;
- image previews are exported from `clipvault get` into `$XDG_RUNTIME_DIR/qreep-clipboard-previews`.

The exported image previews are runtime files, not a second clipboard database.
Do not make clipboard history durable in QML because a thumbnail looked lonely.

## IPC

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard showMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard hideMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard refresh
```

## Current Behavior

- bottom overlay panel;
- refreshes entries when shown;
- search filters immediately;
- pins filter shows starred entries only;
- type filters narrow results to image, text, code, and color entries;
- pinned entries sort first;
- text, code, color, and image cards; colour cards also read Hyprland's `rgba(rrggbbaa)`, `rgb(rrggbb)` and `0xaarrggbb`, and `#rrggbbaa` is drawn in the right channel order (Qt itself reads 8-digit hex as `#aarrggbb`);
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
- `Escape` closes the F1 sheet, then the panel;
- `F1` toggles the shortcuts sheet (above the panel);
- `Ctrl+1` pins only, `Ctrl+2` … `Ctrl+5` image, text, code, color filters (same order as the header buttons, each toggles);
- `Ctrl+S` or `Alt+S` toggles star on the selected card;
- `Shift+Delete` deletes the selected card (unpins a pin);
- printable typing while cards are focused returns focus to search and appends the typed character.

## Hyprland Binding

Adam's current binding is `SUPER+SHIFT+V`, in the Lua config:

```lua
A.exec(mainMod .. " + SHIFT + V", "Clipboard manager (qreep)", qreep .. " ipc call qreep-clipboard toggle")
```

The plain hyprland.conf shape, if that layer comes back:

```ini
bind = SUPER SHIFT, V, exec, quickshell -c qreep ipc call qreep-clipboard toggle
```

Adjust the config syntax to match whichever Hyprland config layer is currently
holding the steering wheel.

## Next Steps

These are follow-ups, not v1 blockers:

1. Watch image preview cost with large screenshot history. If it feels heavy, add deliberate thumbnail sizing/caching instead of creating a second clipboard store by accident.
2. Pins are durable now, which also means a pinned secret sits in plain files under `~/.local/share/qreep/clipboard-pins/` until it is unpinned. Pin passwords and tokens at your own risk; Fast Password exists for those.
3. Consider a type-to-search overlay if the visible search row starts feeling too chunky.
4. Add richer image handling only if the simple runtime preview path proves too limited.
