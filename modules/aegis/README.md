# Aegis Module

## What It Does

Aegis owns Qreep's system overview surface and the dashboard widgets that used
to live in AGS.

It provides:

* a standalone `qreep-aegis` overlay;
* a shared sysinfo service;
* dashboard block types for full/summary Aegis, CPU graph, memory pie, and disk
  pie;
* dashboard-style enter/leave motion for standalone Aegis cards;
* a compatibility path for old AGS dashboard configs that use `widgets`.

This is a top-level shell module. It is not a bar feature. The bar has suffered
enough.

## Files

* `Aegis.qml` - scope/controller, IPC, service ownership, lazy panel.
* `AegisPanel.qml` - full-screen overlay panel.
* `AegisService.qml` - shared sysinfo probes and section formatting.
* `AegisBlock.qml` - dashboard-facing block renderer.
* `AegisCpuGraph.qml` - CPU usage graph.
* `AegisPie.qml` - memory/disk pie renderer.
* `AegisSection.qml` and `AegisInfoRow.qml` - reusable info layout.
* `AegisTheme.qml` - placement, sizes, colors, timing.

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

Supported dashboard block types:

```text
aegis
aegis-summary
aegis-cpu-graph
aegis-memory-pie
aegis-disk-pie
```

`modules/dashboard/DashboardService.qml` can normalize the old AGS `widgets`
array shape. Qreep still prefers native `blocks`, but the compatibility path
exists so migration does not require a tiny archaeology degree.

## Validation

```bash
qmllint modules/aegis/*.qml
qmllint modules/dashboard/*.qml
timeout 10 quickshell --path . --no-duplicate
```
