# Vitals

One bar pill that holds a set of small system indicators. Toggle indicators
on and off at runtime. When none are on, the pill disappears instead of
sitting there as an empty bean.

Left click opens Aegis. The pill is the glance; Aegis is the detail.

## Indicators

| ID | Shape | Source |
| --- | --- | --- |
| `cpu-usage` | pie | `/proc/stat`, delta between samples |
| `core-usage` | 2-row pie cluster | `/proc/stat` `cpuN` lines, one per **logical CPU** (thread) |
| `cpu-temp` | gauge | hwmon `coretemp` "Package id 0" (fallback `k10temp` Tctl/Tdie, `zenpower`), scaled to the sensor's `temp_crit` |
| `core-temps` | 2-row gauge cluster | hwmon `coretemp` "Core N", one per **physical core** |
| `cpu-fan` | gauge | busiest fan on one hwmon device; prefers a device with `fanN_max` (`dell_smm` reports 8000) |
| `battery` | gauge | the bar's `BatteryService` (UPower) |
| `disk` | gauge | `df -B1 -P <VitalsTheme.diskMount>` |

Threads and cores are separate on purpose. The i7-1165G7 has 4 cores and 8
threads, and pretending those lists line up would just be lying with circles.

Fan labels lie. On this XPS `dell_ddv` calls fan1 "CPU Fan", and it reads 0 rpm
at 92 °C while fan2 spins at ~6000. So the gauge shows the busiest fan on the
device, not whichever one has the nicest label.

Fan max: `VitalsTheme.fanMaxRpm` if non-zero, otherwise the driver's
`fanN_max`, otherwise the highest rpm seen this session. The driver max is
nominal; the fan may never actually get there.

## Colors

Every indicator is colored by how full it is relative to its own max, so
"75% of max" means the same thing for a temperature and a disk:

| Level | Theme color | Temp (of crit) | Usage | Fan (of max) | Disk | Battery (drained) |
| --- | --- | --- | --- | --- | --- | --- |
| success | `successColor` | < 50% | < 25% | < 25% | < 50% | < 20% |
| normal | `primary` | < 60% | < 75% | < 60% | < 80% | < 80% |
| warning | `warningColor` | < 75% | < 90% | < 85% | < 92% | < 90% |
| critical | `error` | >= 75% | >= 90% | >= 85% | >= 92% | >= 90% |

Thresholds are the `*Levels` objects in `VitalsTheme.qml`. Battery is
`inverted`: full is good, so the levels apply to the drained fraction.

## Files

* `Vitals.qml` - controller: enabled indicators, IPC, sensor demand, indicator data, tooltip text.
* `VitalsButton.qml` - the pill; one `VitalsIndicator` per enabled id.
* `VitalsIndicator.qml` - renders a gauge, pie, or cluster.
* `VitalsTheme.qml` - default indicator set, intervals, thresholds, sizes, colors.
* `core/SystemSensorsService.qml` - shared sensor reader, hosted by `shell.qml`.
* `components/QreepGauge.qml`, `components/QreepPie.qml` - bar-sized shapes.

## Polling

`SystemSensorsService` polls nothing until a consumer calls
`setDemand(id, groups)`. Vitals asks only for the groups its enabled
indicators need (`cpu`, `sensors`, `disk`), and only while the pill is visible.

* `/proc/stat` - `FileView.reload()` every `cpuInterval` (2 s). No process spawn.
* hwmon - one `grep -H .` over the resolved files every `sensorInterval` (3 s).
* disk - `df` every `diskInterval` (60 s).

hwmon devices are discovered once, by their `name` file. `hwmonN` indexes move
between boots and are not to be trusted.

## IPC

Runtime only. Reloading Qreep resets to `VitalsTheme.defaultIndicators`.

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-vitals listIndicators
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-vitals toggleIndicator cpu-temp
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-vitals enableIndicator core-usage
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-vitals disableIndicator disk
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-vitals setIndicators "cpu-usage,cpu-temp,disk"
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-vitals state
```

The pill also uses the normal pill id `vitals` in `qreep-bar-pill`.

## Follow-ups

* Right-click checklist popup for toggling indicators by mouse.
* Point Aegis's live CPU/temp at `SystemSensorsService` (Aegis still reads the first `thermal_zone*`).
* A second pill instance ("sets") only if one pill stops being enough.
