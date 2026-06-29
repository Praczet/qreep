# Dashboard Word Of The Day Block

The word-of-the-day block reads the MDJ/WOTD card JSON and renders it inside a
dashboard card. It is display-only; the dictionary pipeline can keep doing
dictionary pipeline things elsewhere, where it can be watched safely.

Default card path:

```text
~/.cache/mdj/card.json
```

## Example

```json
{
  "id": "wotd-compact",
  "type": "word-of-the-day",
  "anchorPoint": "top-center",
  "dx": -164,
  "dy": 110,
  "width": 490,
  "height": 340,
  "showTitle": false,
  "config": {
    "variant": "compact",
    "maxMeanings": 3,
    "maxTranslations": 2,
    "maxWidth": 450,
    "minHeight": 300,
    "showLang": false,
    "showTitle": false
  }
}
```

## Config Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `path` / `cardPath` | string | `~/.cache/mdj/card.json` | Card JSON path. `~/` expands to `$HOME/`. |
| `variant` | string | `card` | `card`, `compact`, or `definition-only`. |
| `maxWidth` | number | block width | Max content width. |
| `minHeight` | number | `0` | Minimum implicit height. |
| `padding` | number | `0` | Inner padding inside the block. |
| `spacing` | number | variant-based | Vertical spacing between rows. |
| `showTitle` | boolean | `variant !== "compact"` | Shows the card title. |
| `title` / `titleOverride` | string | card title | Optional title override. |
| `showDate` | boolean | `false` | Shows the card date. |
| `showLang` | boolean | `variant === "card"` | Shows language pair such as `FR -> EN`. |
| `showWord` | boolean | `true` | Shows the word. |
| `showPronunciation` | boolean | `true` | Shows pronunciation when present. |
| `showPartOfSpeech` | boolean | `true` | Shows part of speech when present. |
| `showDefinition` | boolean | `true` | Shows the short definition. |
| `showMeanings` | boolean | `variant !== "definition-only"` | Shows numbered meanings. |
| `showTranslations` | boolean | `true` | Shows translations for card/compact variants. |
| `showTranslation` | boolean | `true` | Shows one translation for definition-only variant. |
| `maxMeanings` | number | `1` compact, `3` card | Numbered meaning limit. |
| `maxTranslations` | number | `1` compact, `3` card | Translation limit. |
| `wordPixelSize` | number | `36` compact, `38` card | Word heading size. |
