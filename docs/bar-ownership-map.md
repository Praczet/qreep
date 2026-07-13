# Bar Ownership Map

This is the current ownership map for `modules/bar/Bar.qml`. It is a snapshot,
not a constitution. Update it when ownership moves, or future Adam gets to
practice archaeology again.

## Bar Surface

`Bar.qml` is the visible top bar and owns the layer-shell surface:

```qml
WlrLayershell.namespace: "qreep-bar"
```

It also owns the slot layout:

- left slot;
- center slot;
- right slot;
- overlay layer;
- collapsed/reserved/overlay height and exclusive-zone behavior;
- mask regions for the active pill slots.

That part belongs in the bar. The bar is allowed to be the bar. Brave stance.

## Bar State

The bar directly creates these bar-level state objects:

| Object | Kind | Notes |
| --- | --- | --- |
| `BarModeService` | bar mode service | Owns reserved, overlay, and collapsed runtime mode state. |
| `BarPillStateService` | pill state service | Owns runtime pill add/remove state and collapsed-mode pinning for registered bar pills. |
| `Core.Log` | shared support service | Used by bar-owned services for logging and notifications. |
| `ClockFeature.EventStore` | shared feature data | Loaded for the clock, calendar popup, event indicators, and reminders. |
| `ClockFeature.CalendarReminder` | reminder controller | Watches `EventStore` and emits calendar reminders. |

`shell.qml` passes the top-level timer controller/service into `Bar.qml`. The bar
uses that public API for the timer pill; it does not own the timer panel.

## Feature Services

The bar directly creates these feature services and passes them into buttons,
popups, or panels:

| Service | Consumers | Current shape |
| --- | --- | --- |
| `Power` | `PowerButton`, `PowerPanel` | Feature controller owns the service and lazy standalone layer panel. |
| `MonitorProfileService` | `MonitorProfileButton` | Small button/service pair. Leave alone until it grows teeth. |
| `MprisService` | `MprisButton`, `MprisTooltip`, `MprisPanel` | Larger anchored feature with button, tooltip, and panel. Watch it. |
| `LauncherService` | `LauncherButton` | Small command launcher button. Fine where it is. |
| `BatteryService` | `BatteryButton` | Small status pill. Fine where it is. |
| `NetworkService` | `NetworkButton`, `NetworkPanel` | Anchored button plus panel. Not as urgent as the full layer panels. |
| `LanguageService` | `LanguageButton` | Small Hyprland keyboard-layout pill. Fine where it is. |
| `Core.SoundService` | `VolumeButton`, OSD signal bridge | Shared audio service plus bar button and OSD signal. Keep the shell bridge explicit. |
| `WorkspaceService` | `Workspaces`, `WorkspaceClients` | Bar-owned workspace pill plus anchored client popup. |
| `BorgService` | `Borg`, `BorgTooltip`, `BorgProgressPopup` | Bar-owned status pill plus tooltip, progress popup, and actions. |
| `PotatoFastService` | `PotatoFastButton` | Bar-owned center pill that displays POTATO state and refreshes with a pulse. |
| `Upchecker` | `UpcheckerButton`, `UpcheckerPanel` | Feature controller owns the service and lazy standalone layer panel. First split done; suspiciously civilized. |

## Small Bar Controls

These visual controls are created directly in bar slots and are currently fine
as bar-owned objects:

| Slot | Object | Behavior |
| --- | --- | --- |
| Left | `LauncherButton` | Click launches the configured launcher. |
| Left | `Workspaces` | Runtime pill visibility/pinning; shows workspace client popup. |
| Center | `PotatoFastButton` | Click refreshes POTATO health state. |
| Center | `TimerButton` | Click opens the shell-level timer panel; middle toggles running; right stops. |
| Center | `Clock` | Runtime pill visibility/pinning; left opens calendar; right confirms manual pull. |
| Center | `MprisButton` | Click toggles playback; right-click opens player panel. |
| Right | `UpcheckerButton` | Click asks the `Upchecker` controller to toggle the update panel. |
| Right | `MonitorProfileButton` | Shows monitor profile state. Apply-next is intentionally commented out. |
| Right | `Borg` | Click refreshes, right-click runs backup. |
| Right | `BatteryButton` | Shows battery state. |
| Right | `NetworkButton` | Click toggles network panel. |
| Right | `LanguageButton` | Shows the active keyboard layout; click switches to the next configured layout. |
| Right | `VolumeButton` | Click toggles mute, right-click opens `pavucontrol`, scroll adjusts volume. |
| Right | `PowerButton` | Click toggles power panel. Hidden in collapsed mode. |

Small controls can stay in `Bar.qml` until they need their own controller. The
crime is not a button in a bar. The crime is making the bar remember every
full-screen panel's childhood.

## Runtime Pill State

Runtime pill state has two independent flags:

| Flag | IPC | Meaning |
| --- | --- | --- |
| enabled | `enablePill` / `disablePill` / `togglePill` | Adds or removes the pill from the bar. |
| pinned | `expandPill` / `collapsePill` / `togglePinned` | In collapsed mode, shows the pill full-size instead of as a collapsed strip. |

Current behavior:

| Bar mode | Enabled | Pinned | Result |
| --- | --- | --- | --- |
| reserved / overlay | false | any | Pill is absent. |
| reserved / overlay | true | any | Pill is full-size. |
| collapsed | false | any | Pill is absent. |
| collapsed | true | false | Pill is a collapsed strip. |
| collapsed | true | true | Pill is full-size. |

Do not make `enablePill` auto-expand. That sounds helpful for about four minutes,
then the state model starts wearing a false mustache.

`Bar.qml` currently registers these runtime pill IDs with
`BarPillStateService`:

```qml
["clock", "workspaces", "mpris", "timer", "upchecker", "monitorprofile", "borg", "potato-fast", "battery", "network", "language", "volume"]
```

Unknown pill IDs return an error. `listPills` returns the current state for all
known pills.

## Anchored Popups And Tooltips

The bar directly hosts these anchored or lightweight surfaces:

| Surface | Anchor / owner | Notes |
| --- | --- | --- |
| `SharedTooltip` | shared | Generic delayed tooltip surface. |
| `BorgTooltip` | `Borg` | Feature-specific structured tooltip. |
| `BorgProgressPopup` | `Borg` | Backup progress popup, hidden when the Borg pill disappears. |
| `MprisTooltip` | `MprisButton` | Feature-specific preview tooltip. |
| `WorkspaceClients` | `Workspaces` | Anchored client list popup. |
| `CalendarPopup` | `Clock` | Anchored calendar popup. |
| `CalendarPullConfirmPopup` | `Clock` | Anchored confirmation before manual calendar pull. |
| `ClockEventIndicators` | `Clock` | Popup-based event dots, suppressed while fullscreen shell surfaces are open. |
| `MprisPanel` | `MprisButton` | Anchored player panel. Larger than a tooltip, but still button-owned for now. |
| `NetworkPanel` | `NetworkButton` | Anchored network panel. |

These can remain visible-toggled for now. Destroying and recreating them would
mostly add ceremony and bugs, a classic two-for-one.

## Standalone Layer Panels

The bar routes to these standalone layer panels:

| Surface | Namespace | Current shape |
| --- | --- | --- |
| `PowerPanel` | `qreep-popup-power` | Full-height layer panel owned by `Power.qml` behind a `LazyLoader`. |
| `UpcheckerPanel` | `qreep-popup-upchecker` | Standalone update panel owned by `Upchecker.qml` behind a `LazyLoader`. |

These are the main reason this document exists. `Bar.qml` should route to these
features, not personally hold the furniture. Upchecker and Power have started
behaving. Suspicious, but useful.

## Shell-Level Modules

These are hosted by `shell.qml`, not `Bar.qml`:

| Module | Reason |
| --- | --- |
| `modules/notification/Notification.qml` | Shell-level notification popups and center. |
| `modules/timer/Timer.qml` | Shell-level timer panel and service; bar only displays the active timer pill. |
| `modules/aegis/Aegis.qml` | Top-level system overview surface. |
| `modules/dashboard/Dashboard.qml` | Top-level dashboard surface with its own IPC and panel. |
| `modules/clipboard/Clipboard.qml` | Top-level clipboard work surface with IPC and a lazy panel. |
| `modules/expose/Expose.qml` | Top-level window overview with IPC and a fullscreen panel. |
| `modules/bloom/Bloom.qml` | Shell-level Bloom panel/status surface. |
| `modules/osd/Osd.qml` | Shell-level OSD surface and IPC service. |

This is the right direction for surfaces that are not naturally bar-owned.

## Next Splits

Recommended order:

1. Revisit `Mpris` only if the panel/tooltip/service wiring keeps expanding.
2. Decide whether `launcher` and `power` should join runtime pill state or stay normal-mode-only for now.
3. Leave small anchored popups alone until there is real pain.

Keep each split as one reviewable unit. No renaming festival. No opportunistic
cleanup buffet. We have seen where that road goes.
