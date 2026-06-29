import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../services" as Services

Item {
    id: rootClockBlock

    required property QtObject theme
    property var config: ({})

    // Optional external service.
    // If you pass one from shell.qml, ClockBlock will use it.
    // Otherwise it creates its own local service.
    property QtObject clockService: null

    readonly property QtObject clock: clockService !== null ? clockService : localClockService

    implicitWidth: numberValue(config.width, 240)
    implicitHeight: numberValue(config.height, 240)

    readonly property int cardPadding: numberValue(config.padding, 0)
    readonly property int textSpacing: numberValue(config.textSpacing, 10)
    readonly property real baseAutoSize: Math.max(24, Math.min(width - cardPadding * 2, height - cardPadding * 2))
    readonly property int timePixelSize: numberValue(config.timePixelSize, Math.round(baseAutoSize * numberValue(config.timeTextScale, 0.12)))
    readonly property int datePixelSize: numberValue(config.datePixelSize, Math.round(baseAutoSize * numberValue(config.dateTextScale, 0.07)))
    readonly property real availableFaceSize: Math.max(24, Math.min(width - cardPadding * 2, height - cardPadding * 2 - textReservedHeight))
    readonly property real dateReservedHeight: (showDate || showDayOfWeek) ? datePixelSize + textSpacing : 0
    readonly property real textReservedHeight: dateReservedHeight
    readonly property real digitalClockYOffset: numberValue(config.digitalClockYOffset, 0.18)

    property real faceSize: Math.min(numberValue(config.faceSize, availableFaceSize), availableFaceSize)

    property color cardColor: colorValue(config.cardColor, theme.modules.dashboard.backgroundColor)
    property color cardBorderColor: colorValue(config.cardBorderColor, theme.modules.dashboard.borderColor)

    property color tickColor: colorValue(config.tickColor, theme.secondaryText)
    property color faceBorderColor: colorValue(config.faceBorderColor, theme.modules.dashboard.borderColor)
    property color faceColor: colorValue(config.faceColor, theme.moduleBackground)
    property real faceOpacity: numberValue(config.faceOpacity, 0.5)

    property color hourHandColor: colorValue(config.hourHandColor, theme.primaryText)
    property color minuteHandColor: colorValue(config.minuteHandColor, theme.calendarHeaderText)
    property color secondHandColor: colorValue(config.secondHandColor, theme.eventIndicator)
    property color centerDotColor: colorValue(config.centerDotColor, theme.primaryText)

    property color timeTextColor: colorValue(config.timeTextColor, theme.primaryText)
    property color dateTextColor: colorValue(config.dateTextColor, theme.secondaryText)

    property bool showHourHand: boolValue(config.showHourHand, true)
    property bool showMinuteHand: boolValue(config.showMinuteHand, true)
    property bool showSecondHand: boolValue(config.showSecondHand, boolValue(config.showSecondsHand, true))
    property bool showHourMarkers: boolValue(config.showHourMarkers, true)
    property bool showMinuteMarkers: boolValue(config.showMinuteMarkers, true)
    property bool showDigitalClock: boolValue(config.showDigitalClock, true)
    property bool showDate: boolValue(config.showDate, true)
    property bool showDayOfWeek: boolValue(config.showDayOfWeek, false)
    property bool showSeconds: boolValue(config.showSeconds, showSecondHand)
    property bool showBackground: boolValue(config.showBackground, true)
    property bool showBorder: boolValue(config.showBorder, true)
    property real hourHandOpacity: numberValue(config.hourHandOpacity, 1)
    property real minuteHandOpacity: numberValue(config.minuteHandOpacity, 1)
    property real secondHandOpacity: numberValue(config.secondHandOpacity, 1)
    readonly property string dateDisplayText: showDate ? clock.currentDateTime.dateText : Qt.formatDateTime(clock.currentDateTime.raw, "dddd")

    Services.ClockService {
        id: localClockService

        config: rootClockBlock.config
        showSeconds: rootClockBlock.showSeconds

        // If dashboard unloads this component, this does not matter.
        // If dashboard only hides it, this stops ticking while hidden.
        active: rootClockBlock.visible
    }

    Rectangle {
        id: card

        anchors.fill: parent
        clip: true
        radius: numberValue(rootClockBlock.config.radius, 18)

        color: rootClockBlock.showBackground ? rootClockBlock.cardColor : "transparent"
        border.width: rootClockBlock.showBorder ? 1 : 0
        border.color: rootClockBlock.cardBorderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: rootClockBlock.cardPadding
            spacing: rootClockBlock.textSpacing

            Item {
                id: analogClock

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: rootClockBlock.faceSize
                Layout.preferredHeight: rootClockBlock.faceSize

                Canvas {
                    id: faceCanvas

                    anchors.fill: parent

                    property color faceBorderColor: rootClockBlock.faceBorderColor
                    property color tickColor: rootClockBlock.tickColor
                    property color faceColor: rootClockBlock.faceColor
                    property real faceOpacity: rootClockBlock.faceOpacity
                    property bool showHourMarkers: rootClockBlock.showHourMarkers
                    property bool showMinuteMarkers: rootClockBlock.showMinuteMarkers

                    onFaceBorderColorChanged: requestPaint()
                    onTickColorChanged: requestPaint()
                    onFaceColorChanged: requestPaint()
                    onFaceOpacityChanged: requestPaint()
                    onShowHourMarkersChanged: requestPaint()
                    onShowMinuteMarkersChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");

                        ctx.clearRect(0, 0, width, height);

                        const size = Math.min(width, height);
                        const cx = width / 2;
                        const cy = height / 2;
                        const radius = size / 2 - 2;

                        // Outer circle
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius - 1, 0, Math.PI * 2, false);
                        ctx.lineWidth = 2;
                        ctx.strokeStyle = faceBorderColor;
                        ctx.fillStyle = faceColor;
                        ctx.globalAlpha = faceOpacity;
                        ctx.stroke();
                        ctx.fill();

                        if (showMinuteMarkers) {
                            for (let i = 0; i < 60; i++) {
                                if (showHourMarkers && i % 5 === 0)
                                    continue;

                                const angle = (i * Math.PI / 30) - Math.PI / 2;
                                const outer = radius - 4;
                                const inner = radius - 8;

                                ctx.beginPath();
                                ctx.moveTo(cx + Math.cos(angle) * inner, cy + Math.sin(angle) * inner);
                                ctx.lineTo(cx + Math.cos(angle) * outer, cy + Math.sin(angle) * outer);
                                ctx.lineWidth = 1;
                                ctx.strokeStyle = tickColor;
                                ctx.globalAlpha = 0.28;
                                ctx.stroke();
                            }
                        }

                        if (showHourMarkers) {
                            for (let i = 0; i < 12; i++) {
                                const angle = (i * Math.PI / 6) - Math.PI / 2;
                                const isQuarter = i % 3 === 0;
                                const outer = radius - 4;
                                const inner = radius - (isQuarter ? 16 : 13);

                                const x1 = cx + Math.cos(angle) * inner;
                                const y1 = cy + Math.sin(angle) * inner;
                                const x2 = cx + Math.cos(angle) * outer;
                                const y2 = cy + Math.sin(angle) * outer;

                                ctx.beginPath();
                                ctx.moveTo(x1, y1);
                                ctx.lineTo(x2, y2);

                                ctx.lineWidth = isQuarter ? 2 : 1.5;
                                ctx.strokeStyle = tickColor;
                                ctx.globalAlpha = isQuarter ? 0.8 : 0.45;
                                ctx.stroke();
                            }
                        }

                        ctx.globalAlpha = 1.0;
                    }
                }

                // Hour hand
                Rectangle {
                    id: hourHand

                    width: 5
                    height: rootClockBlock.faceSize * 0.31
                    radius: width / 2
                    visible: rootClockBlock.showHourHand

                    color: rootClockBlock.hourHandColor
                    opacity: rootClockBlock.hourHandOpacity
                    antialiasing: true

                    x: analogClock.width / 2 - width / 2
                    y: analogClock.height / 2 - height + 1

                    transform: Rotation {
                        origin.x: hourHand.width / 2
                        origin.y: hourHand.height - 1
                        angle: rootClockBlock.clock.currentDateTime.hourAngle
                    }
                }

                // Minute hand
                Rectangle {
                    id: minuteHand

                    width: 5
                    height: rootClockBlock.faceSize * 0.41
                    radius: width / 2
                    visible: rootClockBlock.showMinuteHand

                    color: rootClockBlock.minuteHandColor
                    opacity: rootClockBlock.minuteHandOpacity
                    antialiasing: true

                    x: analogClock.width / 2 - width / 2
                    y: analogClock.height / 2 - height + 1

                    transform: Rotation {
                        origin.x: minuteHand.width / 2
                        origin.y: minuteHand.height - 1
                        angle: rootClockBlock.clock.currentDateTime.minuteAngle
                    }
                }

                // Second hand
                Rectangle {
                    id: secondHand

                    width: 2
                    height: rootClockBlock.faceSize * 0.46
                    radius: width / 2
                    visible: rootClockBlock.showSecondHand

                    color: rootClockBlock.secondHandColor
                    opacity: rootClockBlock.secondHandOpacity
                    antialiasing: true

                    x: analogClock.width / 2 - width / 2
                    y: analogClock.height / 2 - height + 1

                    transform: Rotation {
                        origin.x: secondHand.width / 2
                        origin.y: secondHand.height - 1
                        angle: rootClockBlock.clock.currentDateTime.secondAngle
                    }
                }

                Rectangle {
                    id: centerDot

                    width: 8
                    height: 8
                    radius: 4

                    color: rootClockBlock.centerDotColor
                    antialiasing: true

                    anchors.centerIn: parent
                }

                Text {
                    id: digitalTime

                    visible: rootClockBlock.showDigitalClock

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 + rootClockBlock.faceSize * rootClockBlock.digitalClockYOffset

                    text: rootClockBlock.clock.currentDateTime.timeText
                    color: rootClockBlock.timeTextColor

                    font.pixelSize: rootClockBlock.timePixelSize
                    font.weight: Font.DemiBold
                    font.family: stringValue(rootClockBlock.config.fontFamily, "")
                }
            }

            Text {
                id: dateText

                visible: rootClockBlock.showDate || rootClockBlock.showDayOfWeek
                Layout.alignment: Qt.AlignHCenter

                text: rootClockBlock.dateDisplayText

                color: rootClockBlock.dateTextColor

                font.pixelSize: rootClockBlock.datePixelSize
                font.weight: Font.Normal
                font.family: stringValue(rootClockBlock.config.fontFamily, "")
            }

            Item {
                Layout.fillHeight: true
            }
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
