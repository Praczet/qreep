import QtQuick

QtObject {
    id: rootOsdTheme

    readonly property int panelHeight: 160
    readonly property int topMargin: 58
    readonly property int screenPadding: 24
    readonly property int horizontalPadding: 22
    readonly property int verticalPadding: 14
    readonly property int radius: 14
    readonly property int borderWidth: 1
    readonly property real opacity: 0.5
    readonly property int titleTextPixelSize: 15
    readonly property int messageTextPixelSize: 13
    readonly property int iconSize: 30
    readonly property int contentSpacing: 12
    readonly property int textSpacing: 3
    readonly property int progressCardWidth: 450
    readonly property int progressIconSize: 84
    readonly property int progressTitleTextPixelSize: 30
    readonly property int progressMessageTextPixelSize: 18
    readonly property int progressHeight: 8
    readonly property int progressSpacing: 18
    readonly property int playerQueryDelay: 120
    readonly property int defaultDuration: 1600
    readonly property string defaultPosition: "bottom"
    readonly property int testButtonLeftMargin: 4
    readonly property int testButtonTextPixelSize: 13
}
