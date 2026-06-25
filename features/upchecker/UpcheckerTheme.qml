import QtQuick

QtObject {
    id: rootUpcheckerTheme

    readonly property int buttonIconPixelSize: 24
    readonly property int buttonTextPixelSize: 14
    readonly property int buttonContentSpacing: 8
    readonly property string updateTerminalCommand: "ghostty"
    readonly property string updateCommand: "update-btw"
    readonly property int windowWidth: 1200
    readonly property int screenMargin: 48
    readonly property int topMargin: 104
    readonly property int bottomMargin: 48
    readonly property int radius: 16
    readonly property int borderWidth: 1
    readonly property int contentPadding: 20
    readonly property int titleBottomMargin: 24
    readonly property int titlePixelSize: 28
    readonly property int emptyTextPixelSize: 14
    readonly property int paneSpacing: 20
    readonly property int rowHeight: 46
    readonly property int rowRadius: 8
    readonly property int rowSpacing: 10
    readonly property int rowHorizontalPadding: 24
    readonly property int rowTextPixelSize: 15
    readonly property int versionWidth: 92
    readonly property int versionSpacing: 12
    readonly property int scrollbarReserve: 12
    readonly property int selectedBorderWidth: 1
    readonly property int detailPadding: 20
    readonly property int detailSpacing: 18
    readonly property int detailHeaderHeight: 48
    readonly property int detailHeaderPadding: 12
    readonly property int detailTitlePixelSize: 22
    readonly property int detailVersionPixelSize: 20
    readonly property int detailVersionWidth: 150
    readonly property int descriptionPixelSize: 15
    readonly property int descriptionHorizontalInset: 120
    readonly property int metaLabelWidth: 92
    readonly property int metaTextPixelSize: 13
    readonly property int metaRowSpacing: 6
    readonly property int dependencyPreviewLimit: 12
    readonly property real dimOpacity: 0.55
    readonly property real pulseScale: 1.22
    readonly property real pulseSettleScale: 0.96
    readonly property real pulseRotation: 6
    readonly property real pulseRotationSettle: 2
    readonly property int pulseOutDuration: 160
    readonly property int pulseSettleDuration: 140
    readonly property int pulseInDuration: 180
    readonly property int actionButtonWidth: 72
    readonly property int actionButtonHeight: 32
    readonly property int actionButtonRadius: 4
}
