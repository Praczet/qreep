import QtQuick

QtObject {
    id: rootClipboardTheme

    required property QtObject qreep

    readonly property string placement: "bottom"
    readonly property int maxItems: 40
    readonly property int panelHeight: 238
    readonly property int panelMargin: 10
    readonly property int panelPadding: 10
    readonly property int headerHeight: 28
    readonly property int searchWidth: 260
    readonly property int typeFilterWidth: 46
    readonly property int cardWidth: 150
    readonly property int cardHeight: 150
    readonly property int cardGap: 10
    readonly property int cardPadding: 8
    readonly property int cardRadius: 7
    readonly property int cardBorderWidth: 1
    readonly property int iconButtonSize: 18
    readonly property int typePixelSize: 14
    readonly property int bodyPixelSize: 11
    readonly property int metaPixelSize: 9
    readonly property int animationDuration: 150

    readonly property real panelOpacity: 0.86
    readonly property real cardOpacity: 0.72
    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, panelOpacity)
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color errorColor: qreep.error
    readonly property color searchColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.82)
    readonly property color headerBackgroundColor: qreep.primaryContainer
    readonly property color headerBackgroundSelected: qreep.primary
    readonly property color headerSelectedTextColor: qreep.on_primary

    readonly property color cardColor: qreep.surfaceContainer
    readonly property color hoveredCardColor: Qt.rgba(qreep.surfaceContainerHigh.r, qreep.surfaceContainerHigh.g, qreep.surfaceContainerHigh.b, 0.82)
    readonly property color selectedCardColor: Qt.rgba(qreep.primary.r, qreep.primary.g, qreep.primary.b, 0.18)

    readonly property color borderColor: qreep.outline
    readonly property color hoveredBorderColor: withAlpha(qreep.primary, 0.55)
    readonly property color selectedBorderColor: qreep.primary

    readonly property color cardGlowOuter: withAlpha(qreep.primary, 0.55)
    readonly property color cardGlowBloom: withAlpha(qreep.secondary, 0.42)
    readonly property color cardGlowInner: withAlpha(qreep.on_surface, 0.35)
    readonly property color hoveredGlowColor: withAlpha(qreep.primary, 0.24)

    readonly property color cardGlowBorder: qreep.primaryFixed
    readonly property color cardGlowBorderStrong: qreep.on_surface

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
