# KIP

KIP (Knowledge & Intelligence Presence) is a summonable prompt that shows up
as a thin line, drops to just under the bar, turns into an input box, and
unfolds the rest of itself around that box. It reacts to slash commands while
you type and has opinions in its status line.

KIP is the front end. `~/.local/bin/jarvis` is the backend and stays its own
tool: KIP runs it, reads its JSON, and never touches the index or Ollama
directly. `KipMockService.qml` is kept for UI work without Ollama; the header
says `Local AI · mock` when it is active.

## Files

```text
modules/kip/
├── Kip.qml            # Scope/controller: IPC, open state, lazy panel, focused screen
├── KipPanel.qml       # PanelWindow: open/close motion, layout, routing to commands
├── KipHeader.qml      # title row, Help chip, backend status chip
├── KipInput.qml       # input box: icon, flag chips, command highlight, Enter hint
├── KipAnswerView.qml  # answer/doc viewer: throttled render, follow, Copy links
├── KipCommands.qml    # command registry + parse(text)
├── KipMessages.qml    # event-keyed microcopy, picked on state entry
├── KipJarvisService.qml # Jarvis adapter: argv, JSON/NDJSON parsing, cancellation
├── KipMockService.qml # fake search/ask/general, Jarvis-shaped event sequence
├── KipScreenshotService.qml # /last: newest files in the screenshot folder
├── KipShotsCommand.qml # /last in the panel: count, live refresh, grid keys
├── KipFileSearchService.qml # /fd: two fd passes, merged and ranked
├── KipFilesCommand.qml # /fd in the panel: debounce, flag complaints, selection
├── KipTldrService.qml # /tldr: pages from the local tldr cache
├── KipCalcService.qml # /calc: qalc, offline
├── KipDictService.qml # /def: sdcv (StarDict), offline
├── KipWindowService.qml # /win: hyprctl clients, focus via Expose
├── KipWindowView.qml  # /win: grid/list of icons or live previews
├── KipWindowsCommand.qml # /win in the panel: selection, Ctrl+L/Ctrl+P, focus
├── KipQreepService.qml # /qreep: quickshell ipc show/call for this process
├── KipQreepCatalog.qml # /qreep: labels, groups, icons, what is listed
├── KipQreepList.qml   # /qreep: grouped rows with icons
├── KipQreepCommand.qml # /qreep in the panel: Tab completion, calling, Ctrl+H
├── KipGrepService.qml # /rg: ripgrep --json, capped, path:line hits
├── KipGrepCommand.qml # /rg in the panel: debounce, flag complaints, selection
├── KipBrowseService.qml # /browse: one folder via fd, local filter, preview bytes
├── KipBrowsePreview.qml # /browse: Alt+P preview pane
├── KipBrowseCommand.qml # /browse in the panel: input-as-path, Tab/Alt keys
├── KipAppService.qml  # launcher: desktop entries, grouping, search, launch log
├── KipAppView.qml     # launcher: toolbar + sectioned grid/list, spatial keys
├── KipTimerCommand.qml # /timer: plan + preview against the Qreep timer
├── KipRunService.qml  # /run: rofi-runner history, terminal/background decision
├── KipRunCommand.qml  # /run in the panel: history picking, preview, danger arm, keys
├── KipChooser.qml     # numbered action chooser shared by every result type
├── KipShortcuts.qml   # Ctrl+/ keys sheet, current group first
├── KipShotGrid.qml    # /last thumbnails
├── KipResultList.qml  # ranked hits: origin, folder, basename, line range
├── KipMarkdown.qml    # answer Markdown → KIP-styled Qt rich text
├── KipTheme.qml       # placement, timings, reducedMotion, tone, colors
└── README.md
```

`*Service.qml` runs the tool; `*Command.qml` is that command's behaviour in
the panel (selection, timers, keys, status line, Enter). Commands get the
panel as `host` and use `contentState`, `parsed`, `notice`, `setInput()`,
`backToCompose()` and the chooser functions; `*View.qml`, `KipHeader` and
`KipInput` only draw and emit signals. A new command with its own view gets a
`*Command.qml` and one line in `KipPanel.activeCommand`.

## IPC

```bash
quickshell -c qreep ipc call qreep-kip toggle
quickshell -c qreep ipc call qreep-kip showMe
quickshell -c qreep ipc call qreep-kip hideMe
quickshell -c qreep ipc call qreep-kip showWith "/run "     # open with the input already typed
quickshell -c qreep ipc call qreep-kip toggleWith "/run "   # same; closes if already on /run
quickshell -c qreep ipc call qreep-kip state   # open, phase, view, input, service, results, error, backend
quickshell -c qreep ipc call qreep-kip setBackend mock     # or jarvis
quickshell -c qreep ipc call qreep-kip run "/notes MariaDB permissions"  # no panel needed
```

`run` exists for testing the backend path headlessly; poll `state` afterwards.

`showWith`/`toggleWith` put the text in the input exactly as if typed, so any
command works (`"/browse ~/"`, `"/win "`, `""` for the launcher). Keep the
trailing space for commands that preview live. `toggleWith` closes KIP when
the input already starts with that command, and switches to it otherwise.

## Backend

| KIP input | Jarvis call | Output |
| --- | --- | --- |
| `/notes <q>` | `jarvis --json -search-notes=<q>` | one JSON object (`notes.search.results`) |
| `/notes-ask <q>` | `jarvis --json -ask-notes=<q>` | NDJSON: `response.start`, `response.sources`, `response.delta`…, `response.done` |
| `/ask <q>` | `jarvis --json -- <q>` | same NDJSON, no sources |

Details that were verified against the installed Jarvis on 2026-10-15:

- The `=` / `--` forms are deliberate. `jarvis -ask-notes "-x"` makes argparse
  treat the question as a flag. Arguments are argv items; no shell anywhere.
- Jarvis reports its own failures as `{"type":"response.error"}` on stdout and
  exits 1. Argparse failures go to stderr with exit 2. KIP handles both.
- Search always returns its top 8 chunks, even for gibberish. Hits below
  `KipTheme.weakSimilarity` (0.25) are dimmed and the message says so. The
  number on each row is that similarity, not Jarvis's blended score, so
  "weak" and the number always agree.
- Chunks from the same file are folded into one row with every line range;
  Enter opens the best one.
- `SOURCE n` citations in an answer are rewritten to `[n · file:start–end]`
  from the real source list.

Each request gets its own `Process`. A new request, Escape, editing the text,
or closing KIP kills the old process (checked with `pgrep`) and its late
output is ignored by request id.

Error states, each with its own message:

| Error | Cause |
| --- | --- |
| Ollama unavailable | `Cannot reach Ollama` / `Ollama HTTP` from Jarvis |
| index problem | no index, model changed, vector dimensions changed |
| malformed reply | non-JSON on stdout |
| jarvis failed | non-zero exit with no JSON error |
| jarvis not found | `backendCommand` is not on Quickshell's PATH |

Enter retries after an error.

Hyprland bind (lives in `~/.config/hypr/modules/binds.lua`, not here):

```lua
A.exec(mainMod .. " + K", "KIP (qreep)", qreep .. " ipc call qreep-kip toggle")
```

## Motion

All open/close geometry derives from one number, `openProgress` (0 → 1):

| Slice | Phase | What moves |
| --- | --- | --- |
| `0 → signalEnd` | signal | input box fades in at the top edge (`signalTopY`) |
| `signalEnd → descendEnd` | descend | input box slides down to `anchorY` |
| `descendEnd → 1` | assemble | header up, icon left, status right, body down |

Closing animates the same number back to 0, faster. A toggle mid-animation just
reverses direction, so there is no state machine to wedge. Content state
(`ready → processing → results/error`) is separate from motion.

The input box is full size from the first frame and has keyboard focus, so
you can type while it is still sliding in.

`KipTheme.reducedMotion: true` skips the theatre and snaps open/closed.

The panel picks the Hyprland-focused monitor when it opens. Sizes are logical
pixels, so `anchorY` (100) and `panelWidth` (780, clamped to the screen) follow
monitor scaling.

## Answers

Answers are Markdown from the model, converted by `KipMarkdown.qml` into Qt
rich text with KIP's own spacing (`answer*` tokens in `KipTheme.qml`) and
shown in one read-only `TextEdit`, so a mouse selection can span the whole
answer. Qt's built-in Markdown mode rendered, but gave no control over
spacing or code blocks.

- Supported: paragraphs, headings (restrained sizes), nested lists, fenced
  and inline code, bold/italic, `http(s)` links, blockquotes, rules. Model
  text is HTML-escaped before any markup is added.
- Each fenced block has a **Copy** link that copies the original code
  exactly, indentation and all, through `wl-copy`.
- Select with the mouse, `Ctrl+C` copies, `Ctrl+A` selects the answer. Typing
  while the answer has focus goes back to the prompt; `Esc`/`Tab` return
  focus without closing.
- While streaming, the document is rebuilt at most every 120 ms
  (`answerRenderInterval`), and the view follows the end only while you are
  at the bottom. Scroll up and it stays put; scroll back down and it follows
  again. Only your scrolling changes that, never a layout change.
- Whenever the end is out of view, a **↓ more** chip sits at the bottom
  right (**↓ more arriving** while streaming). Click it to jump to the end
  and follow again.
- Limitation: a rebuild drops the selection, so select after the answer
  finishes.

`Enter` on a finished answer opens its actions (`KipTheme.answerActions`):

1. **Copy answer**: the Markdown as written (default).
2. **Copy plain**: markers stripped, code kept.
3. **Copy selection**: only listed when something is selected.
4. **Open source**: `/notes-ask` only, the highlighted source (same openers as `/notes`).
5. **Retry**: asks again and replaces the answer.
6. **More detail**: asks again with `jarvis -explain`, which adds
   `prompts/explain.md` to the system message.

Options that cannot apply are left out, so the numbers match what you see.
`Up`/`Down` still moves through `/notes-ask` sources and `Tab` still shows a
source's original text.

## Height

The body is capped at `maxBodyHeight` (600); past that it scrolls. The
answer takes whatever height is left below the sources/status above it, so
its end is always inside the card (a fixed answer cap used to let the body
clip it and hide the end of a stream). The grip on the card's bottom edge
drags the cap up (to the screen bottom) or down (to `minBodyHeight`).
Double-click the grip to reset.
Longer content uses the room, short content does not stretch to fill it.
The size survives closing KIP but not a Quickshell restart.

## Commands and keys

| Input | Mode |
| --- | --- |
| empty input | app launcher: Most used, Recent, then groups |
| `/` | command palette |
| `/as` | candidate, `/ask` highlighted |
| `/ask ` + question (alias `/a`) | general question, no notes context (mock) |
| `/notes-ask ` + question (alias `/na`) | note-grounded answer (mock) |
| `/notes ` + query (aliases `/n`, `/search`) | notes search (mock) |
| `/last`, `/last 3` (alias `/shot`) | newest screenshot(s), capped at 12 |
| `/fd words [--f=<dir>] [--h]` (alias `/find`) | files and folders via `fd`, live |
| `/rg text [--f=<dir>] [--h] [--t=<type>]` (alias `/grep`) | file contents via ripgrep, live from 3 chars |
| `/qreep [target] [function] [args]` (alias `/q`) | call any Qreep IPC function; list from `ipc show` |
| `/browse [path]` (aliases `/b`, `/ls`) | walk folders; the input is the path, text after the last `/` filters |
| `/tldr tar`, `/tldr git commit` (alias `/tl`) | real tldr page from the local cache; live |
| `/calc 5 km to mi` (aliases `/c`, `/=`) | qalc result plus how qalc read it; live, Enter copies |
| `/def word` (alias `/define`) | offline dictionary via sdcv; live, Enter copies |
| `/win [words]` (aliases `/w`, `/window`) | windows by class/title/workspace; Enter switches and focuses |
| `/timer 25m Tea`, `15:03 x`, `up x`, `pause`, `resume`, `stop` (alias `/t`) | preview, then Enter does it |
| `/run <command>` (alias `/r`) | run what you typed, in Ghostty or the background; preview first |
| `/help`, `/help fd` (alias `/?`) | commands and keys, or one command's syntax, flags, examples; live |
| `/app [name]` (alias `/apps`) | app launcher, same as empty input / plain text |
| `/foo` | calm "not a command" plus the list |
| plain text | filters apps, ranked; Enter launches the selected one |

`/help` is generated from the registry (`syntax`, `examples`, `actions`,
flag `usage`/`help`), so help and the parser cannot disagree. A mistyped
command gets "Did you mean /fd?" (edit distance ≤ 2).

Commands live in `KipCommands.qml`: name, aliases, label, description, helper,
event key, placeholder, icon, source hint, kind, takesArgument. The panel never
hardcodes `/ask`.

Keys:

- `Ctrl+/` or the header's **Help** chip: a floating keys sheet, grouped by
  where each key applies, the current group first. The groups live in
  `KipCommands.shortcutGroups`; `/help` prints the same list.
- `F1` app launcher (empty input), `F2` `/browse ` at `~`, `F3` `/fd `, `Shift+F3` `/rg `, `F4` `/win `. They
  rewrite the input, work from any view, and close an open action menu.
- `Enter` submits. Single-line on purpose.
- `Tab` completes the highlighted command.
- `Up`/`Down` move through the palette or results.
- `Enter` on a result opens it at the line: `ghostty -e nvim +<line> <path>`
  (`KipTheme.openCommand`), then closes KIP.
- `Enter` on any **markdown** hit asks first, wherever the file lives.
  `Up`/`Down` or the number keys, `Enter` confirms, `Esc` cancels. Options live
  in `KipTheme.markdownOpeners`; the first one shown is the default. Files in
  the Logseq graph get all three. In `/fd` and `/browse`, markdown outside
  the graph gets the normal file menu with Vivify after nvim; `/notes` hits
  outside the graph (`toreview/`, ...) get Default and Vivify. Non-markdown
  `/notes` hits open with Default directly.
  1. **Logseq** (Logseq graph only): `xdg-open logseq://graph/Logseq?page=<page>`. Page-level only;
     Logseq URLs cannot jump to a line without a block uuid.
     If Logseq is not running, the first link only starts it (a cold Logseq
     drops links while loading the graph). KIP watches for the `Logseq`
     window and resends the link 2 s and 5 s after it appears
     (`logseqColdStartResendDelays`), giving up after 30 s.
  2. **Default**: the nvim command above.
  3. **Vivify**: `viv <path>:<line>`, rendered and scrolled to the line.

  Page names follow Logseq 0.10 file-graph rules: `title::` if the page has
  one, else the filename with `___` → `/`; journals use the default
  `MMM do, yyyy` title (`Oct 14th, 2026`). If `:journal/page-title-format`
  is ever set in `config.edn`, `Kip.qml journalTitle()` must follow it.
- `Tab` on results shows the original retrieved text, so SQL and code can be
  copied from the note instead of from the model's retelling.
- `Ctrl+Shift+C` copies `<absolute path>:<line>` with `wl-copy`.
- `Escape` steps back from results to the prompt, then closes.
- Editing the text after a submit cancels the running request and returns to compose.
- Outside click closes.

Mock backend triggers: a query containing `nothing` returns zero results, and
one containing `fail` returns a backend error.

## Header banner

The top of the card shows an image behind the title and input, faded into the
card colour before the body starts, like the rofi theme does. Theme tokens in
`KipTheme.qml`:

- `headerImage`: `"bloom"` follows Unclaimed Bloom's current wallpaper by
  watching `~/.cache/unclaimed-bloom/current-wallpaper` (so `wallset` updates
  it while KIP is open); any other value is an image path; `""` turns it off.
- `headerImageHeight`, `headerImageOpacity`, `headerImageFadeStart` (solid
  part before the fade), `headerImageAlign` (`top`/`center`/`bottom` of the
  cropped image).

KIP reads that one file itself instead of borrowing the Bloom module's
service, so it works whether or not the Bloom surface is loaded.

## Launcher

KIP opens as an app launcher: empty input, plain text and `/app [name]` all
show it. Typing `/` hands the body to the command palette as before.

- Apps come from Quickshell's `DesktopEntries` (`NoDisplay=true` skipped).
- Without a query: **Most used** (top `appMostUsedCount`, default 10),
  **Recent** (last `appRecentCount`, default 5), then the grouping:
  category (freedesktop main categories, folded: Audio/Video → Multimedia,
  Network → Internet, Utility → Utilities, the rest → Other), name, or A–Z.
- With a query: one ranked section. Every word must match; name prefix beats
  word start beats substring beats generic name / keywords / comment / id.
  Ties go to whatever you launch more.
- `Ctrl+G` cycles grouping, `Ctrl+L` toggles grid/list; the toolbar chips do
  the same. Defaults are `appDefaultGrouping` / `appDefaultView`. The choice
  lives in `KipAppService` for the session; a Quickshell restart forgets it.
- Arrows move spatially (Up/Down keep the column across sections), `Enter`
  launches and closes KIP. Left/Right belong to the grid here, not the cursor.
- `Terminal=true` entries run as `ghostty -e <command>` (`appTerminal`);
  everything else goes through `DesktopEntry.execute()`.

Habit remarks: on a fresh open, `appNudgeChance` (0.5) of the time KIP
replaces the generic line with one about your launches, with the app's icon
in front, and preselects that app so Enter takes the hint. Three kinds, picked
at random among those that apply (`apps.nudge.*` in `KipMessages.qml`):
**most** (top app), **hour** (most launched around the current hour, ±1 h),
**recent** (last launch within `appNudgeRecentWindow`, default 3 h). An app
needs `appNudgeMinLaunches` (3) launches before KIP gets smug about it.

Launch log: `~/.local/share/qreep/kip/apps.db`, one table,
`launches(app_id, launched_at)`, written through the `sqlite3` CLI (path and
SQL passed as arguments, ids quote-escaped). It records desktop entry id and
time of launches *from KIP*, nothing else. Deleting the file resets Most used
and Recent; KIP recreates it.

```bash
sqlite3 ~/.local/share/qreep/kip/apps.db \
  "SELECT app_id, COUNT(*) FROM launches GROUP BY app_id ORDER BY 2 DESC LIMIT 10;"
```

## Screenshots

`/last [n]` lists `KipTheme.screenshotDir` (default `~/Pictures/Screenshots`)
with `find -maxdepth 1 -printf '%T@\t%p\n'`, keeps png/jpg/jpeg/webp, and
shows the `n` newest by modification time. One shot gets a large preview,
more get a grid (`screenshotColumns`, 3).

It previews live: typing `/last ` (with the space) shows the newest shot,
typing the count updates it in place (debounced 120 ms, old shots stay until
the new list lands). A bare `/last` without the space waits for Enter.
Arrow keys move, `Enter` asks:

1. **Copy image** (default): `wl-copy --type <mime>` with the file on stdin.
   This is the one place `sh` appears, only for the `<` redirect; the mime
   and path are passed as `$1`/`$2`, never pasted into the script.
2. **Copy path**: `wl-copy <path>`.
3. **Show image**: `xdg-open <path>`, i.e. your default image viewer.

The actions are `KipTheme.screenshotActions`; KIP closes after one runs.

## Files

`/fd kip notes` searches `~`; `--f=/` or `--f=~/Notes` searches elsewhere,
`--h` includes hidden files. Flags can sit anywhere in the text and get a chip
in the input; an unknown or incomplete flag is outlined red and explained
instead of searched. Results appear 250 ms after you stop typing
(`fdDebounce`); every keystroke kills the running search.

Each search runs two `fd` passes side by side, merged without duplicates:

```text
fd --color never --absolute-path --fixed-strings --max-results 200 \
   --exclude /proc --exclude /sys --exclude /dev --exclude /run \
   [--hidden] [--full-path] --and=notes -- kip ~
```

- Every word must match (`--and`), literally (`--fixed-strings`), smart case.
- The **name** pass matches words in the file/folder name. The **path** pass
  (`--full-path`) also finds "Screenshots 1134" style searches.
- Both stop at 200. With the path pass alone, a broad search of `/` filled
  the cap with path-only matches and `hyprland.conf` never arrived; the name
  pass is what makes the right file show up.
- `--and=<word>` and `--` keep a word like `-rf` a search term.
- An uncapped search of `/` took ~13 s here, so the cap is what keeps `/` quick.
  A rare name on `/` still walks the whole disk; results stream in meanwhile.

Ranking, best first: exact name, all words in the name starting with the
first, all words in the name, name starts with the first word, matched only
through the folder path; then fewer folder levels, then shorter path. The
panel shows the top 50 (`fdShownResults`).

`Enter` opens the chooser:

| Hit | Options (first is default) |
| --- | --- |
| folder | Open (file manager) / Terminal here / Broot / Copy path |
| `.md` file | `markdownOpeners` (Logseq only inside `logseqGraphDir`) |
| other file | Open (default app) / nvim / containing Folder / Copy path |

## Qreep IPC

`/qreep ` lists every IPC function of the running Qreep, read from
`quickshell ipc --pid <KIP's own process> show`, so it is whatever the shell
registers right now, not a copied list. `--pid` matters: the instance runs
from `~/.config/quickshell/qreep`, and `--path` to the repo finds nothing.

- `KipQreepCatalog.qml` curates the live list: a label, group (Surfaces,
  System, Timer, Bar, Qreeper), icon, and known argument values per action.
  Script getters, hooks other programs call (`osd`, `bloom`, `calendar`,
  `monitor-profile`), `showMe`/`hideMe`/`refresh` duplicates, KIP itself and
  `fast-password copy` are hidden; `Ctrl+H` shows everything, dimmed. A
  function the catalog does not mention lands in "Uncatalogued", visible,
  until someone decides what it is.
- Hidden is a tidy-up, not a lock: exact `target function args` still calls it.
- Typing filters on label, target and function (`upd`, `upch tog`). Targets
  show without the `qreep-` prefix.
- Actions with known values (pill ids, Aegis mode, timer alert style): Tab
  cycles them, Enter takes a unique prefix and refuses anything else.
- Enter on a function without parameters calls it. With parameters, Enter
  or Tab fills the input (`/qreep timer startCountdown `) and the status line
  shows the signature; the last parameter takes the rest of the line, so
  `/qreep timer startCountdown 25m Tea break` passes `"Tea break"`.
- `void` calls run detached and KIP closes, so the panel they open gets the
  focus. Calls returning a value stay and show the answer, selectable.

## Contents search

`/rg` runs `rg --json --fixed-strings --smart-case` over `~` (or `--f=`),
so the query is literal text and gitignored files are skipped like rg always
does. `--h` adds hidden files, `--t=py` limits to one rg file type. Caps:
`rgMaxPerFile` (5) matches per file, `rgMaxResults` (200) in total, after
which KIP stops rg itself; `.git` and `node_modules` are always skipped
(`rgExcludeGlobs`). Results show `path:line` with the line underneath.
Enter opens the file menu with **nvim at the line** first; markdown gets
Vivify at the line as well.

## Browse

`/browse` lists one folder at a time with `fd --exact-depth 1`. The input is
the whole state: `/browse ~/.config/hy` lists `~/.config/` filtered by `hy`,
so typing, Backspace and pasting a path all just work. Relative paths start at
`~`. Folders sort first, then names starting with the filter, then the rest.

| Key | Does |
| --- | --- |
| `Enter` on a folder, `Tab` | go in (rewrites the input) |
| `Enter` on a file | action menu (markdown gets the note openers) |
| `Shift+Enter` | action menu, also for folders |
| `Alt+Up`, `../` | parent folder |
| `Alt+H` | hidden files on/off |
| `Alt+I` | hide what `.gitignore`/`.ignore` would hide, on/off |
| `Alt+P` | preview pane: first `browsePreviewBytes` of text, images, a note for binaries |

Starting values are `browseShowHidden`, `browseRespectGitignore` and
`browsePreview`; the toggles last until Quickshell restarts. The listing is
re-read only when the folder or a toggle changes; filtering is local.

## tldr

`/tldr <command> [subcommand]` shows the real tldr page, never a model's
version of it. `git commit` reads `git-commit.md`; `linux/` is tried before
`common/`.

- Pages are read straight from the tldr client's cache,
  `~/.cache/tldr/pages/`. KIP never runs the client, so a lookup cannot
  download anything. Fill or refresh the cache yourself:

  ```bash
  tldr --update
  ```

  (7582 pages for `en` on 2026-10-15, about a second.)
- Names are checked against `[a-z0-9._+-]` before they touch a path, so
  `../../etc/passwd` or `rm; ls` are rejected, not looked up.
- "No page" and "empty cache" are different messages. A missing page
  suggests `man` / `--help` to run yourself; KIP runs nothing.
- Each example is its own code block with **Copy**. `{{placeholders}}` lose
  their braces, so you copy an editable template. `Enter` copies the page.

## Local tools

None of these talk to the model or the network.

- **`/calc`** runs `qalc -nocurrencies <expr>` (one argv item) and shows the
  result with qalc's own reading of the input, because qalc will turn almost
  anything into units (`foo bar` is `femtobyte*byte*bar`). Results qalc
  cannot reduce (`1/0`) say so, with qalc's warning. Currencies are off, so no
  exchange-rate downloads; `100 EUR to USD` stays `EUR 100`.
- **`/def`** runs `sdcv -n -j -e -- <word>` (exact matches only; fuzzy hits for
  half-typed words are noise). Entries are parsed, not dumped: WordNet
  (`n 1:`, `adj :`, quoted examples, `[syn: {…}]`) and Wiktionary dumps
  (`n.` lines, `(l en x)`, `(gloss: …)`, `(lb …)`, `#English` residue) become
  part of speech → numbered senses with examples and synonyms, as wrapping
  prose. Other dictionaries fall back to plain paragraphs. Enter copies the
  cleaned text. **No dictionaries are installed yet** (2026-10-15):
  StarDict dictionaries go in `~/.stardict/dic/`, the AUR has them
  (`paru -S stardict-wordnet` installs to `/usr/share/stardict/dic/`, read by
  default), `sdcv -l` lists what sdcv sees. Until then `/def` says so and
  shows that command.
- **`/win`** reads `hyprctl clients -j` once when `/win ` is typed and filters
  locally; most recently focused first. Focus goes through
  `ExposeService.focusClientObject` (workspace switch, then `focuswindow`,
  Lua dispatch aware), so Qreep has one focus path.
  Grid or list (`Ctrl+L`), icons or live previews (`Ctrl+P`), both runtime
  only; defaults are `windowDefaultView`/`windowDefaultDisplay` in
  `KipTheme.qml`. Previews are `ScreencopyView` on the `Toplevel` that
  `ExposeService.previewSourceForClient` matches, fitted to the window's
  aspect. No safe match, no preview: the card shows the icon. Icons come from
  `DesktopEntries.heuristicLookup`, then Expose's class fixes.
- **`/timer`** plans against the Qreep timer service (`shell.qml` passes
  `timer.service` in) using its own `parseDuration`/`parseFinishAt`, so KIP
  accepts exactly what the bar does. The preview says what will happen and
  which running timer it replaces; nothing changes until Enter.

`/calc` and `/def` refresh 180 ms after you stop typing (`liveDocDebounce`).

## Run

`/run` runs **what you typed**, nothing else: no answer, tldr example or
Copy link ever fills it in. It shares rofi-runner's history
(`~/.local/state/rofi-runner/history`), so old rofi-runner history still shows
up; the file is all KIP needs, not the rofi-runner script.

Hyprland bind that replaces rofi-runner (`binds.lua`):

```lua
A.exec(mainMod .. " + F2", "KIP run", qreep .. " ipc call qreep-kip toggleWith '/run '")
```

Typing shows matching history and a preview: where it will run and why.
Terminal or background is decided in this order:

1. your remembered choice (`~/.local/state/qreep/kip/run-modes.json`, command
   word → mode, written only by Shift+Enter);
2. `sudo`/`doas` always get a terminal (password prompt);
3. the script's `# %terminal: true|false` header (your `~/.local/bin` convention);
4. the `.desktop` file's `Terminal=` for that command;
5. ELF binaries: GTK/Qt/Wayland/X11/SDL libraries → background, none → terminal;
6. shell aliases/functions → terminal; anything else → background.

Checks go through `bash -ic`, like rofi-runner, so bash aliases count (zsh-only
aliases do not). `cinfo` adds its summary; a command it marks
`Danger: YES` needs a second Enter.

- **Terminal**: `ghostty --wait-after-command=true -e bash -ic "<cmd>"`, so
  the window stays open after the command ends.
- **Background**: `setsid bash -ic "<cmd>"`, in its own session, so a
  Quickshell reload cannot kill it. A wrapper watches 2 s: still running →
  started, KIP closes; exited → exit code and output shown in KIP.
- Successful commands are added to the shared history; failed ones are not.
- Up/Down picks a history entry **into the input** (Enter again runs it);
  Ctrl+Delete forgets the selected entry; Shift+Enter runs the other way and
  remembers it.

## Microcopy

`KipMessages.qml` maps event keys (`kip.open`, `ask.ready`, `notes.found`,
`error.backend`, ...) to short lines, with `neutral` and `dry` tones
(`KipTheme.tone`). A line is picked when the state is **entered**, so typing a
question after `/notes-ask ` does not reroll the message. Lines only claim what is
true at that point: no "Searching..." before a search exists.

## Not done yet

- Plain text filters the app launcher. General chat moved to `/ask`;
  note-grounded answers to `/notes-ask`.
- Launcher: no desktop actions (right-click "New window" etc.), no pinning,
  and launches from rofi or Hyprland binds are not logged.
- First `/ask` or `/notes-ask` after a cold Ollama spends ~10 s loading the model before the
  first token. The status line says `waiting for <model>` so it doesn't look stuck.
- No Hyprland layer rule ships with this. If you want blur behind the card:

  ```lua
  hl.layer_rule({ match = { namespace = "qreep-kip" }, blur = true, ignore_alpha = 0.1 })
  ```

  Do not add a Hyprland `animation` to it; KIP does its own motion and two
  animators arguing is not a feature.
