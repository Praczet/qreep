# Jarvis

Jarvis is the local Ollama assistant and notes search that KIP talks to. It
lives here so changes to it have history; the installed command is still
`~/.local/bin/jarvis`.

This copy started as a byte-for-byte import of the installed script on
2026-10-15. Edit it here, then install:

```bash
install -m 0755 tools/jarvis/jarvis ~/.local/bin/jarvis
```

`install` copies with the right mode in one step. Editing
`~/.local/bin/jarvis` directly works until the next install overwrites it,
so don't.

## What KIP uses

| KIP | Jarvis |
| --- | --- |
| `/notes <q>` | `jarvis --json -search-notes=<q>` |
| `/ask <q>` | `jarvis --json -ask-notes=<q>` |
| plain text | `jarvis --json -- <q>` |

The `=` / `--` forms keep a question starting with `-` from being read as a
flag. `--json` output is the contract: one JSON object for search, NDJSON
events (`response.start`, `response.sources`, `response.delta`,
`response.done`, `response.error`) for answers. Change it and KIP breaks.

## Files it touches

- `~/.local/share/jarvis/notes.sqlite`: the notes index (`jarvis -index-notes`).
- `~/.local/share/jarvis/memory.md`: only via `jarvis -remember`.
- `~/.local/share/jarvis/drafts/`: only via `jarvis -note-save`.
