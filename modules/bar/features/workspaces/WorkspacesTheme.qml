import QtQuick

QtObject {
    id: rootWorkspacesTheme

    readonly property bool showEmptyWorkspaces: false
    readonly property bool showSpecialWorkspaces: true
    readonly property string indicatorMode: "count"
    readonly property int normalWorkspaceStart: 1
    readonly property int normalWorkspaceEnd: 10
    readonly property bool useHyprlandEvents: true
    readonly property int refreshInterval: 10000
    readonly property int eventRefreshDelay: 60
    readonly property int refreshAfterDispatchDelay: 120
    property color backgroundColor: "#242933"
    property color borderColor: "#3b4252"
    readonly property real activeOpacity: 1
    readonly property real inactiveOpacity: 0.42
    readonly property real emptyOpacity: 0.16
    readonly property real hoverOpacity: 1
    readonly property real hoverScale: 1.18
    readonly property real inactiveBackgroundOpacity: 0.18
    readonly property real emptyBackgroundOpacity: 0.08
    readonly property real hoverBackgroundOpacity: 0.36
    readonly property real specialActiveBackgroundOpacity: 0.18
    readonly property real specialActiveBorderOpacity: 0.9
    readonly property int specialActiveBorderWidth: 2
    readonly property int hoverAnimationDuration: 120
    readonly property int itemHeight: 34
    readonly property int itemMinWidth: 34
    readonly property int itemHorizontalPadding: 16
    readonly property int itemRadius: 11
    readonly property int itemSpacing: 4
    readonly property int contentSpacing: 6
    readonly property int numberTextPixelSize: 14
    readonly property int specialTextPixelSize: 13
    readonly property int countTextPixelSize: 11
    readonly property int dotSize: 4
    readonly property int maxDots: 4
    readonly property int tooltipWidth: 360
    readonly property int tooltipRowHeight: 34
    readonly property int tooltipIconSize: 20
    readonly property int tooltipRowRadius: 7
    readonly property int tooltipRowSpacing: 4
    readonly property int tooltipContentSpacing: 10
    readonly property int tooltipTitlePixelSize: 13
    readonly property int tooltipWindowPixelSize: 12
    readonly property int tooltipMaxWindows: 8
}
