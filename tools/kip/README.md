# kip

`kip` is the terminal side of KIP. It writes down what you just found, before
the next topic eats it. KIP owns the data; Mox will only display it.

| Command | Meaning | Tag |
| --- | --- | --- |
| `kip "text"` | Remember that this exists | `#kip` |
| `kip try "text"` | Try this later | `#kip/try` |
| `kip idea "text"` | Worth thinking about | `#kip/idea` |

```bash
install -m 0755 tools/kip/kip ~/.local/bin/kip
```

## Adding

```bash
kip qsv: process and filter CSV from the terminal
kip try "qsv: process CSV" --example "qsv stats file.csv"
kip idea "Mox could read my shortcuts"
kip "qsv: process CSV" --dry-run   # show the block, save nothing
```

That goes into today's Logseq journal, through `lsq`:

```markdown
- qsv: process CSV #kip/try
  example:: qsv stats file.csv
```

Say what it is **and what it is for**. The purpose is what you will remember
later, so that is what search needs.

The tag is added for you. Quote notes containing shell characters like `|`, `*`
or `$`, because zsh gets to them first.

The first word matters: `kip idea for dinner` saves "for dinner" as an idea. For
plain text that starts with `add`, `try` or `idea`, write
`kip add "idea for dinner"`.

`KIP_LOGSEQ_DIR` points at another graph, otherwise `lsq` uses its own config.
`KIP_LSQ` replaces the `lsq` executable.

## Listing

```bash
kip list              # everything
kip list --kind try   # note, try, idea, shortcut or tip
kip list --json       # the kip-items-v1 document Mox reads
```

Kip reads three places and never writes to any of them:

| Source | Kind | Where |
| --- | --- | --- |
| `logseq` | `note`, `try`, `idea` | `#kip` lines in `journals/` and `pages/`, using `lsq`'s `:directory` |
| `hyprland` | `shortcut` | `hyprctl binds -j`, without mouse binds and switches |
| `zsh` | `tip` | `~/.config/zsh/tips.txt`, one `keys\|description` per line, optional |

Each source reports its own `status` of `ok`, `missing` or `error`. One broken
source does not hide the others, and an error does not mean "nothing exists".
A note's `id` comes from its text, so moving it keeps its id and rewording it
makes a new one.

## Not here yet

- Searching. Use `/notes` in KIP, but the Jarvis index does not refresh by
  itself, so run `jarvis -index-notes` to find anything new.

## Tests

```bash
python3 tools/kip/test_kip.py
```

They use temporary graphs and never touch your notes.
