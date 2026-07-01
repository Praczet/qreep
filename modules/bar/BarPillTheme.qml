import QtQuick

QtObject {
    id: rootBarPillTheme

    required property QtObject qreep

    readonly property color backgroundColor: qreep.background
    readonly property color hoverBackgroundColor: qreep.surfaceContainerHigh
    readonly property color primaryTextColor: qreep.primary
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary

    readonly property int height: 48
    readonly property int radius: 20
    readonly property int collapsedRadius: 8
    readonly property int expandDuration: 140
    readonly property int collapseDuration: 220
    readonly property int horizontalPadding: 20
    readonly property int spacing: 8
}
