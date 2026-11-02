# kip

`kip` is the terminal side of KIP. It writes down what you just found, before
the next topic eats it. KIP owns the data; Mox will only display it.

```bash
install -m 0755 tools/kip/kip ~/.local/bin/kip
```

## Adding

```bash
kip add qsv: process and filter CSV from the terminal
kip add "qsv: process CSV" --type tool --try "qsv stats file.csv"
kip add "qsv: process CSV" --dry-run   # show the block, save nothing
```

That goes into today's Logseq journal, through `lsq`:

```markdown
- qsv: process CSV #kip
  type:: tool
  try:: qsv stats file.csv
```

Say what it is **and what it is for**. The purpose is what you will remember
later, so that is what search needs.

`#kip` is added for you. Quote notes containing shell characters like `|`, `*`
or `$`, because zsh gets to them first.

`KIP_LOGSEQ_DIR` points at another graph, otherwise `lsq` uses its own config.
`KIP_LSQ` replaces the `lsq` executable.

## Not here yet

- Searching. Use `/notes` in KIP, but the Jarvis index does not refresh by
  itself, so run `jarvis -index-notes` to find anything new.
- Reminders. Nothing reads `#kip` yet.

## Tests

```bash
python3 tools/kip/test_kip.py
```

They use temporary graphs and never touch your notes.
