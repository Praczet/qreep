import QtQuick

QtObject {
    id: rootTimerTheme

    required property QtObject qreep

    readonly property int panelWidth: 520
    readonly property int panelMinMargin: 18
    readonly property int panelPadding: 18
    readonly property int panelRadius: 12
    readonly property int headerHeight: 28
    readonly property int displayHeight: 92
    readonly property int fieldHeight: 34
    readonly property int buttonHeight: 34
    readonly property int smallButtonWidth: 70
    readonly property int actionButtonWidth: 112
    readonly property int gap: 10
    readonly property int animationDuration: 150
    readonly property int pillContentSpacing: 8
    readonly property int pillPieSize: 24
    readonly property int pillPieStrokeWidth: 2
    readonly property int pillTimePixelSize: 14
    readonly property int pillDonePixelSize: 12

    readonly property int labelPixelSize: 11
    readonly property int bodyPixelSize: 12
    readonly property int titlePixelSize: 15
    readonly property int displayPixelSize: 44
    readonly property int metaPixelSize: 10

    readonly property real panelOpacity: 0.9
    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, panelOpacity)
    readonly property color panelBorderColor: qreep.outline
    readonly property color fieldColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.84)
    readonly property color fieldBorderColor: qreep.outline
    readonly property color focusBorderColor: qreep.primary
    readonly property color activeColor: Qt.rgba(qreep.primary.r, qreep.primary.g, qreep.primary.b, 0.22)
    readonly property color activeBorderColor: qreep.primary
    readonly property color progressTrackColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.74)
    readonly property color progressFillColor: qreep.primary
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentTextColor: qreep.primary
    readonly property color errorTextColor: qreep.error
    readonly property color actionColor: qreep.primary
    readonly property color actionTextColor: qreep.on_primary
    readonly property color dangerColor: Qt.rgba(qreep.error.r, qreep.error.g, qreep.error.b, 0.20)
    readonly property color dangerBorderColor: qreep.error
}
