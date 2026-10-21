# Prism Module

Colours you picked or copied, the ones you keep, and the sets they belong in.

Every colour that passes through gets remembered: `SUPER+P` picks one with
hyprpicker (still copied to the clipboard, as before), and anything copied as
`#hex`, `rgb()`, `hsl()` or in Hyprland's notation (`rgba(97a8d1ff)`,
`rgb(2e3440)`, `0xaarrggbb`) is caught by a `wl-paste --watch`. Both land in
History. Favourites are the ones you pin.

Palettes are named sets of **combos**, and a combo is one or more colours
that belong together. A palette ("Color combos") shows its combos as small
posters; Enter opens one full size: one band per colour, lettered in the
combo colour that reads best on it, the way design accounts post colour
combos (Timberwolf on American Brown).

The **universe** is the editor (`Ctrl+E`, or "Open the universe" in the
colour menu): a hue ring with a saturation/value square inside, H S V A
sliders painted with what they change, the colour in every notation (click to
copy), and its harmonies: complementary, split complementary, analogous,
triadic, tetradic, monochromatic (one hue, contrast from lightness and saturation, the Timberwolf / American Brown kind), shades, tints. Click a harmony swatch to travel there
(double click copies it), ↺ returns to where you started, and "save as combo"
stores a whole harmony as a combo, named after it. Copy, favourite and
add-to-combo act on the colour you are editing.

## Use

`SUPER+SHIFT+P` toggles it. `SUPER+P` picks a colour without opening it.

| Key | Does |
| --- | --- |
| type | filter by name or hex |
| `↑↓←→` | move (`↑↓` in an open combo) |
| `Enter`, double click | copy the hex and close; on a palette, open the combo |
| click, `Ctrl+Enter` | actions: copy and close, copy, copy as `rgb()` / `hsl()` / `Qt.rgba()` / Hyprland `rgba(rrggbbaa)`, favourite, add to a combo, open the universe (step 2); `1`–`9` pick |
| `Shift+Enter` | copy, stay open |
| `Ctrl+S` | favourite / unfavourite |
| `Ctrl+P` | add the colour to a combo (the last one used comes first), a new combo, or a new palette |
| `Shift+Delete` | remove from this section; a combo goes on the second press |
| drag any colour box | (History / Favourites swatches, combo bands, the universe's preview, origin and harmony swatches) onto a sidebar combo: add it; onto a palette: a new combo with it; onto Favourites: favourite |
| `Ctrl+1` `Ctrl+2` `Ctrl+3` | Favourites, History, first palette |
| `Ctrl+↑` `Ctrl+↓` | previous / next in the sidebar, combos of unfolded palettes included |
| `Ctrl+→` `Ctrl+←` | unfold / fold the current palette in the sidebar |
| `Ctrl+N` | in a palette: new combo (opens it); elsewhere: new palette |
| `Ctrl+Shift+N` | new palette |
| `F2` / `Shift+F2` | rename the colour or combo / the palette |
| `Alt+arrows` | move the colour within its combo, or the combo within its palette |
| `Ctrl+Shift+Delete` | delete the palette (press twice) |
| `Ctrl+E` | open the universe on the colour |
| universe: `←→` `↑↓` | hue, value; `Alt+↑↓` saturation; `Shift` for ×10 |
| universe: type | jump to a typed colour (`#hex`, `rgb()`, `hsl()`, `rgba(rrggbbaa)`) |
| `F1` | shortcuts sheet |
| `Esc` | back out: menu, prompt, sheet, open combo, filter, then close |

The sidebar is a tree: a palette unfolds (▸ / ▾, or when you open it) to its
combos; click a combo to open it, double click to rename it.

Names: a new colour gets the nearest CSS colour name ("Saddle Brown"), so
the list is readable before you name anything. Rename it in a palette when
you know better.

## Storage

`~/Data/qreep/prism/prism.json`:

```json
{
  "version": 1,
  "history": [{ "hex": "#763948", "name": "Saddle Brown", "time": 0, "source": "clipboard" }],
  "favorites": ["#763948"],
  "palettes": [{
    "id": "p…", "name": "Color combos",
    "combos": [{ "id": "c…", "name": "Combo 1", "colors": [
      { "hex": "#d6ccd0", "name": "Timberwolf" },
      { "hex": "#763948", "name": "American Brown" }
    ] }]
  }]
}
```

History keeps one entry per colour (a repeat moves to the top), 500 at most.
Qreep is the only writer; edit the file with Qreep stopped, or not at all.
Palettes saved before combos (a flat `colors` list) load as one combo.

## IPC

```bash
quickshell ipc -c qreep call qreep-prism toggle
quickshell ipc -c qreep call qreep-prism pick
quickshell ipc -c qreep call qreep-prism showSection history
quickshell ipc -c qreep call qreep-prism showSection "Logo Idea Book"
quickshell ipc -c qreep call qreep-prism addCombo "Color combos" "#d6ccd0=Timberwolf #763948=American Brown"
quickshell ipc -c qreep call qreep-prism universe "#e9c46a"
quickshell ipc -c qreep call qreep-prism state
```

## Files

* `Prism.qml` - controller: IPC, open state, lazy panel on the focused monitor.
* `PrismService.qml` - store, picker, clipboard watcher, colour parsing and contrast.
* `PrismPanel.qml` - overlay: sidebar, swatch grid, combo grid, combo poster, prompts, keys.
* `PrismPoster.qml` - a combo as a small poster (palette grid).
* `PrismBand.qml` - one colour band: name, hex box, lettered in the combo's ink.
* `PrismUniverse.qml` - the editor: wheel, sliders, notations, harmonies.
* `PrismSlider.qml` - one painted channel slider.
* `PrismNames.qml` - nearest CSS colour name for new colours.
* `PrismTheme.qml` - paths, sizes, colours.
