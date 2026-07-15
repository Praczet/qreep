import QtQuick

QtObject {
    id: rootFastPasswordTheme

    required property QtObject qreep

    readonly property int panelWidth: 720
    readonly property int panelHeight: 520
    readonly property int screenMargin: 32
    readonly property int panelPadding: 16
    readonly property int panelRadius: 8
    readonly property int controlRadius: 6
    readonly property int headerHeight: 54
    readonly property int searchHeight: 38
    readonly property int searchPadding: 12
    readonly property int iconBoxSize: 48
    readonly property int statusWidth: 150
    readonly property int contentGap: 10
    readonly property int rowHeight: 54
    readonly property int rowGap: 6
    readonly property int rowRadius: 6
    readonly property int rowPadding: 10
    readonly property int rowVerticalPadding: 9
    readonly property int rowIconWidth: 42
    readonly property int titlePixelSize: 19
    readonly property int titleIconPixelSize: 22
    readonly property int rowIconPixelSize: 26
    readonly property int bodyPixelSize: 13
    readonly property int metaPixelSize: 10
    readonly property int animationDuration: 150

    readonly property real panelOpacity: 0.9
    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, panelOpacity)
    readonly property color controlColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.78)
    readonly property color hoveredRowColor: Qt.rgba(qreep.surfaceContainerHigh.r, qreep.surfaceContainerHigh.g, qreep.surfaceContainerHigh.b, 0.5)
    readonly property color selectedRowColor: Qt.rgba(qreep.primary.r, qreep.primary.g, qreep.primary.b, 0.18)
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color errorColor: qreep.error
    readonly property color borderColor: qreep.outline
    readonly property color focusBorderColor: qreep.primary
}
