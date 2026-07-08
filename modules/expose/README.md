# Expose Module

## What It Does

Shows a full-screen window overview for Hyprland. Current-workspace windows are
large cards. Windows from other workspaces are grouped into compact workspace
clusters. Click a card, or select it with the keyboard and press `Enter`, to
focus that window.

This is a top-level shell module. It is not a bar pill. The bar has enough
tiny furniture already.

## Files

* `Expose.qml` - Scope/controller, IPC, open state, lazy panel.
* `ExposePanel.qml` - full-screen overlay and keyboard navigation.
* `ExposeService.qml` - Hyprland data, grouping, selection, and focus dispatch.
* `ExposeClientCard.qml` - one selectable window card.
* `ExposeWorkspaceCluster.qml` - compact grouped non-current workspace card.
* `ExposeTheme.qml` - placement, sizing, color, and animation tokens.

## IPC

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose showMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose hideMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose refresh
```

For the installed `qreep` config name:

```bash
quickshell -c qreep ipc call qreep-expose toggle
```

## Hyprland Binding

Example:

```ini
bind = SUPER, TAB, exec, quickshell -c qreep ipc call qreep-expose toggle
```

Adjust this to match the current Hyprland config layer. The command just tells
the already-running Qreep instance to show the overlay; it should not spawn a
second shell instance, because duplicate bars are how desktop folklore starts.

## Backend

V1 uses:

```bash
hyprctl activeworkspace -j
hyprctl clients -j
grim -g "<x>,<y> <width>x<height>" ~/.cache/qreep/expose/<address>.png
Hyprland.toplevels -> wayland handle -> ScreencopyView
hyprctl dispatch focuswindow address:<address>
```

This is deliberate. Quickshell has useful Wayland and Hyprland APIs, but
`hyprctl clients -j` is still the reliable source for geometry, workspace,
class, title, and address in one boring packet.

## Keyboard Model

* `Escape` closes.
* Arrow keys move the selection spatially.
* `Enter` focuses the selected window and closes.
* Clicking a card focuses that window and closes.

Search is intentionally not in v1. Later, printable typing should open a search
field and filter by title, class, app label, and workspace name.

## Preview Note

Current-workspace cards use runtime `grim -g` screenshots by default. It is
fast and boring, which is more useful than slow and theoretically elegant.

`modules/expose/ExposeTheme.qml` exposes:

```qml
readonly property bool useScreencopy: false
```

Set that to `true` to prefer Quickshell `ScreencopyView` fed by the Wayland
handle from `Hyprland.toplevels`. If a client cannot be matched to a Wayland
toplevel, Expose still falls back to a `grim -g` screenshot captured from
Hyprland geometry.

The grim path is rectangle-based and therefore still cursed around overlapping
floating windows. Screencopy should avoid that specific photobomb, but it has
been slower here and is not innocent either.

Other workspace clusters stay icon based for now.

Generated thumbnails live under:

```text
~/.cache/qreep/expose/
```

No durable preview store. Window thumbnails do not need to become a family
photo archive.
