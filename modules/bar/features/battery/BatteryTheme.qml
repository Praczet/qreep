import QtQuick

QtObject {
    id: rootBatteryTheme

    required property QtObject qreep

    readonly property int buttonIconPixelSize: 24
    readonly property int buttonTextPixelSize: 14
    readonly property int buttonContentSpacing: 8

    readonly property color primaryTextColor: qreep.on_surface
    readonly property color unavailableColor: qreep.on_surfaceDisabled
    readonly property color lowColor: qreep.warning
    readonly property color criticalColor: qreep.error
}
