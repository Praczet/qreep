# Battery Feature

## What It Does

Shows the current UPower display-device battery state in the right bar slot.
The pill stays compact until the battery is critical, then shows the percent
because subtle warnings are cute right up until the laptop becomes furniture.

## Files

* `BatteryButton.qml` - bar pill, icon, critical percent text, tooltip wiring.
* `BatteryService.qml` - `UPower.displayDevice` state and icon/tooltip helpers.
* `BatteryTheme.qml` - icon sizing, spacing, and status colors.

## Wiring

`modules/bar/Bar.qml` creates `BatteryService` and passes it to
`BatteryButton`.

This is a bar-owned feature. Sources live under
`modules/bar/features/battery/`.

Theme is exposed through:

```qml
readonly property QtObject battery: BatteryFeature.BatteryTheme {
    qreep: rootBarTheme.qreep
}
```

## Service Notes

`BatteryService.qml` uses:

```qml
import Quickshell.Services.UPower
```

It derives availability, charging state, percent, remaining time, warning
thresholds, icon glyph, and tooltip text from `UPower.displayDevice`.

There is no IPC target for battery. It is display-only for now. This is allowed.
