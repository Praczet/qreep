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
    readonly property int eventRevision: events.revision
    readonly property var visibleTodayEvents: {
        eventRevision;
        return events.visibleEventsForToday(currentDate);
    }
    readonly property var upcomingPersonalEvents: {
        eventRevision;

        if (!theme.modules.bar.calendar.showUpcomingPersonalEvents)
            return [];

        return events.upcomingPersonalEvents(
            currentDate,
            theme.modules.bar.calendar.upcomingPersonalEventLimit,
            visibleTodayEvents
        );
    }
    readonly property string eventToolTip: {
        const lines = [];

        if (visibleTodayEvents.length === 0)
            lines.push("No remaining events today");
        else
            lines.push(visibleTodayEvents.map(event => events.eventTimeLabel(event) + "  " + event.title).join("\n"));

        if (upcomingPersonalEvents.length > 0) {
            lines.push("");
            lines.push("Next AD events:");
            lines.push(upcomingPersonalEvents.map(event =>
                events.eventDateLabel(event, currentDate) + "  " + events.eventTimeLabel(event) + "  " + event.title
            ).join("\n"));
        }

        return lines.join("\n");
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

    function toggleSeconds() {
        showSeconds = !showSeconds;
        refresh();
    }

    onMiddleClicked: toggleSeconds()

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

    Component.onCompleted: refresh()
}
