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
| `description` | One line for the header. Without it: first paragraph of `README.md`, else of `AGENTS.md`, else nothing. |
| `pinned` | Extra files, relative to the project. |
| `links` | Related folders, opened in the file manager. |
| `cockpit` | Command for Shift+Enter, run in the project folder. |
| `enabled` | `false` hides the project (or a whole group) without deleting it. Missing means on. |

Top-level `"tips": { "enabled": true, "items": ["..."] }` adds your own tips
to the built-in ones (`PlacesTips.qml`), or turns the tip card off with
`"enabled": false`. Tips are Markdown (`**bold**`, `` `code` ``).

`{path}` is the file or folder being opened. Commands with `"terminal": true`
run in Qreep's terminal (`QreepTheme.terminal`, kitty) in the project folder.

## Places and blocks

A group can hold `"places"` next to (or instead of) `"projects"`. A place is a
page made of blocks and needs no folder; give it a `path` and it also gets
Folder / Terminal buttons. Projects take `"blocks"` too: they show up after
the file cards. Every block takes `"enabled": false` and an optional `"title"`.

```json
{ "name": "Places", "places": [ {
    "id": "home", "name": "Home", "icon": "󰋜",
    "description": "Admin, notes, and the apps I actually open.",
    "blocks": [
      { "type": "apps", "items": ["zen", "slack", "kitty"] },
      { "type": "documents", "title": "Admin papers", "items": ["~/Documents/Admin/tax.pdf"] },
      { "type": "folders", "items": [{ "name": "Notes", "path": "~/Notes" }, "~/Downloads"] }
    ] } ] }
```

| Block | Items | Enter / click |
| --- | --- | --- |
| `apps` | desktop entry ids (`zen`, `org.gnome.Calculator`, `.desktop` optional) | launch (Terminal=true apps run in kitty) |
| `documents` | paths, or `{ "name", "path" }` | Open with chooser; documents and images put "default app" first |
| `folders` | paths, or `{ "name", "path" }` | folder chooser: yazi, terminal here, broot, copy path |
| `folder` | none; `"path"`, `"sort"` (`name` / `modified`), `"limit"`, `"hidden"` | lists the folder's contents, subfolders first; folder chooser or Open with |
| `usb` | none | Open (mounts if needed, yazi), Terminal, Mount / Unmount, Eject (unmount + power off) |
| `smb` | `"shares": [{ "name", "url": "smb://host/share", "user", "domain" }]` | Open (mounts if needed, yazi), Terminal, Mount / Unmount, Change / Forget password |
| `ssh` | none (every `~/.ssh/config` host), or host names / `{ "name", "host", "user", "port" }`; `"exclude"` | a terminal running `ssh <host>` |

`ssh` without items reads `~/.ssh/config` (watched): wildcard patterns and
git forges (`User git`, github / gitlab / bitbucket / codeberg) are skipped,
since they give no shell. ssh itself still reads the config, so a listed
host only needs its name.
| `calendar` | none; `"days"` (default 2), `"limit"` (default 10) | opens the event page (Google events have one) |
| `todos` | none; `"states"` (default NOW, DOING, TODO, LATER), `"limit"` | KIP's markdown chooser: Logseq page, nvim at the line, Vivify |

`calendar` reads the same files as the bar clock: repo `events.json`,
`~/.cache/qreep/calendar/events.json` (Google) and `microsoft-events.json`.
Events that already ended or were cancelled are skipped; the list groups by
Today / Tomorrow / day. `todos` runs `rg` over the Logseq graph
(`KipTheme.logseqGraphDir`, journals and pages) for `- TODO` style lines,
NOW/DOING first, newest journal first; read-only, ticking them off stays in
Logseq. Both follow their data while Places is open.

Paths are absolute, `~/…`, or relative to the entry's own `path`. Blocks fill
two columns masonry-style: each goes to the shorter column (heights estimated
from contents), in config order. `"wide": true` gives a block the full width
and starts a fresh pair of columns below it. `"hideWhenEmpty": true` hides a
live block while it has nothing to show; `usb` does that by default.

A place's header line summarises the page: events left today and the next
one, todo count, mounted shares, plugged-in drives, reachable SSH hosts.
SSH hosts get a green icon when their ssh port answers (one TCP connect per
host when Places opens, address and port from `ssh -G`, no login), dim when
not. A folder listing longer than its `limit` ends in "+ N more", which opens
the folder. Cards are numbered in reading
order for `Alt+1`…`Alt+9` (a project's four file cards first, then its
blocks), and Tab walks them after the buttons. In an apps card ←→ move
along the row and ↑↓ change card. `smb` mounts through GVFS (`gio mount`). The password lives only in GNOME
Keyring, under `service=qreep-places-smb url=smb://host/share/`
(`secret-tool lookup service qreep-places-smb url …` shows it, `Forget
password` deletes it). With no saved password, gio gets no input, so a login
GVFS saved itself still works; if the server asks anyway, Places shows a
password dialog. The password reaches `sh` and `secret-tool` on stdin, never
on a command line, and never touches places.json or a log.

Nothing else is planned right now; an unknown type shows a card saying so.

## What it finds on its own

* **git**: branch, ahead/behind, changed count, last commit (all projects, on open).
* **Description**: the first real paragraph of `README.md` (or `AGENTS.md`
  when there is no README), headings, badges and HTML skipped. A config
  `description` wins.
* **Questlog**: `docs/ai/QUESTLOG.json`, `questlog.json` or `QUESTLOG.json`.
  Open quests first, step dots (filled = done/active/blocked, hollow = todo),
  blocked steps spelled out with who they wait on. Watched, so an agent's
  update shows up live.
* **Pinned**: `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/ai/CURRENT.md` when present.
* **Recently touched**: `fd --changed-within 14d`, which honours `.gitignore`.
* **Docs**: `docs/`, two levels deep (`.md`, `.txt`, `.pdf`, `.html`), newest first.
* **Activity**: a year of commits as a GitHub-style grid, one column per
  week, one row per weekday, darker = busier day.
* **Stats**: file count (`fd`), lines of code and top languages (`tokei`),
  total commits, doc count.

Lists (uncommitted, recent, docs, commits) show as many rows as the pane has
room for: between `minListRows` and `maxListRows` in `PlacesTheme.qml`.

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
| `Tab` / `Shift+Tab` | move through the buttons, then the file cards that have files, then around again |
| `Enter` | run the highlighted button (the editor, unless you tabbed) |
| double click | open in the project's editor |
| `Shift+Enter` | cockpit (falls back to the editor) |
| `Ctrl+E` | open in the other editor |
| `Ctrl+O` | file manager |
| `Ctrl+T` | terminal in the project folder |
| `Ctrl+R` | re-read everything |
| `Ctrl+/` | find anything clickable on this page (fuzzy); the card you were in ranks first; `↑↓` next match, `Enter` open, `Esc` back |
| `Ctrl+1` … `Ctrl+9`, `Ctrl+0` | select the 1st … 10th entry in the list, places and projects alike; each row shows its key |
| `Alt+1` … `Alt+9` | jump into a card: a project's Uncommitted, Pinned, Recently touched, Docs, then blocks; a place's blocks |
| in a card: `↑` `↓` / `←` `→` | move between files / to the next card |
| in a card: `Enter` | "Open with" chooser for that file |
| in a card: `Esc` | back to the project list (typing does that too) |
| `F1` | shortcuts sheet |
| `Esc` | close the sheet, clear the filter, then close |

Clicking a file row (uncommitted, recent, docs, pinned) opens KIP's "Open
with" chooser with KIP's file actions (`KipTheme.fileActions`): nvim first,
Vivify for markdown, then the default app, its folder in yazi, a terminal in
its folder, and copy path. The panel behind the chooser is blurred.
The order is decided in three steps: an extension guess right away
(documents and images: their app first), then `xdg-mime` a moment later
(text types such as `.conf`, `.log` or JSON: nvim first; anything else: its
every app whose desktop entry lists the type, the default first and marked
so, each launched with `gio launch <app.desktop> <file>`), and
finally whatever you picked last for that file type goes on top. The
chooser shows two groups: "Open with" (the apps) and "Actions" (nvim, Vivify,
folder in yazi, terminal there, copy path). Text files list Actions first,
everything else Open with first; a remembered choice brings its group up.
Only the default app (and a remembered one) gets a number key; the other
"can open it" apps are reached with the arrows, so nvim and the actions keep
low numbers. Those
choices live in `~/.local/state/qreep/places-openers.json` (extension, or
mime type for files without one -> option id); delete a line to forget it.
`1`–`9` or `↑↓` + `Enter` pick, `Esc` cancels. Copy path keeps Places open;
everything else closes it.

## IPC

```bash
quickshell -c qreep ipc call qreep-places toggle
quickshell -c qreep ipc call qreep-places showMe
quickshell -c qreep ipc call qreep-places hideMe
quickshell -c qreep ipc call qreep-places refresh
quickshell -c qreep ipc call qreep-places showWith eos   # open with the filter typed
quickshell -c qreep ipc call qreep-places showProject eos   # open with that project selected
quickshell -c qreep ipc call qreep-places state
```

## Tips and KIP

A tip card sits under the project list: a random tip each time Places opens,
click it for the next. KIP's `/p eos` lists the same projects (same service)
and opens Places on one; Shift+Enter there goes straight to the cockpit.
`/ssh` lists the hosts of the ssh blocks (`sshHosts` on the service) and
connects with `kitten ssh`, like Enter on an ssh card.

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
