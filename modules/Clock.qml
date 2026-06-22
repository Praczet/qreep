import QtQuick
import "../components" as Components

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
        const refreshInterval = showSeconds ? 1000 : 60000;
        const elapsedInInterval = showSeconds ? now.getMilliseconds() : now.getSeconds() * 1000 + now.getMilliseconds();
        const millisecondsToNextRefresh = refreshInterval - elapsedInInterval;

        minuteTimer.interval = Math.max(50, millisecondsToNextRefresh);
        minuteTimer.restart();
    }

    onClicked: {
        showSeconds = !showSeconds;
        refresh();
    }

    Row {
        id: clockContent

        spacing: rootClock.theme.moduleSpacing

        Text {
            text: Qt.formatDateTime(rootClock.currentDate, rootClock.timeFormat)
            color: rootClock.theme.primaryText
            font.pixelSize: rootClock.theme.clockTimePixelSize
            font.weight: Font.DemiBold
        }

        Text {
            anchors.verticalCenter: parent.children[0].verticalCenter
            text: Qt.formatDateTime(rootClock.currentDate, rootClock.dateFormat)
            color: rootClock.theme.secondaryText
            font.pixelSize: rootClock.theme.clockDatePixelSize
            font.weight: Font.Medium
        }
    }

    overlay: Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.bottom
        }

        spacing: 4
        visible: rootClock.visibleTodayEvents.length > 0

        Repeater {
            model: Math.min(rootClock.visibleTodayEvents.length, 5)

            delegate: Rectangle {
                required property int index

                width: 8
                height: 8
                radius: 4
                color: rootClock.theme.eventIndicator
            }
        }
    }

    Component.onCompleted: refresh()
}
