import QtQuick

Rectangle {
    id: rootClock

    required property QtObject theme

    property string timeFormat: "HH:mm"
    property string dateFormat: "dd MMM"
    property date currentDate: new Date()

    implicitWidth: clockContent.implicitWidth + theme.moduleHorizontalPadding
    implicitHeight: theme.moduleHeight
    radius: theme.moduleRadius
    color: theme.moduleBackground

    function refresh() {
        currentDate = new Date();

        const now = currentDate;
        const millisecondsToNextMinute = 60000 - (now.getSeconds() * 1000 + now.getMilliseconds());

        minuteTimer.interval = Math.max(50, millisecondsToNextMinute);
        minuteTimer.restart();
    }

    Row {
        id: clockContent

        anchors.centerIn: parent
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

    Timer {
        id: minuteTimer

        repeat: false
        onTriggered: rootClock.refresh()
    }

    Component.onCompleted: refresh()
}
