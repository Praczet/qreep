import QtQuick

QtObject {
    id: rootBatteryTheme

    required property QtObject qreep

    readonly property int buttonIconPixelSize: 24
    readonly property int buttonTextPixelSize: 14
    readonly property int buttonContentSpacing: 8

    readonly property color primaryTextColor: qreep.on_surface
    readonly property color unavailableColor: qreep.on_surface_variant
    readonly property color lowColor: qreep.warningColor
    readonly property color criticalColor: qreep.error
}
