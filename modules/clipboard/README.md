# Clipboard

`qreep-clipboard` is a shell-level clipboard picker backed by `clipvault`.

Current scope:

- bottom overlay panel;
- text, code, color, and image-metadata cards;
- search/filter;
- keyboard navigation;
- restore selected entry through `wl-copy`;
- delete selected entry if `clipvault delete` accepts the id;
- pin metadata in `~/.local/share/clipvault/pinned.json`.

IPC:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard show
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard hide
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard refresh
```

Hyprland can bind `ctrl+super+v` to the `toggle` command later. No bar button is planned. The bar does not need another thing pretending to be small.
