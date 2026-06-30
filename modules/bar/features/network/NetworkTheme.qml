import QtQuick

QtObject {
    id: rootNetworkTheme

    required property QtObject qreep

    readonly property int buttonIconPixelSize: 22
    readonly property int buttonContentSpacing: 8
    readonly property color activeColor: qreep.primary
    readonly property color inactiveColor: qreep.on_surface_variant
    readonly property real inactiveOpacity: 0.35
    readonly property real activeOpacity: 1.0

    readonly property int panelWidth: 560
    readonly property int panelMaxHeight: 680
    readonly property int panelTopOffset: 8
    readonly property int panelPadding: 14
    readonly property int panelRadius: 10
    readonly property int sectionSpacing: 10
    readonly property int rowSpacing: 7
    readonly property int sectionPadding: 10
    readonly property int sectionRadius: 8
    readonly property int titlePixelSize: 15
    readonly property int bodyPixelSize: 12
    readonly property int iconPixelSize: 18
    readonly property int actionHeight: 28
    readonly property int actionPadding: 10
    readonly property int actionRadius: 6
    readonly property int inputHeight: 30
    readonly property color panelBackgroundColor: qreep.surface
    readonly property color sectionBackgroundColor: qreep.surfaceContainer
    readonly property color rowBackgroundColor: qreep.surfaceContainerLow
    readonly property color rowHoverBackgroundColor: qreep.surfaceContainerHigh
    readonly property color borderColor: qreep.outlineVariant
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color actionBackgroundColor: qreep.surfaceContainerHigh
    readonly property color actionTextColor: qreep.primary
}
