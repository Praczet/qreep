# Aegis Module

## What It Does

Aegis owns the `qreep-aegis` shell entry point. It is a dashboard instance with
system-info cards, not a second dashboard engine.

It provides:

* a standalone `qreep-aegis` overlay;
* its own dashboard config at `modules/dashboard/configs/aegis_dashboard.json`;
* a sysinfo service under `modules/dashboard/features/aegis/`;
* block types for full/summary Aegis, CPU graph, memory pie, and disk pie;
* dashboard-style enter/leave motion through the shared dashboard panel;
* the same `blocks` schema as the main dashboard.

This is a top-level shell module. It is not a bar feature. The bar has suffered
enough.

## Files

* `Aegis.qml` - scope/controller, IPC, service ownership, lazy dashboard panel.
* `modules/dashboard/configs/aegis_dashboard.json` - Aegis-specific dashboard layout.
* `modules/dashboard/features/aegis/AegisService.qml` - sysinfo probes and section formatting.
* `modules/dashboard/features/aegis/AegisBlock.qml` - dashboard-facing block renderer.
* `modules/dashboard/features/aegis/AegisCpuGraph.qml` - CPU usage graph.
* `modules/dashboard/features/aegis/AegisPie.qml` - memory/disk pie renderer.
* `modules/dashboard/features/aegis/AegisSection.qml` and `AegisInfoRow.qml` - reusable info layout.
* `modules/dashboard/features/aegis/AegisTheme.qml` - placement, sizes, colors, timing.

## Data Sources

Aegis uses Quickshell services where they are useful:

```qml
Quickshell.Services.UPower
Quickshell.Networking
Quickshell.Hyprland
```

It uses `Quickshell.Io.Process` for the dull Linux facts Quickshell does not
own directly: `/proc`, `df`, `lsblk`, `lspci`, package counts, and Hyprland JSON
details. No AGS runtime is involved.

## IPC

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-aegis toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-aegis showMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-aegis hideMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-aegis refresh
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-aegis setMode full
```

## Dashboard

Aegis uses `modules/dashboard/DashboardPanel.qml` and
`modules/dashboard/DashboardService.qml` with a different config path. The main
dashboard keeps `modules/dashboard/configs/main_dashboard.json`; Aegis keeps
`modules/dashboard/configs/aegis_dashboard.json`. They should remain separate unless future
Adam wants the two surfaces to become the same thing, which is a different
argument.

Supported dashboard block types:

```text
aegis
aegis-summary
aegis-cpu-graph
aegis-memory-pie
aegis-disk-pie
```

Aegis uses the same `blocks` schema as the main dashboard: `cardStyle`, `title`,
`text`, `preset`, `anchorPoint`, `dx`, `dy`, `width`, `height`, `from`, and
`config`. The old AGS `widgets` shape is not supported here.

## Validation

```bash
qmllint modules/aegis/*.qml modules/dashboard/features/aegis/*.qml
qmllint modules/dashboard/*.qml
timeout 10 quickshell --path . --no-duplicate
```
