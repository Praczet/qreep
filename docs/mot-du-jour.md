# Mot du Jour Pipeline

Qreep displays a French word of the day in the main dashboard. It does not
choose the word, query dictionaries, or schedule updates. Qreep reads one JSON
file and leaves the dictionary pipeline outside the shell, where network calls
can fail without making QML develop opinions about lexicography.

## Ownership

| Part | Owner | Purpose |
| --- | --- | --- |
| Schedule | `mdj-note.timer` | Runs the generator hourly and catches up after login or boot. |
| Generator | `~/.local/bin/mdj-note` | Chooses and enriches one word for the current local date. |
| Display contract | `~/.cache/mdj/card.json` | Small JSON document watched by Qreep. |
| Dashboard block | `modules/dashboard/features/wotd/WordOfTheDayBlock.qml` | Parses and renders the card. |

The generator and its user systemd units are installed outside this repository.
Changing the dashboard block does not change how words are selected.

## Update Cycle

The user timer is configured with:

```ini
[Timer]
OnCalendar=hourly
Persistent=true
```

Each timer activation runs:

```bash
~/.local/bin/mdj-note --format ags-card-json
```

The generator first reads `~/.cache/mdj/latest.json`. If its date, output
format, and output path match today and `card.json` still exists, the generator
exits without making network requests.

On the first successful run of a new local calendar date, it:

1. requests a random French word from `https://trouve-mot.fr/api/random`;
2. requests the French Wiktionary entry for that word;
3. extracts the first definition group, pronunciation, and part of speech;
4. falls back to local `sdcv` dictionaries if Wiktionary has no usable definition;
5. translates French to English with `dict`, falling back to `trans`;
6. writes the dashboard card, the dated archive entry, and `latest.json`.

Despite the name, the upstream endpoint supplies a random word. The system is
"daily" because the local generator accepts one result per date, not because an
external service publishes one canonical word for everybody.

## Cache Files

The generator uses `~/.cache/mdj/`:

| File | Purpose |
| --- | --- |
| `card.json` | Current Qreep display card. |
| `latest.json` | Generator state used to decide whether today is complete. |
| `mdj-YYYY-MM-DD.json` | Enriched source payload archived for that date. |
| `history.json` | Older history format; the current generator does not update it. |

`Persistent=true` means a missed midnight activation can run after the user
session returns. It generates only the current date; it does not manufacture
entries for dates when the machine or timer was unavailable.

## Qreep Data Contract

The dashboard expects `card.json` to contain an object with
`"kind": "wotd-card"`:

```json
{
  "kind": "wotd-card",
  "date": "2026-08-17",
  "title": "Mot du jour",
  "lang": "fr",
  "trans_lang": "en",
  "word": "Honte",
  "word_raw": "honte",
  "pronunciation": "/ɔ̃t/",
  "part_of_speech": "nom",
  "definition": "A short primary definition.",
  "meanings": [
    {
      "index": 1,
      "text": "An additional meaning."
    }
  ],
  "translations": [
    "shame"
  ],
  "meta": {
    "definition_source": "wiktionary",
    "translation_source": "trans"
  }
}
```

`WordOfTheDayBlock.qml` preloads this file with a Quickshell `FileView` and
watches it for changes. A successful generator write therefore updates an open
dashboard without restarting Qreep. Missing, unreadable, malformed, or
wrong-kind JSON is shown as an error inside the card.

The default dashboard configuration currently renders the word,
pronunciation, part of speech, definition, and up to three meanings. It hides
the title, date, language pair, and translations. The data can still exist in
the card even when the block chooses not to display it.

## Useful Commands

Inspect the current card:

```bash
jq . ~/.cache/mdj/card.json
```

Inspect the generator state:

```bash
jq . ~/.cache/mdj/latest.json
```

Check the timer and its next activation:

```bash
systemctl --user status mdj-note.timer
```

Read recent generator output and failures:

```bash
journalctl --user -u mdj-note.service -n 80 --no-pager
```

Run the normal idempotent update manually:

```bash
~/.local/bin/mdj-note --format ags-card-json
```

Replace today's word deliberately:

```bash
~/.local/bin/mdj-note --format ags-card-json --force
```

`--force` requests another random word and overwrites today's card, latest
state, and dated archive. Use it when the current word is unsuitable, not as a
refresh button with commitment issues.

## Failure Behaviour

- If the initial random-word request fails, the command exits non-zero. The
  previous card remains available and the next hourly activation retries.
- Wiktionary failures fall back to `sdcv` when it is installed.
- Translation failures leave the translations list empty.
- If a word is written with incomplete enrichment, the date is still marked as
  complete. Normal hourly runs will not retry the missing fields that day.
- Writes are direct rather than atomic. The files are small, but a future
  generator revision could use temporary-file replacement if partial reads ever
  become observable.
- Archive gaps are expected when no run succeeds for a date. The timer does not
  backfill them later.

Qreep deliberately has no refresh IPC for this block. Scheduling, network
access, and retry policy belong to `mdj-note`; the dashboard remains a boring
consumer of prepared JSON. That boundary is doing useful work.
