# Jarvis

Jarvis is the local Ollama assistant and notes search that KIP talks to. It
lives here so changes to it have history; the installed command is still
`~/.local/bin/jarvis`.

This copy started as a byte-for-byte import of the installed script on
2026-10-15. Edit it here, then install:

```bash
install -m 0755 tools/jarvis/jarvis ~/.local/bin/jarvis
install -d ~/.config/jarvis/prompts
install -m 0644 tools/jarvis/prompts/*.md ~/.config/jarvis/prompts/
```

`install` copies with the right mode in one step. Editing
`~/.local/bin/jarvis` directly works until the next install overwrites it,
so don't.

## Response policy

General questions and `-ask-notes` build their system message from
`prompts/kip-response.md` plus a mode overlay (`general.md` or
`ask-notes.md`); `-explain` appends `explain.md`. Only those files go into
the system message. The question, your `memory.md` preferences and
retrieved notes stay in the user message, clearly delimited.

- Prompt directory: `~/.config/jarvis/prompts`, override with `JARVIS_PROMPTS`.
- If a file is missing, Jarvis falls back to its old built-in one-liners
  instead of failing.
- Answer temperature: `JARVIS_TEMPERATURE` (default 0.3). `-code` and `-note`
  keep the model's own (0.6 for `adam-jarvis-fast`).
- `--json` adds `policy` to `response.start`, e.g. `general:97cbca61` (mode +
  hash of the system text) or `general:builtin`, so a bad answer can be traced
  to the prompt that produced it.

A prompt makes answers tidier, not correct. Tested on 2026-10-15: the
general prompt still produced an invented `ls --sort=asc`. Real command
documentation belongs in a tool (`/tldr` in KIP), not in more prompt text.

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
