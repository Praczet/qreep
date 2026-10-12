# Delayed screenshot

A compact keyboard-first panel for selecting a delay and screenshot backend.
The important ordering is deliberately boring and deliberate:

```text
select region -> selector closes -> wait -> capture selected geometry
```

The Qreep panel itself is destroyed before Slurp starts. Slurp is always the
region selector; the selected backend controls only what happens after the
geometry has been remembered and the delay has elapsed.

## Open it

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-screenshot toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-screenshot showMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-screenshot hideMe
```

The Hyprland binding is `Ctrl+Print`.

The delay field starts at `3` seconds and accepts `0` through `30`. `Enter`
starts the selected workflow, `Escape` cancels the Qreep panel, and focus starts
in the delay field. Arrow keys adjust the delay or move between backend choices.

## Backends

### Flameshot

Slurp returns geometry in its normal form:

```bash
region="$(slurp)"
```

After the delay, the helper converts `x,y WxH` into Flameshot's `WxH+X+Y`
format and opens that exact region in Flameshot's annotation UI:

```bash
flameshot gui --region "$region" --clipboard --path "$HOME/Pictures/Screenshots"
```

Flameshot treats `--clipboard` and `--path` as final actions. Annotation still
works, but accepting the annotated result performs both actions instead of
showing separate copy and save buttons.

### Grim

The Grim path reuses the existing
`scripts/qreep-region-screenshot-delay_v0.0.1` helper. Slurp selects the region,
the helper waits, Grim writes through a temporary file, and the finished PNG is
saved as:

```text
~/Pictures/Screenshots/Screenshot_YYYY-MM-DD_HH-MM-SS.png
```

Only the finished file is copied with `wl-copy`. Cancelling selection does not
create a screenshot file.

## Dependencies and failures

The helper checks only the selected backend's dependencies. Missing commands,
directory failures, capture failures, and clipboard failures are reported with
`notify-send`, which Qreep's notification module displays. Selection cancellation
exits quietly apart from a short cancellation notification.
