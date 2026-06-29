import QtQuick

QtObject {
    id: rootDashboardTheme

    required property QtObject qreep

    readonly property real overlayOpacity: 0.35
    readonly property real cardOpacity: 0.82
    readonly property color overlayColor: Qt.rgba(qreep.background.r, qreep.background.g, qreep.background.b, overlayOpacity)
    readonly property color backgroundColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, cardOpacity)
    readonly property color containerColor: qreep.surfaceContainer
    readonly property color borderColor: qreep.outline
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color errorColor: qreep.error
    readonly property int placementMargin: 48
    readonly property int defaultCardWidth: 320
    readonly property int defaultCardHeight: 180
    readonly property int cardPadding: 20
    readonly property int cardRadius: 18
    readonly property int cardBorderWidth: 1
    readonly property int contentSpacing: 10
    readonly property int titlePixelSize: 18
    readonly property int bodyPixelSize: 14
    readonly property int metaPixelSize: 12
    readonly property int dividerWidth: 1
    readonly property int enterOffset: 420
    readonly property int animationDuration: 420
}
