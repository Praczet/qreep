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

    implicitWidth: numberValue(config.width, 490)
    implicitHeight: numberValue(config.height, 306)

    property real faceSize: numberValue(config.faceSize, 224)

    property color cardColor: colorValue(config.cardColor, "#303846")
    property color cardBorderColor: colorValue(config.cardBorderColor, "#3c4658")

    property color faceBorderColor: colorValue(config.faceBorderColor, "#455068")
    property color tickColor: colorValue(config.tickColor, "#56617a")

    property color hourHandColor: colorValue(config.hourHandColor, "#93a0c9")
    property color minuteHandColor: colorValue(config.minuteHandColor, "#a1add6")
    property color secondHandColor: colorValue(config.secondHandColor, "#d56b78")
    property color centerDotColor: colorValue(config.centerDotColor, "#8f9bc3")

    property color timeTextColor: colorValue(config.timeTextColor, "#aab7e0")
    property color dateTextColor: colorValue(config.dateTextColor, "#9aa8cf")

    Services.ClockService {
        id: localClockService

        config: rootClockBlock.config
        showSeconds: true

        // If dashboard unloads this component, this does not matter.
        // If dashboard only hides it, this stops ticking while hidden.
        active: rootClockBlock.visible
    }

    Rectangle {
        id: card

        anchors.fill: parent
        radius: numberValue(rootClockBlock.config.radius, 18)

        color: rootClockBlock.cardColor
        border.width: 1
        border.color: rootClockBlock.cardBorderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

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

                    onFaceBorderColorChanged: requestPaint()
                    onTickColorChanged: requestPaint()
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
                        ctx.globalAlpha = 0.85;
                        ctx.stroke();

                        // Hour ticks
                        for (let i = 0; i < 12; i++) {
                            const angle = (i * Math.PI / 6) - Math.PI / 2;

                            const isQuarter = i % 3 === 0;
                            const outer = radius - 10;
                            const inner = radius - (isQuarter ? 20 : 17);

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

                        ctx.globalAlpha = 1.0;
                    }
                }

                // Hour hand
                Rectangle {
                    id: hourHand

                    width: 5
                    height: rootClockBlock.faceSize * 0.31
                    radius: width / 2

                    color: rootClockBlock.hourHandColor
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

                    color: rootClockBlock.minuteHandColor
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

                    color: rootClockBlock.secondHandColor
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

                    text: rootClockBlock.clock.currentDateTime.timeText

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 + rootClockBlock.faceSize * 0.23

                    color: rootClockBlock.timeTextColor

                    font.pixelSize: numberValue(rootClockBlock.config.timePixelSize, 31)
                    font.weight: Font.DemiBold
                    font.family: stringValue(rootClockBlock.config.fontFamily, "")
                }
            }

            Text {
                id: dateText

                Layout.alignment: Qt.AlignHCenter

                text: rootClockBlock.clock.currentDateTime.dateText

                color: rootClockBlock.dateTextColor

                font.pixelSize: numberValue(rootClockBlock.config.datePixelSize, 16)
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

    function colorValue(value, fallback) {
        return typeof value === "string" && value.length > 0 ? value : fallback;
    }
}
