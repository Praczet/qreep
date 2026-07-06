import QtQuick

QtObject {
    id: rootAegisTheme

    required property QtObject qreep

    readonly property real overlayOpacity: 0.35
    readonly property real panelOpacity: 0.94
    readonly property real cardOpacity: 0.86

    readonly property color overlayColor: Qt.rgba(qreep.background.r, qreep.background.g, qreep.background.b, overlayOpacity)
    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, panelOpacity)
    readonly property color cardColor: Qt.rgba(qreep.surfaceContainer.r, qreep.surfaceContainer.g, qreep.surfaceContainer.b, cardOpacity)
    readonly property color subtleCardColor: Qt.rgba(qreep.surfaceContainerHigh.r, qreep.surfaceContainerHigh.g, qreep.surfaceContainerHigh.b, 0.54)
    readonly property color borderColor: qreep.outline
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color successColor: qreep.successColor
    readonly property color warningColor: qreep.warningColor
    readonly property color errorColor: qreep.error

    readonly property int panelWidth: 1260
    readonly property int panelHeight: 900
    readonly property int panelPadding: 26
    readonly property int panelRadius: 20
    readonly property int cardRadius: 16
    readonly property int cardPadding: 18
    readonly property int cardGap: 14
    readonly property int rowGap: 7
    readonly property int sectionTitlePixelSize: 15
    readonly property int headingPixelSize: 28
    readonly property int titlePixelSize: 18
    readonly property int bodyPixelSize: 13
    readonly property int metaPixelSize: 12
    readonly property int iconPixelSize: 26
    readonly property int heroIconSize: 64
    readonly property int graphBarHeight: 10
    readonly property int pieSize: 150
    readonly property int enterOffset: 420
    readonly property int animationDuration: 420
    readonly property int refreshInterval: 15000
    readonly property int cpuRefreshInterval: 1000
}
