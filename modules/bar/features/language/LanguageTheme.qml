import QtQuick

QtObject {
    id: rootLanguageTheme

    required property QtObject qreep

    readonly property int buttonIconPixelSize: 18
    readonly property int buttonTextPixelSize: 13
    readonly property int buttonContentSpacing: 6

    readonly property color primaryTextColor: qreep.on_surface
    readonly property color unavailableColor: qreep.on_surface_variant

    readonly property real pulseScale: 1.14
    readonly property int pulseOutDuration: 140
    readonly property int pulseInDuration: 180
}
