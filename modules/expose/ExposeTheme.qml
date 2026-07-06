import QtQuick

QtObject {
    id: rootExposeTheme

    required property QtObject qreep

    readonly property int animationDuration: 150
    readonly property int panelMargin: 48
    readonly property int panelPadding: 24
    readonly property int sectionGap: 24
    readonly property int cardGap: 16
    readonly property int currentCardWidth: 380
    readonly property int currentCardHeight: 250
    readonly property int currentCardPreviewHeight: 150
    readonly property int clusterWidth: 340
    readonly property int clusterMinHeight: 180
    readonly property int miniCardWidth: 136
    readonly property int miniCardHeight: 74
    readonly property int maxClusterClients: 8
    readonly property int cardRadius: 8
    readonly property int previewRadius: 7
    readonly property int borderWidth: 1
    readonly property int selectedBorderWidth: 2
    readonly property int iconSize: 42
    readonly property int miniIconSize: 24
    readonly property int titlePixelSize: 16
    readonly property int subtitlePixelSize: 12
    readonly property int clusterTitlePixelSize: 15
    readonly property int clusterCountPixelSize: 12
    readonly property real overlayOpacity: 0.88
    readonly property real inactiveCardOpacity: 0.74
    readonly property real selectedScale: 1.035
    readonly property bool useScreencopy: false

    readonly property color overlayColor: Qt.rgba(qreep.background.r, qreep.background.g, qreep.background.b, overlayOpacity)
    readonly property color cardColor: Qt.rgba(qreep.surfaceContainer.r, qreep.surfaceContainer.g, qreep.surfaceContainer.b, 0.88)
    readonly property color cardHoverColor: Qt.rgba(qreep.surfaceContainerHigh.r, qreep.surfaceContainerHigh.g, qreep.surfaceContainerHigh.b, 0.94)
    readonly property color previewColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.72)
    readonly property color borderColor: Qt.rgba(qreep.outline.r, qreep.outline.g, qreep.outline.b, 0.72)
    readonly property color selectedBorderColor: qreep.primary
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color badgeColor: qreep.primary
    readonly property color badgeTextColor: qreep.on_primary
}
