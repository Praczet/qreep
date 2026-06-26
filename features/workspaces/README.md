# Workspaces Feature

## What It Does

Shows Hyprland workspaces in the left bar slot. It starts with the basics:
active and occupied workspaces, optional empty workspaces, named special
workspaces, click-to-switch, scroll-to-step, and hover tooltips with window
lists.

This is the useful slice. Icons and grouping can wait their turn in the queue
like everyone else.

## Files

* `Workspaces.qml` - visible bar module.
* `WorkspaceClients.qml` - clickable window list popup.
* `WorkspaceService.qml` - Hyprland queries, workspace model, and dispatch.
* `WorkspacesTheme.qml` - display options, spacing, opacity, and refresh timing.

## Where To Change Things

Change clutter and display policy in `WorkspacesTheme.qml`:

```qml
readonly property bool showEmptyWorkspaces: false
readonly property bool showSpecialWorkspaces: true
readonly property string indicatorMode: "count"
readonly property bool useHyprlandEvents: true
readonly property real hoverOpacity: 1
readonly property real hoverScale: 1.18
readonly property real inactiveBackgroundOpacity: 0.18
readonly property real emptyBackgroundOpacity: 0.08
readonly property real hoverBackgroundOpacity: 0.36
readonly property real specialActiveBackgroundOpacity: 0.18
readonly property real specialActiveBorderOpacity: 0.9
readonly property int specialActiveBorderWidth: 2
```

The service listens to Quickshell's Hyprland event stream and refreshes after
workspace/window events. It still keeps a slow poll as a fallback, because event
streams are reliable right up to the moment they are not.

The refresh path uses:

```bash
hyprctl workspaces -j
hyprctl activeworkspace -j
hyprctl clients -j
hyprctl monitors -j
```

Special workspaces are tracked separately from normal active workspaces. Hyprland
keeps the normal workspace active underneath, so Qreep shows the normal active
workspace as filled and the active special workspace with an accent border.

Hovering a workspace uses the shared passive tooltip. Right-clicking a workspace
opens a clickable window list popup. Each row shows an icon and window title;
clicking focuses that client by address.

## Later

The next sensible additions are app icons, class grouping, and a richer hover
popup with grouped and ungrouped window lists.
