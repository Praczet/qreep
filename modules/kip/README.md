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
├── KipPanel.qml       # PanelWindow: open/close motion, input, body, keys
├── KipCommands.qml    # command registry + parse(text)
├── KipMessages.qml    # event-keyed microcopy, picked on state entry
├── KipJarvisService.qml # Jarvis adapter: argv, JSON/NDJSON parsing, cancellation
├── KipMockService.qml # fake search/ask/general, Jarvis-shaped event sequence
├── KipScreenshotService.qml # /last: newest files in the screenshot folder
├── KipFileSearchService.qml # /fd: two fd passes, merged and ranked
├── KipChooser.qml     # numbered action chooser shared by every result type
├── KipShotGrid.qml    # /last thumbnails
├── KipResultList.qml  # ranked hits: origin, folder, basename, line range
├── KipMarkdown.qml    # answer Markdown → KIP-styled Qt rich text
├── KipTheme.qml       # placement, timings, reducedMotion, tone, colors
└── README.md
```

## IPC

```bash
quickshell -c qreep ipc call qreep-kip toggle
quickshell -c qreep ipc call qreep-kip showMe
quickshell -c qreep ipc call qreep-kip hideMe
quickshell -c qreep ipc call qreep-kip state   # open, phase, service, results, error, backend
quickshell -c qreep ipc call qreep-kip setBackend mock     # or jarvis
quickshell -c qreep ipc call qreep-kip run "/notes MariaDB permissions"  # no panel needed
```

`run` exists for testing the backend path headlessly; poll `state` afterwards.

## Backend

| KIP input | Jarvis call | Output |
| --- | --- | --- |
| `/notes <q>` | `jarvis --json -search-notes=<q>` | one JSON object (`notes.search.results`) |
| `/ask <q>` | `jarvis --json -ask-notes=<q>` | NDJSON: `response.start`, `response.sources`, `response.delta`…, `response.done` |
| plain text | `jarvis --json -- <q>` | same NDJSON, no sources |

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
| `0 → signalEnd` | signal | line fades in at the top edge |
| `signalEnd → descendEnd` | descend | line drops to `anchorY`, widens |
| `descendEnd → morphEnd` | morph | line becomes the input box |
| `morphEnd → 1` | assemble | header up, icon left, status right, body down |

Closing animates the same number back to 0, faster. A toggle mid-animation just
reverses direction, so there is no state machine to wedge. Content state
(`ready → processing → results/error`) is separate from motion.

The input has keyboard focus from the first frame and is only faded, never
hidden, so typing during the opening animation is kept.

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
  at the bottom. Scroll up and it stays put.
- Limitation: a rebuild drops the selection, so select after the answer
  finishes.

## Height

The body is capped at `maxBodyHeight` (600) and a streamed answer at
`answerMaxHeight` (260); past that they scroll. The grip on the card's bottom
edge drags the cap up (to the screen bottom) or down (to `minBodyHeight`);
the answer gets everything the drag adds. Double-click the grip to reset.
Longer content uses the room, short content does not stretch to fill it.
The size survives closing KIP but not a Quickshell restart.

## Commands and keys

| Input | Mode |
| --- | --- |
| `/` | command palette |
| `/as` | candidate, `/ask` highlighted |
| `/ask ` + question | note-grounded answer (mock) |
| `/notes ` + query (aliases `/n`, `/search`) | notes search (mock) |
| `/last`, `/last 3` (alias `/shot`) | newest screenshot(s), capped at 12 |
| `/fd words [--f=<dir>] [--h]` (alias `/find`) | files and folders via `fd`, live |
| `/help`, `/help fd` (alias `/?`) | commands and keys, or one command's syntax, flags, examples; live |
| `/foo` | calm "not a command" plus the list |
| plain text | general question (mock, no notes context) |

`/help` is generated from the registry (`syntax`, `examples`, `actions`,
flag `usage`/`help`), so help and the parser cannot disagree. A mistyped
command gets "Did you mean /fd?" (edit distance ≤ 2).

Commands live in `KipCommands.qml`: name, aliases, label, description, helper,
event key, placeholder, icon, source hint, kind, takesArgument. The panel never
hardcodes `/ask`.

Keys:

- `Enter` submits. Single-line on purpose.
- `Tab` completes the highlighted command.
- `Up`/`Down` move through the palette or results.
- `Enter` on a result opens it at the line: `ghostty -e nvim +<line> <path>`
  (`KipTheme.openCommand`), then closes KIP.
- `Enter` on any **markdown** hit asks first, wherever the file lives.
  `Up`/`Down` or the number keys, `Enter` confirms, `Esc` cancels. Options live
  in `KipTheme.markdownOpeners`; the first one shown is the default. Files in
  the Logseq graph get all three, anything else (`toreview/`, ...) gets
  Default and Vivify. Non-markdown hits open with Default directly.
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

## Microcopy

`KipMessages.qml` maps event keys (`kip.open`, `ask.ready`, `notes.found`,
`error.backend`, ...) to short lines, with `neutral` and `dry` tones
(`KipTheme.tone`). A line is picked when the state is **entered**, so typing a
question after `/ask ` does not reroll the message. Lines only claim what is
true at that point: no "Searching..." before a search exists.

## Not done yet

- Plain text goes to general Jarvis chat. If that turns out to be a bad
  default, route it to `/notes` instead in `KipPanel.submit()`.
- First `/ask` after a cold Ollama spends ~10 s loading the model before the
  first token. The status line says `waiting for <model>` so it doesn't look stuck.
- No Hyprland layer rule ships with this. If you want blur behind the card:

  ```lua
  hl.layer_rule({ match = { namespace = "qreep-kip" }, blur = true, ignore_alpha = 0.1 })
  ```

  Do not add a Hyprland `animation` to it; KIP does its own motion and two
  animators arguing is not a feature.
