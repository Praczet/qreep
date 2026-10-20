# Wallpaper Module

Qreep's wallpaper picker. It replaces the rofi menu that Unclaimed Bloom's
`wallset` used to open: you pick here, and `wallset <path>` still does the
real work (sow, grow, `awww`, plant), with the Bloom OSD showing progress.

Rofi had icons. This has opinions.

## Use

`SUPER+T` toggles it (Hyprland `binds.lua`). Running `wallset` without a
path opens it too, when Qreep is up.

| Key | Does |
| --- | --- |
| type | filter by file name (every word must match) |
| `↑↓←→` | move (grid); `↑↓` in the list |
| `PgUp` `PgDn` | a page at a time |
| `Enter`, double click | apply: `wallset <path>`, then the picker closes |
| `Ctrl+B` / `Ctrl+Shift+B` | next / previous Unclaimed Bloom profile (used on apply) |
| `Ctrl+P` | grid ↔ list |
| `Ctrl+1` … `Ctrl+4` | tile size S / M / L / XL (switches to the grid) |
| `Ctrl++` `Ctrl+=` / `Ctrl+-` `Ctrl+_` | bigger / smaller tiles |
| `F1` | shortcuts sheet |
| `Esc` | close the sheet, clear the filter, then close |
| `Ctrl+Esc` | close |

The chips in the search bar do the same with the mouse.

## Bloom profile

The chip left of the filter picks the Unclaimed Bloom **composition** the
wallpaper is applied with (`desktop-graphite-tweak`, `desktop-graphite-blooming`,
…). Only compositions are listed: they theme the whole desktop, GTK included;
a plain profile like `daily-gtk` would plant one target and look broken.

Choosing does nothing on its own. `Enter` runs `spore profile use <profile>`
and then `wallset <path>`, so the switch and the regrow happen together; `Esc`
leaves the active profile alone. The chip lights up while the choice differs
from the active profile, the preview says which profile Enter will use, and
every open starts from the active one again (`~/.cache/unclaimed-bloom/current-profile`).
`Enter` on the current wallpaper re-themes it with the chosen profile. The view and size
are remembered in `~/.local/state/qreep/wallpaper.json`. The picker opens on
the current wallpaper (`~/.cache/unclaimed-bloom/current-wallpaper`).

## Views

| View | Tile | Thumbnail | Preview pane |
| --- | --- | --- | --- |
| List | 96 px wide, with size and resolution | 400 | yes |
| S | 160×120 | 400 | yes |
| M | 240×180 | 400 | yes |
| L | 400×300 | 400 | no |
| XL | 800×600 | 800 | no |

Images are letterboxed, never cropped: an ultrawide stays an ultrawide. The
preview pane shows the 800 thumbnail (800×600 at most) where tiles are too
small to judge.

## Thumbnails

`wallpaper-thumbs` (next to the QML) does the file work:

```bash
wallpaper-thumbs list  ~/.config/backgrounds ~/.cache/qreep/wallpapers   # instant, TSV
wallpaper-thumbs build ~/.config/backgrounds ~/.cache/qreep/wallpapers   # missing/stale only
```

`build` runs every time the picker opens, in the background and in parallel
(`nproc` ImageMagick jobs). It makes `800/<name>.jpg` (fits 800×600) from the
image, `400/<name>.jpg` from that, and `800/<name>.dim` with the source size,
so listing never decodes an image. A thumbnail older than its image is
remade; thumbnails without an image are removed. The first run for ~100
5K wallpapers takes about 10 s; the footer counts it, and tiles fill in when
it is done.

## Config

`WallpaperTheme.qml`: `wallpaperDir` (`$UB_WALLPAPER_DIR`, else
`~/.config/backgrounds`, same as `wallset`), `thumbnailDir`, `applyCommand`
(`~/.local/bin/wallset`), tile sizes, panel sizing and colors.

## IPC

```bash
quickshell ipc -c qreep call qreep-wallpaper toggle
quickshell ipc -c qreep call qreep-wallpaper showMe
quickshell ipc -c qreep call qreep-wallpaper hideMe
quickshell ipc -c qreep call qreep-wallpaper showWith city
quickshell ipc -c qreep call qreep-wallpaper setView grid xl
quickshell ipc -c qreep call qreep-wallpaper refresh
quickshell ipc -c qreep call qreep-wallpaper state
```

## Files

* `Wallpaper.qml` - controller: IPC, open state, lazy panel on the focused monitor.
* `WallpaperService.qml` - listing, thumbnail builds, current wallpaper, view state, apply.
* `WallpaperPanel.qml` - overlay, search, grid / list, preview, keys.
* `WallpaperThumb.qml` - one letterboxed thumbnail with placeholder and current badge.
* `WallpaperChip.qml` - view and size toggles.
* `WallpaperTheme.qml` - paths, sizes, colors.
* `wallpaper-thumbs` - the thumbnail worker.

## Not yet

* Profile switch (daily, daily-light, ...) next to the view chips.
* KIP `/wall` on the same service.
