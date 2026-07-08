import QtQuick

QtObject {
    id: rootBloomTheme

    required property QtObject qreep

    readonly property color backgroundColor: Qt.rgba(qreep.background.r, qreep.background.g, qreep.background.b, 0.92)
    readonly property color borderColor: Qt.rgba(qreep.outline.r, qreep.outline.g, qreep.outline.b, 0.55)
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color errorColor: qreep.error
    readonly property int panelHeight: 320
    readonly property int topMargin: 75
    readonly property int cardWidth: 820
    readonly property int cardHeight: 248
    readonly property int cardRadius: 16
    readonly property int cardBorderWidth: 1
    readonly property int contentPadding: 18
    readonly property int wallpaperWidth: 180
    readonly property int contentSpacing: 12
    readonly property int rowSpacing: 4
    readonly property int titlePixelSize: 15
    readonly property int bodyPixelSize: 13
    readonly property int metaPixelSize: 12
    readonly property int progressHeight: 4
    readonly property int autoDismissDelay: 4000
}
