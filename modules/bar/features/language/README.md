# Language Feature

## What It Does

Shows the current Hyprland keyboard layout in the right bar slot. Left click
switches to the next configured layout, because reaching for Polish characters
should not require a small archaeological dig.

For a normal US plus Polish programmer setup, Hyprland usually wants something
like this in its input config:

```ini
input {
    kb_layout = us,pl
}
```

`pl` is the usual Polish programmer layout in XKB land. If Hyprland is
configured differently, Qreep only reports what Hyprland says. A rare moment of
restraint.

## Files

* `LanguageButton.qml` - bar pill, short layout label, tooltip wiring.
* `LanguageService.qml` - reads `hyprctl devices -j`, listens for Hyprland
  layout events, and switches layouts.
* `LanguageTheme.qml` - icon, text, spacing, and pulse tokens.

## Wiring

`modules/bar/Bar.qml` creates `LanguageService` and passes it to
`LanguageButton`.

This is a bar-owned feature. Sources live under
`modules/bar/features/language/`.

Theme is exposed through:

```qml
readonly property QtObject language: LanguageFeature.LanguageTheme {
    qreep: rootBarTheme.qreep
}
```

## Commands

Refresh or inspect the current state:

```bash
quickshell ipc call qreep-language refresh
quickshell ipc call qreep-language state
```

Switch to the next configured layout:

```bash
quickshell ipc call qreep-language next
```

The click path uses:

```bash
hyprctl switchxkblayout all next
```

That switches every Hyprland keyboard to the next configured layout. This keeps
external and laptop keyboards from politely disagreeing with each other.
