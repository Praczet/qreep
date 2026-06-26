import QtQuick
import Quickshell

Scope {
    id: rootClockService

    property var config: ({})

    property bool showSeconds: true
    property bool active: true

    property string timeFormat: stringValue(config.timeFormat, "24h")
    property string dateFormat: stringValue(config.dateFormat, "dddd, yyyy-MM-dd")

    SystemClock {
        id: systemClock

        enabled: rootClockService.active
        precision: rootClockService.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    readonly property var currentDateTime: buildDateTime(systemClock.date)

    function stringValue(value, fallback) {
        return typeof value === "string" && value.length > 0 ? value : fallback;
    }

    function pad2(value) {
        return String(value).padStart(2, "0");
    }

    function buildDateTime(now) {
        const hours = now.getHours();
        const minutes = now.getMinutes();
        const seconds = now.getSeconds();

        const hourAngle = ((hours % 12) * 30) + (minutes * 0.5);
        const minuteAngle = (minutes * 6) + (seconds * 0.1);
        const secondAngle = seconds * 6;

        const timeText = rootClockService.timeFormat === "12h" ? Qt.formatDateTime(now, "hh:mm AP") : Qt.formatDateTime(now, "HH:mm");

        return {
            raw: now,
            hh: hours,
            mm: minutes,
            ss: seconds,
            hhText: pad2(hours),
            mmText: pad2(minutes),
            ssText: pad2(seconds),
            timeText: timeText,
            timeWithSecondsText: Qt.formatDateTime(now, "HH:mm:ss"),
            dateText: Qt.formatDateTime(now, rootClockService.dateFormat),
            hourAngle: hourAngle,
            minuteAngle: minuteAngle,
            secondAngle: secondAngle
        };
    }
}
