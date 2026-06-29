import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../services" as Services

Item {
    id: rootDigitalClockBlock

    required property QtObject theme
    property var config: ({})
    property QtObject clockService: null

    readonly property QtObject clock: clockService !== null ? clockService : localClockService

    implicitWidth: numberValue(config.width, 360)
    implicitHeight: numberValue(config.height, 140)

    readonly property int padding: numberValue(config.padding, 18)
    readonly property int textSpacing: numberValue(config.textSpacing, 8)
    readonly property real baseAutoSize: Math.max(24, Math.min(width - padding * 2, height - padding * 2))
    readonly property int timePixelSize: numberValue(config.timePixelSize, Math.round(baseAutoSize * numberValue(config.timeTextScale, 0.48)))
    readonly property int datePixelSize: numberValue(config.datePixelSize, Math.round(baseAutoSize * numberValue(config.dateTextScale, 0.12)))

    property bool showTime: boolValue(config.showTime, true)
    property bool showDate: boolValue(config.showDate, true)
    property bool showDayOfWeek: boolValue(config.showDayOfWeek, false)
    property bool showSeconds: boolValue(config.showSeconds, false)

    property color timeTextColor: colorValue(config.timeTextColor, theme.primaryText)
    property color dateTextColor: colorValue(config.dateTextColor, theme.secondaryText)

    readonly property string timeText: showSeconds ? clock.currentDateTime.timeWithSecondsText : clock.currentDateTime.timeText
    readonly property string dateDisplayText: showDate ? clock.currentDateTime.dateText : Qt.formatDateTime(clock.currentDateTime.raw, "dddd")

    Services.ClockService {
        id: localClockService

        config: rootDigitalClockBlock.config
        showSeconds: rootDigitalClockBlock.showSeconds
        active: rootDigitalClockBlock.visible
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: rootDigitalClockBlock.padding
        }
        spacing: rootDigitalClockBlock.textSpacing

        Item {
            Layout.fillHeight: true
        }

        Text {
            visible: rootDigitalClockBlock.showTime
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true

            text: rootDigitalClockBlock.timeText
            color: rootDigitalClockBlock.timeTextColor
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight

            font.pixelSize: rootDigitalClockBlock.timePixelSize
            font.weight: Font.DemiBold
            font.family: stringValue(rootDigitalClockBlock.config.fontFamily, "")
        }

        Text {
            visible: rootDigitalClockBlock.showDate || rootDigitalClockBlock.showDayOfWeek
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true

            text: rootDigitalClockBlock.dateDisplayText
            color: rootDigitalClockBlock.dateTextColor
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight

            font.pixelSize: rootDigitalClockBlock.datePixelSize
            font.weight: Font.Normal
            font.family: stringValue(rootDigitalClockBlock.config.fontFamily, "")
        }

        Item {
            Layout.fillHeight: true
        }
    }

    function stringValue(value, fallback) {
        return typeof value === "string" && value.length > 0 ? value : fallback;
    }

    function numberValue(value, fallback) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function boolValue(value, fallback) {
        return typeof value === "boolean" ? value : fallback;
    }

    function colorValue(value, fallback) {
        if (typeof value !== "string" || value.length === 0)
            return fallback;

        switch (value) {
        case "{{primary}}":
            return theme.primaryText;
        case "{{secondary}}":
            return theme.secondaryText;
        case "{{background}}":
            return theme.barBackground;
        case "{{surface}}":
            return theme.modules.dashboard.backgroundColor;
        case "{{surface_border}}":
            return theme.modules.dashboard.borderColor;
        case "{{accent}}":
            return theme.eventIndicator;
        case "{{module}}":
            return theme.moduleBackground;
        case "{{module_hover}}":
            return theme.moduleHoverBackground;
        case "{{calendar_background}}":
            return theme.calendarBackground;
        case "{{calendar_header}}":
            return theme.calendarHeaderText;
        case "{{calendar_day}}":
            return theme.calendarDayText;
        case "{{error}}":
            return theme.borg.errorColor;
        default:
            return value;
        }
    }
}
