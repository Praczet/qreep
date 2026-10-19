import QtQuick

QtObject {
    id: rootVitalsTheme

    required property QtObject qreep

    // Indicators shown at startup. Runtime changes go through qreep-vitals IPC
    // and are not persisted.
    readonly property var defaultIndicators: ["cpu-temp", "disk"]

    readonly property int cpuInterval: 2000
    readonly property int sensorInterval: 3000
    readonly property int diskInterval: 60000
    readonly property string diskMount: "/"
    // 0 = trust the driver's fanN_max, then the highest rpm seen this session.
    readonly property int fanMaxRpm: 0

    readonly property int indicatorSize: 26
    readonly property int clusterItemSize: 13
    readonly property int clusterSpacing: 2
    readonly property int gaugeLineWidth: 3
    readonly property int clusterGaugeLineWidth: 2
    readonly property int iconPixelSize: 12
    readonly property int contentSpacing: 6

    // Color levels as a fraction of the indicator's own max (temp: sensor
    // crit, fan: max rpm, the rest: 100%). Below `success` -> success color,
    // below `warning` -> normal, below `critical` -> warning, else critical.
    // success: 0 skips the success level. `inverted` flips the scale for
    // things where full is good (battery: 0.2 fill-left = 80% drained).
    readonly property var tempLevels: ({ success: 0.5, warning: 0.6, critical: 0.75 })
    readonly property var usageLevels: ({ success: 0.25, warning: 0.75, critical: 0.9 })
    readonly property var fanLevels: ({ success: 0.25, warning: 0.6, critical: 0.85 })
    readonly property var diskLevels: ({ success: 0.5, warning: 0.8, critical: 0.92 })
    readonly property var batteryLevels: ({ success: 0.2, warning: 0.8, critical: 0.9, inverted: true })

    // Translucent so the track stays visible on both pill and hover backgrounds.
    readonly property color trackColor: Qt.rgba(qreep.on_surface_variant.r, qreep.on_surface_variant.g, qreep.on_surface_variant.b, 0.6)
    readonly property color successColor: qreep.successColor
    readonly property color normalColor: qreep.primary
    readonly property color warningColor: qreep.warningColor
    readonly property color criticalColor: qreep.error
    readonly property color iconColor: qreep.on_surface
    readonly property color unavailableColor: qreep.on_surface_variant
}
