import QtQuick

QtObject {
    id: rootMonitorProfileTheme

    readonly property int buttonIconPixelSize: 24
    readonly property int buttonTextPixelSize: 14
    readonly property int buttonContentSpacing: 8

    readonly property real pulseScale: 1.2
    readonly property real pulseRotation: 15
    readonly property real pulseSettleScale: 1.1
    readonly property real pulseRotationSettle: 5
    readonly property int pulseOutDuration: 200
    readonly property int pulseSettleDuration: 150
    readonly property int pulseInDuration: 200
}
