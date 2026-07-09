# Expose Module

## What It Does

Shows a full-screen window overview for Hyprland. Current-workspace windows are
large cards. Windows from other workspaces are grouped into compact workspace
cluster cards. Everything lands in one centered overview grid instead of a sad
top-left lineup pretending to be design.

Click a card, or select it with the keyboard and press `Enter`, to switch to
that window's workspace, focus the window, and close Expose.

Start typing to reveal search. Expose filters windows by title, class, app
label, and workspace name while keeping arrow-key navigation active.

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
grim -g "<x>,<y> <width>x<height>" -t png -l 0 ~/.cache/qreep/expose/<address>.png
Hyprland.toplevels -> wayland handle -> ScreencopyView
hyprctl dispatch focuswindow address:<address>
```

This is deliberate. Quickshell has useful Wayland and Hyprland APIs, but
`hyprctl clients -j` is still the reliable source for geometry, workspace,
class, title, and address in one boring packet.

Current-workspace `grim` captures run in parallel before the overlay opens.
That keeps Expose out of its own screenshots and avoids waiting politely for one
window capture at a time.

## Layout and Motion

Current windows and other-workspace clusters share one centered, grid-shaped
manual layout. It uses up to four columns by default, so eight windows form a
4x2 overview instead of a long horizontal shelf.

This is deliberately not a QML `Grid` item anymore. Card positions are computed
by Expose so filtered results can animate into their new slots instead of being
teleported by a layout object that thinks it is helping.

Current-window cards animate from their real window position into a middle
gather point, then settle into their grid slot with a small overshoot. Workspace
cluster cards join from the middle into their own grid slots.

## Keyboard Model

* `Escape` closes.
* Arrow keys move by grid row and column.
* When a workspace cluster is selected, arrow keys first navigate the mini cards
  inside that cluster, then fall back to the main grid when there is no inner
  neighbor in that direction.
* Printable typing opens the search field and filters the overview.
* `Escape` hides the focused search field first, clears an existing search
  second, and closes only when there is nothing left to clean up.
* `Enter` switches to the selected window's workspace, focuses it, and closes.
* Clicking a card does the same thing.

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
