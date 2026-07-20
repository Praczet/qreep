import QtQuick

QtObject {
    id: rootTriageTheme

    required property QtObject qreep

    readonly property int panelWidth: 980
    readonly property int screenMargin: 20
    readonly property int panelPadding: 16
    readonly property int panelRadius: 8
    readonly property int headerHeight: 54
    readonly property int summaryHeight: 58
    readonly property int actionHeight: 32
    readonly property int searchHeight: 36
    readonly property int listWidth: 330
    readonly property int rowHeight: 54
    readonly property int rowGap: 6
    readonly property int rowRadius: 6
    readonly property int detailGap: 10
    readonly property int decisionPanelHeight: 166
    readonly property int noteHeight: 64
    readonly property int animationDuration: 150

    readonly property int titlePixelSize: 19
    readonly property int bodyPixelSize: 12
    readonly property int metaPixelSize: 10
    readonly property int valuePixelSize: 18

    readonly property real panelOpacity: 0.92
    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, panelOpacity)
    readonly property color controlColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.78)
    readonly property color decisionPanelColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.58)
    readonly property color eventPanelColor: Qt.rgba(qreep.surfaceContainer.r, qreep.surfaceContainer.g, qreep.surfaceContainer.b, 0.98)
    readonly property color eventRowColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.96)
    readonly property color eventRowHoverColor: Qt.rgba(qreep.surfaceContainerHigh.r, qreep.surfaceContainerHigh.g, qreep.surfaceContainerHigh.b, 0.98)
    readonly property color inspectHintColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.94)
    readonly property color inspectHintHoverColor: Qt.rgba(qreep.surfaceContainerHigh.r, qreep.surfaceContainerHigh.g, qreep.surfaceContainerHigh.b, 0.96)
    readonly property color sectionColor: Qt.rgba(qreep.surfaceContainer.r, qreep.surfaceContainer.g, qreep.surfaceContainer.b, 0.72)
    readonly property color hoveredRowColor: Qt.rgba(qreep.surfaceContainerHigh.r, qreep.surfaceContainerHigh.g, qreep.surfaceContainerHigh.b, 0.50)
    readonly property color selectedRowColor: Qt.rgba(qreep.primary.r, qreep.primary.g, qreep.primary.b, 0.18)
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color actionColor: qreep.primary
    readonly property color actionTextColor: qreep.on_primary
    readonly property color dangerColor: Qt.rgba(qreep.error.r, qreep.error.g, qreep.error.b, 0.18)
    readonly property color dangerBorderColor: qreep.error
    readonly property color warningColor: qreep.warningColor
    readonly property color successColor: qreep.successColor
    readonly property color errorColor: qreep.error
    readonly property color borderColor: qreep.outline
    readonly property color focusBorderColor: qreep.primary
}
