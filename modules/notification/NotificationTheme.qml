import QtQuick

QtObject {
    id: rootNotificationTheme

    required property QtObject qreep

    readonly property int animationDuration: 150
    readonly property int maxPopupItems: 4
    readonly property int popupTimeout: 5200
    readonly property int popupWidth: 360
    readonly property int popupTopMargin: 80
    readonly property int popupRightMargin: 12
    readonly property int centerWidth: 440
    readonly property int centerMargin: 12
    readonly property int centerTopMargin: 48
    readonly property int panelPadding: 12
    readonly property int panelRadius: 8
    readonly property int cardPadding: 10
    readonly property int groupPadding: 8
    readonly property int cardRadius: 7
    readonly property int cardGap: 8
    readonly property int contentGap: 8
    readonly property int sectionGap: 12
    readonly property int headerHeight: 42
    readonly property int iconSize: 30
    readonly property int appIconSize: 54
    readonly property int appImagePreviewSize: 74
    readonly property int colorPickerIconSize: 42
    readonly property int colorBadgeWidth: 132
    readonly property int colorBadgeHeight: 48
    readonly property int foldButtonSize: 20
    readonly property int groupClearButtonSize: 20
    readonly property int closeButtonSize: 22
    readonly property int actionHeight: 24
    readonly property int imagePreviewHeight: 112
    readonly property int cardBorderWidth: 1
    readonly property int headingPixelSize: 18
    readonly property int titlePixelSize: 13
    readonly property int bodyPixelSize: 11
    readonly property int metaPixelSize: 10
    readonly property int closePixelSize: 13

    readonly property color overlayColor: Qt.rgba(qreep.background.r, qreep.background.g, qreep.background.b, 0.42)
    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, 0.92)
    readonly property color cardColor: Qt.rgba(qreep.surfaceContainer.r, qreep.surfaceContainer.g, qreep.surfaceContainer.b, 0.88)
    readonly property color cardHoverColor: Qt.rgba(qreep.surfaceContainerHigh.r, qreep.surfaceContainerHigh.g, qreep.surfaceContainerHigh.b, 0.94)
    readonly property color groupColor: Qt.rgba(qreep.surfaceContainerLow.r, qreep.surfaceContainerLow.g, qreep.surfaceContainerLow.b, 0.72)
    readonly property color controlColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.72)
    readonly property color selectedControlColor: Qt.rgba(qreep.primary.r, qreep.primary.g, qreep.primary.b, 0.2)
    readonly property color actionColor: Qt.rgba(qreep.surfaceContainerHighest.r, qreep.surfaceContainerHighest.g, qreep.surfaceContainerHighest.b, 0.56)
    readonly property color actionHoverColor: Qt.rgba(qreep.primary.r, qreep.primary.g, qreep.primary.b, 0.18)
    readonly property color closeButtonHoverColor: Qt.rgba(qreep.error.r, qreep.error.g, qreep.error.b, 0.18)
    readonly property color borderColor: Qt.rgba(qreep.outline.r, qreep.outline.g, qreep.outline.b, 0.72)
    readonly property color selectedBorderColor: qreep.primary
    readonly property color criticalBorderColor: qreep.error
    readonly property color criticalTextColor: qreep.error
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
}
