import QtQuick

QtObject {
    id: rootPolkitTheme

    required property QtObject qreep

    readonly property int panelWidth: 850
    readonly property int panelPadding: 18
    readonly property int panelRadius: 15
    readonly property int sectionSpacing: 14
    readonly property int fieldHeight: 36
    readonly property int buttonHeight: 32
    readonly property int buttonWidth: 118
    readonly property int iconBoxSize: 50
    readonly property int iconSize: 30
    readonly property int artworkRailWidth: 296
    readonly property int titlePixelSize: 17
    readonly property int bodyPixelSize: 12
    readonly property int metaPixelSize: 10
    readonly property int detailPixelSize: 9
    readonly property int actionPixelSize: 11
    readonly property int animationDuration: 150

    readonly property color overlayColor: Qt.rgba(qreep.background.r, qreep.background.g, qreep.background.b, 0.42)
    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, 0.94)
    readonly property color fieldColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.74)
    readonly property color actionColor: qreep.primary
    readonly property color actionTextColor: qreep.on_primary
    readonly property color quietActionColor: Qt.rgba(qreep.surfaceContainerHigh.r, qreep.surfaceContainerHigh.g, qreep.surfaceContainerHigh.b, 0.82)
    readonly property color quietActionTextColor: qreep.on_surface
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color borderColor: qreep.outline
    readonly property color focusBorderColor: qreep.primary
    readonly property color errorColor: qreep.error
    readonly property color successColor: qreep.successColor
}
