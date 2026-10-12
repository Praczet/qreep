import QtQuick

QtObject {
    id: rootScreenshotTheme

    required property QtObject qreep

    readonly property int panelWidth: 410
    readonly property int panelPadding: 20
    readonly property int panelRadius: 9
    readonly property int screenMargin: 24
    readonly property int sectionSpacing: 16
    readonly property int rowSpacing: 12
    readonly property int labelWidth: 58
    readonly property int fieldHeight: 38
    readonly property int delayFieldWidth: 150
    readonly property int stepButtonWidth: 34
    readonly property int backendWidth: 252
    readonly property int backendButtonWidth: 126
    readonly property int buttonWidth: 88
    readonly property int buttonHeight: 36
    readonly property int controlRadius: 6
    readonly property int titlePixelSize: 18
    readonly property int bodyPixelSize: 13
    readonly property int metaPixelSize: 11
    readonly property int animationDuration: 120
    readonly property int launchDelay: 90

    readonly property real panelOpacity: 0.94
    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, panelOpacity)
    readonly property color controlColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.82)
    readonly property color selectedColor: Qt.rgba(qreep.primary.r, qreep.primary.g, qreep.primary.b, 0.2)
    readonly property color hoverColor: Qt.rgba(qreep.surfaceContainerHigh.r, qreep.surfaceContainerHigh.g, qreep.surfaceContainerHigh.b, 0.72)
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color borderColor: qreep.outline
    readonly property color focusBorderColor: qreep.primary
}
