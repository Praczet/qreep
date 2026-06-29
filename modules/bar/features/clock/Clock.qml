import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootClock

    required property QtObject events

    property bool showSeconds: false
    property string timeFormat: showSeconds ? "HH:mm:ss" : "HH:mm"
    property string dateFormat: "dd MMM"
    property date currentDate: new Date()
    readonly property Timer minuteTimer: Timer {
        repeat: false
        onTriggered: rootClock.refresh()
    }
    readonly property var visibleTodayEvents: events.visibleEventsForToday(currentDate)
    readonly property string eventToolTip: {
        if (visibleTodayEvents.length === 0)
            return "No remaining events today";

        return visibleTodayEvents.map(event => events.eventTimeLabel(event) + "  " + event.title).join("\n");
    }

    tooltipTitle: "Today's events"
    tooltipContent: eventToolTip

    function refresh() {
        currentDate = new Date();

        const now = currentDate;
        const refreshInterval = showSeconds ? rootClock.theme.modules.bar.clock.secondRefreshInterval : rootClock.theme.modules.bar.clock.minuteRefreshInterval;
        const elapsedInInterval = showSeconds ? now.getMilliseconds() : now.getSeconds() * rootClock.theme.modules.bar.clock.secondRefreshInterval + now.getMilliseconds();
        const millisecondsToNextRefresh = refreshInterval - elapsedInInterval;

        minuteTimer.interval = Math.max(rootClock.theme.modules.bar.clock.minimumRefreshInterval, millisecondsToNextRefresh);
        minuteTimer.restart();
    }

    onClicked: {
        showSeconds = !showSeconds;
        refresh();
    }

    Row {
        id: clockContent

        spacing: rootClock.theme.modules.bar.pill.spacing

        Text {
            text: Qt.formatDateTime(rootClock.currentDate, rootClock.timeFormat)
            color: rootClock.theme.modules.bar.primaryTextColor
            font.pixelSize: rootClock.theme.modules.bar.clock.timePixelSize
            font.weight: Font.DemiBold
        }

        Text {
            anchors.verticalCenter: parent.children[0].verticalCenter
            text: Qt.formatDateTime(rootClock.currentDate, rootClock.dateFormat)
            color: rootClock.theme.modules.bar.secondaryTextColor
            font.pixelSize: rootClock.theme.modules.bar.clock.datePixelSize
            font.weight: Font.Medium
        }
    }

    overlay: Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.bottom
        }

        spacing: rootClock.theme.modules.bar.clock.eventIndicatorSpacing
        visible: rootClock.visibleTodayEvents.length > 0

        Repeater {
            model: Math.min(rootClock.visibleTodayEvents.length, rootClock.theme.modules.bar.clock.maxEventIndicators)

            delegate: Rectangle {
                required property int index

                width: rootClock.theme.modules.bar.clock.eventIndicatorSize
                height: rootClock.theme.modules.bar.clock.eventIndicatorSize
                radius: rootClock.theme.modules.bar.clock.eventIndicatorRadius
                color: rootClock.theme.modules.bar.accentColor
            }
        }
    }

    Component.onCompleted: refresh()
}
