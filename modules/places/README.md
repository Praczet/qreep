# Places

The project cockpit. Pick a project and see where it stands before you jump
in: git state, what changed, what the agents are doing in its questlog,
pinned docs, a few numbers. Then open it in your editor, launch the
dev-workspace cockpit, or drop into yazi or a terminal.

It replaces `~/.local/bin/places-rofi` for projects. Rofi can only show a
list of strings; this one can show a list of strings *and* their problems.

Top-level shell module, opened by IPC and `SUPER+SHIFT+P`. No bar button.

## Config

`~/.config/qreep/places.json`. The file is watched, so edits show up on the
next look without restarting Qreep. Minimum per project: a name and a path.

```json
{
  "defaultEditor": "nvim",
  "fileManager": { "command": ["yazi", "{path}"], "terminal": true },
  "editors": {
    "nvim": { "command": ["nvim", "{path}"], "terminal": true },
    "code": { "command": ["code", "{path}"] }
  },
  "groups": [
    {
      "name": "Work",
      "projects": [
        {
          "id": "eos",
          "name": "EOS",
          "path": "~/Development/work/projects/eos",
          "iconName": "eos-symbolic",
          "editor": "nvim",
          "pinned": ["docs/ai/STAFF-CHANGES-DESIGN.md"],
          "links": [{ "name": "Documentation", "path": "~/Documents/Projects/eos" }],
          "cockpit": ["~/.config/hypr/scripts/launch-dev-project.sh", "eos"]
        },
        { "name": "Scratch", "path": "~/Development/scratch" }
      ]
    }
  ]
}
```

| Field | Meaning |
| --- | --- |
| `name`, `path` | Required. `~` is expanded. |
| `id` | Stable key; defaults to the name. |
| `iconName` | Icon theme name. Looked up in the Qt icon theme, then in `~/.local/share/icons/ADArtWork/scalable/apps/` (`PlacesTheme.iconFallbackDir`). |
| `icon` | Nerd-font glyph when there is no icon file. Otherwise the first letter. |
| `editor` | Per-project editor key from `editors`; else `defaultEditor`. |
| `pinned` | Extra files, relative to the project. |
| `links` | Related folders, opened in the file manager. |
| `cockpit` | Command for Shift+Enter, run in the project folder. |

`{path}` is the file or folder being opened. Commands with `"terminal": true`
run in Qreep's terminal (`QreepTheme.terminal`, kitty) in the project folder.

## What it finds on its own

* **git**: branch, ahead/behind, changed count, last commit (all projects, on open).
* **README.md**: the first real paragraph, with headings, badges and HTML skipped.
* **Questlog**: `docs/ai/QUESTLOG.json`, `questlog.json` or `QUESTLOG.json`.
  Open quests first, step dots (filled = done/active/blocked, hollow = todo),
  blocked steps spelled out with who they wait on. Watched, so an agent's
  update shows up live.
* **Pinned**: `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/ai/CURRENT.md` when present.
* **Recently touched**: `fd --changed-within 14d`, which honours `.gitignore`.
* **Stats**: file count (`fd`), lines of code and top languages (`tokei`),
  commit count and commits per week for 13 weeks.

## Cost

Opening runs one short `sh` with a couple of `git` calls per project. The
detail read (git log, status, `fd`, `tokei`) runs only for the selected
project, after the selection has settled for 120 ms, so arrowing through
the list does not fork a small army. `tokei` results are cached per project
until Qreep reloads.

## Keys

| Key | Action |
| --- | --- |
| type | filter by name, id, group, path |
| `↑` `↓` `PgUp` `PgDn` | move |
| `Tab` / `Shift+Tab` | move the highlight through the buttons |
| `Enter` | run the highlighted button (the editor, unless you tabbed) |
| double click | open in the project's editor |
| `Shift+Enter` | cockpit (falls back to the editor) |
| `Ctrl+E` | open in the other editor |
| `Ctrl+O` | file manager |
| `Ctrl+T` | terminal in the project folder |
| `Ctrl+R` | re-read everything |
| `F1` | shortcuts sheet |
| `Esc` | close the sheet, clear the filter, then close |

Clicking a file row (uncommitted, recent, pinned) opens that file in the
editor. Chips do what they say.

## IPC

```bash
quickshell -c qreep ipc call qreep-places toggle
quickshell -c qreep ipc call qreep-places showMe
quickshell -c qreep ipc call qreep-places hideMe
quickshell -c qreep ipc call qreep-places refresh
quickshell -c qreep ipc call qreep-places showWith eos   # open with the filter typed
quickshell -c qreep ipc call qreep-places state
```

## Files

* `Places.qml` - controller: IPC, open state, service, lazy panel on the focused monitor.
* `PlacesService.qml` - config, summaries, details, questlog/README watching, launching.
* `PlacesPanel.qml` - overlay window, search, list, keys.
* `PlacesProjectRow.qml` - one list row with its group header.
* `PlacesDetail.qml` - the right pane.
* `PlacesQuests.qml`, `PlacesStats.qml` - questlog and stats cards.
* `PlacesSection.qml`, `PlacesChip.qml`, `PlacesFileRow.qml`, `PlacesIcon.qml` - small parts.
* `PlacesTheme.qml` - sizes, limits, colors, config path.

## Not yet

* Non-project places (Home, Notes, Admin), USB and Borg from `places-rofi`.
* A KIP `/p` command on the same service.
* Questlog as a dashboard block.
