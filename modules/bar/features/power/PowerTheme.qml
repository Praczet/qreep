import QtQuick

QtObject {
    id: rootPowerTheme

    required property QtObject qreep

    readonly property int buttonIconPixelSize: 24
    readonly property int sidebarWidth: 360
    readonly property int sidebarMargin: 15
    readonly property int sidebarRadius: 18
    readonly property int sidebarBorderWidth: 1
    readonly property real sidebarOpacity: 0.82
    readonly property color backgroundColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, sidebarOpacity)
    readonly property color borderColor: qreep.outline
    readonly property color actionBackgroundColor: qreep.primary
    readonly property color actionHoverBackgroundColor: qreep.primaryFixedDim
    readonly property color actionTextColor: qreep.on_primary
    readonly property color actionIconColor: qreep.on_primary
    readonly property color confirmTextColor: qreep.on_surface
    readonly property int cardWidth: 260
    readonly property int cardPadding: 20
    readonly property int cardRadius: 18
    readonly property int actionHeight: 54
    readonly property int actionRadius: 10
    readonly property int actionSpacing: 8
    readonly property int actionContentSpacing: 14
    readonly property int actionIconSize: 30
    readonly property real actionIconColorization: 1
    readonly property real actionIconBrightness: 1.2
    readonly property int actionLabelWidth: 92
    readonly property int actionTextPixelSize: 14
    readonly property int confirmTitlePixelSize: 16
    readonly property int confirmContentPixelSize: 12
    readonly property int confirmContentBottomPadding: 10
    readonly property int confirmButtonSpacing: 10
}
