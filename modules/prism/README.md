# Prism Module

Colours you picked or copied, the ones you keep, and the sets they belong in.

Every colour that passes through gets remembered: `SUPER+P` picks one with
hyprpicker (still copied to the clipboard, as before), and anything copied as
`#hex`, `rgb()` or `hsl()` is caught by a `wl-paste --watch`. Both land in
History. Favourites are the ones you pin. Palettes are named sets, shown as
posters: one band per colour, lettered in another colour of the same palette,
the way design accounts show colour combos (Timberwolf on American Brown).

Step 2, not built yet: the editor. Wheels, sliders, complementary / triadic /
analogous harmonies.

## Use

`SUPER+SHIFT+P` toggles it. `SUPER+P` picks a colour without opening it.

| Key | Does |
| --- | --- |
| type | filter by name or hex |
| `↑↓←→` | move (`↑↓` on a palette) |
| `Enter`, double click | copy the hex and close |
| `Shift+Enter` | copy, stay open |
| `Ctrl+S` | favourite / unfavourite |
| `Ctrl+P` | add to a palette (or a new one) |
| `Shift+Delete` | remove from this section (history, favourites, palette) |
| `Ctrl+1` `Ctrl+2` `Ctrl+3` | Favourites, History, first palette |
| `Ctrl+↑` `Ctrl+↓` | previous / next section |
| `Ctrl+N` | new palette |
| `F2` / `Shift+F2` | rename the colour (in a palette) / the palette |
| `Alt+↑` `Alt+↓` | move the colour within its palette |
| `Ctrl+Shift+Delete` | delete the palette (press twice) |
| `F1` | shortcuts sheet |
| `Esc` | back out: menu, prompt, sheet, filter, then close |

Names: a new colour gets the nearest CSS colour name ("Saddle Brown"), so
the list is readable before you name anything. Rename it in a palette when
you know better.

## Storage

`~/.local/share/qreep/prism.json`:

```json
{
  "version": 1,
  "history": [{ "hex": "#763948", "name": "Saddle Brown", "time": 0, "source": "clipboard" }],
  "favorites": ["#763948"],
  "palettes": [{ "id": "p…", "name": "Logo Idea Book", "colors": [{ "hex": "#d6ccd0", "name": "Timberwolf" }] }]
}
```

History keeps one entry per colour (a repeat moves to the top), 500 at most.
Qreep is the only writer; edit the file with Qreep stopped, or not at all.

## IPC

```bash
quickshell ipc -c qreep call qreep-prism toggle
quickshell ipc -c qreep call qreep-prism pick
quickshell ipc -c qreep call qreep-prism showSection history
quickshell ipc -c qreep call qreep-prism showSection "Logo Idea Book"
quickshell ipc -c qreep call qreep-prism newPalette "Logo Idea Book" "#d6ccd0=Timberwolf #763948=American Brown"
quickshell ipc -c qreep call qreep-prism state
```

## Files

* `Prism.qml` - controller: IPC, open state, lazy panel on the focused monitor.
* `PrismService.qml` - store, picker, clipboard watcher, colour parsing and contrast.
* `PrismPanel.qml` - overlay: sidebar, swatch grid, palette posters, prompts, keys.
* `PrismNames.qml` - nearest CSS colour name for new colours.
* `PrismTheme.qml` - paths, sizes, colours.
