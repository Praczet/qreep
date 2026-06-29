import QtQuick

QtObject {
    id: rootDashboardTheme

    required property QtObject qreep

    readonly property color backgroundColor: qreep.overlaySurfaceBackground
    readonly property color borderColor: qreep.overlaySurfaceBorder
    readonly property real overlayOpacity: 0.35
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
