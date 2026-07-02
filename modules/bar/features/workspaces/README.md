# Workspaces Feature

## What It Does

Shows Hyprland workspaces in the left bar slot. It starts with the basics:
active and occupied workspaces, optional empty workspaces, named special
workspaces, click-to-switch, scroll-to-step, and hover tooltips with window
lists. Each visible workspace also shows grouped application icons in the pill;
multiple clients from the same app get one icon with a small count badge.

This is still the useful slice. Tiny app badges are allowed. Full client
previews can stay outside, where they belong for now.

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
readonly property string indicatorMode: "apps"
readonly property bool useHyprlandEvents: true
readonly property real hoverOpacity: 1
readonly property real hoverScale: 1.18
readonly property real inactiveBackgroundOpacity: 0.18
readonly property real emptyBackgroundOpacity: 0.08
readonly property real hoverBackgroundOpacity: 0.36
readonly property real specialActiveBackgroundOpacity: 0.18
readonly property real specialActiveBorderOpacity: 0.9
readonly property int specialActiveBorderWidth: 2
readonly property real appIconColorization: 1
readonly property real appIconBrightness: 0.9
readonly property real appIconContrast: 0
readonly property color activeAppIconColor: qreep.surface
readonly property color inactiveAppIconColor: qreep.on_surface
```

Fix app icons that Hyprland reports under unhelpful classes in
`WorkspaceService.qml`:

```qml
property var appIconAliases: ({
    "zen": "app.zen_browser.zen",
    "chrome-hnpfjngllnobngcgfapefoaidbinmjnm-default": "whatsapp-symbolic",
    "whatsapp web": "whatsapp-symbolic"
})
```

Use the lower-case client label or class as the key and the icon theme name as
the value. Get the client class with:

```bash
hyprctl clients -j
```

Get the icon name from the matching desktop file:

```bash
rg '^(Name|StartupWMClass|Icon)=' ~/.local/share/applications /usr/share/applications
```

Yes, this is a small alias table. It is still less silly than building a
desktop-file indexer because one Chrome app wanted a fake mustache.

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

The next sensible addition is a richer hover or right-click popup with grouped
and ungrouped window lists, if the current flat list starts feeling too flat.
