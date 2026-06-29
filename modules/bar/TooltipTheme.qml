import QtQuick

QtObject {
    id: rootTooltipTheme

    required property QtObject qreep

    readonly property color backgroundColor: qreep.surface
    readonly property color borderColor: qreep.surfaceContainerHigh
    readonly property color warningBorderColor: qreep.primary
    readonly property color titleTextColor: qreep.on_surface
    readonly property color contentTextColor: qreep.on_surface

    readonly property int offsetY: 8
    readonly property int minimumWidth: 180
    readonly property int horizontalPadding: 16
    readonly property int verticalPadding: 12
    readonly property int radius: 10
    readonly property int borderWidth: 1
    readonly property int padding: 12
    readonly property int spacing: 4
    readonly property int titlePixelSize: 13
    readonly property int contentPixelSize: 12
    readonly property real contentLineHeight: 1.15
    readonly property int showDelay: 400
    readonly property int hideDelay: 500
    readonly property real popScale: 1.2
    readonly property int showOutDuration: 120
    readonly property int showSettleDuration: 90
    readonly property int hideOutDuration: 80
    readonly property int hideInDuration: 120
}
