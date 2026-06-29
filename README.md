# Qreep

Qreep is Adam's Quickshell learning bar. It started as a Waybar-shaped
experiment and is now exactly the sort of thing that needs documentation before
future Adam starts guessing. Guessing is how tiny panels become archaeology.

## Run

From the Quickshell config install location:

```bash
quickshell -c qreep
```

Use this when relaunching during tests:

```bash
quickshell -c qreep --no-duplicate
```

That second command refuses to spawn another copy if one is already running.
Useful if you do not want a bar colony.

## Layout

```text
shell.qml
core/
components/
modules/
theme/
```

Top-level Qreep modules live under `modules/`. The bar module lives at
`modules/bar/` and bar-owned pills, panels, services, and popups live under
`modules/bar/features/`. Reusable wrappers remain in `components/`. Theme
entry points remain in `theme/`.

Current bar-owned feature folders:

```text
modules/bar/features/
├── borg/
├── clock/
├── monitorprofile/
├── mpris/
├── osd/
├── power/
└── upchecker/
```

## Bar

The main bar is `modules/bar/Bar.qml`.

It owns:

* the left, center, right, and overlay slots;
* shared services used by bar modules;
* shared tooltip surfaces;
* feature panels/popups that are opened from bar buttons.

The bar layer namespace is:

```qml
WlrLayershell.namespace: "qreep-bar"
```

Do not blur this layer unless you enjoy transparent edge artifacts and follow-up
questions from yourself.

## Hyprland Layer Rules

Use separate layer rules for separate surfaces. The bar is not the power panel.
This is a useful fact, despite everything trying to make it annoying.

Example shape:

```lua
hl.layer_rule({
    name = "qreep-bar",
    match = { namespace = "qreep-bar" },
    animation = "popin 85%",
})

hl.layer_rule({
    name = "qreep-power",
    match = { namespace = "qreep-popup-power" },
    blur = true,
    animation = "popin 85%",
    ignore_alpha = 0.5,
})

hl.layer_rule({
    name = "qreep-upchecker",
    match = { namespace = "qreep-popup-upchecker" },
    blur = true,
    animation = "popin 85%",
    ignore_alpha = 0.5,
})
```

`ignore_alpha` tells Hyprland not to blur behind pixels at or below that alpha
threshold. Higher values ignore more soft/transparent pixels. Good for avoiding
blur halos around rounded transparent surfaces.

## Theme

The public theme object is `theme/QreepTheme.qml`.

Root theme files:

* `theme/colors/UnclaimedBloomColors.qml`
* `theme/colors/template.qml`

Module theme files live with their owning module:

* `modules/ModulesTheme.qml`
* `modules/bar/BarTheme.qml`
* `modules/bar/BarPillTheme.qml`
* `modules/bar/TooltipTheme.qml`
* `modules/dashboard/DashboardTheme.qml`
* `modules/osd/OsdTheme.qml`

`QreepTheme.qml` exposes global semantic colors and the aggregated module theme:

```qml
readonly property QtObject modules: Modules.ModulesTheme {
    qreep: rootQreepTheme
}
```

Old paths such as `theme.module`, `theme.tooltip`, and `theme.dashboard` remain
as compatibility aliases for now. New module-specific code should prefer paths
like `theme.modules.bar.pill`, `theme.modules.bar.tooltip`, and
`theme.modules.dashboard`.

If a feature needs sizes, spacing, timing, or command names, put them in that
feature's theme file. Hardcoding in the button is how the next tweak becomes a
search warrant.

## IPC

Useful current targets:

```bash
quickshell ipc call qreep-borg refresh
quickshell ipc call qreep-upchecker refresh
quickshell ipc call qreep-upchecker toggle
quickshell ipc call qreep-monitor-profile refresh
quickshell ipc call osd showMessage "Hello from the questionable future" 3000
```

Some Quickshell versions vary slightly in CLI syntax. If this bites, check:

```bash
quickshell ipc --help
```

## Event JSON

Clock events are loaded from:

```text
events.json
```

Expected shape:

```json
{
  "events": [
    {
      "date": "2026-06-25",
      "title": "Meeting",
      "start": "14:00",
      "end": "15:00",
      "allDay": false
    }
  ]
}
```

The clock shows current-day dots and the calendar shows today plus the next five
days.

## Monitor Profile JSON

Monitor profile state is read from:

```text
${XDG_RUNTIME_DIR:-/tmp}/hypr-monitor-profile-qreep.json
```

QML does not expand shell syntax, so the service builds that path with
`Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"`.

The service expects a `layout` array with `position`, `display_name`,
`external`, and optional `display.mode`/`display.scale` values. It sorts monitors
by position and renders a compact icon summary.

## Validation

Small useful checks:

```bash
qmllint modules/bar/Bar.qml
qmllint theme/QreepTheme.qml
qmllint modules/bar/features/mpris/MprisService.qml
```

For broader changes:

```bash
qmllint modules/bar/Bar.qml theme/QreepTheme.qml modules/bar/features/*/*.qml
```

Runtime smoke test:

```bash
quickshell -c qreep --no-duplicate
```

If it says an instance is already running, that is not a failed launch. It is the
command doing what the flag says. Suspiciously rare behavior.
