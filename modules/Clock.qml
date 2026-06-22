import QtQuick
import "../components" as Components

Components.QreepModule {
    id: rootClock

    property bool showSeconds: false
    property string timeFormat: showSeconds ? "HH:mm:ss" : "HH:mm"
    property string dateFormat: "dd MMM"
    property date currentDate: new Date()
    readonly property Timer minuteTimer: Timer {
        repeat: false
        onTriggered: rootClock.refresh()
    }

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

    onRightClicked: {
        // just send notify via system notification API, no need to use qml notification component
        console.log("Current time:", Qt.formatDateTime(currentDate, timeFormat), "Current date:", Qt.formatDateTime(currentDate, dateFormat));
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

    Component.onCompleted: refresh()
}
