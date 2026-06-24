import QtQuick

QtObject {
    id: rootClockTheme

    readonly property int timePixelSize: 42
    readonly property int datePixelSize: 14
    readonly property int secondRefreshInterval: 1000
    readonly property int minuteRefreshInterval: 60000
    readonly property int minimumRefreshInterval: 50
    readonly property int eventIndicatorSize: 8
    readonly property int eventIndicatorRadius: 4
    readonly property int eventIndicatorSpacing: 4
    readonly property int maxEventIndicators: 5
}
