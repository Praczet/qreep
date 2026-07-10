import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootTimerButton

    required property QtObject service

    tooltipTitle: "Timer"
    tooltipContent: tooltipText()
    tooltipStyle: service.done ? "warning" : "normal"

    Row {
        id: timerContent

        spacing: rootTimerButton.theme.modules.timer.pillContentSpacing

        Item {
            id: countdownPie

            width: rootTimerButton.theme.modules.timer.pillPieSize
            height: width
            visible: rootTimerButton.service.isCountdown

            Canvas {
                id: pieCanvas

                anchors.fill: parent

                onPaint: {
                    const ctx = getContext("2d");
                    const center = width / 2;
                    const radius = Math.max(1, width / 2 - rootTimerButton.theme.modules.timer.pillPieStrokeWidth);
                    const start = -Math.PI / 2;
                    const end = start + Math.PI * 2 * rootTimerButton.service.progress;

                    ctx.reset();
                    ctx.clearRect(0, 0, width, height);

                    ctx.beginPath();
                    ctx.arc(center, center, radius, 0, Math.PI * 2, false);
                    ctx.lineWidth = rootTimerButton.theme.modules.timer.pillPieStrokeWidth;
                    ctx.strokeStyle = rootTimerButton.theme.modules.timer.progressTrackColor;
                    ctx.stroke();

                    if (rootTimerButton.service.progress > 0) {
                        ctx.beginPath();
                        ctx.moveTo(center, center);
                        ctx.arc(center, center, radius, start, end, false);
                        ctx.closePath();
                        ctx.fillStyle = rootTimerButton.service.done ? rootTimerButton.theme.modules.timer.errorTextColor : rootTimerButton.theme.modules.timer.progressFillColor;
                        ctx.fill();
                    }
                }

                Connections {
                    target: rootTimerButton.service

                    function onProgressChanged() {
                        pieCanvas.requestPaint();
                    }

                    function onDoneChanged() {
                        pieCanvas.requestPaint();
                    }
                }

                Component.onCompleted: requestPaint()
            }

            Text {
                anchors.centerIn: parent
                text: rootTimerButton.service.done ? "!" : ""
                color: rootTimerButton.theme.modules.timer.actionTextColor
                font.pixelSize: rootTimerButton.theme.modules.timer.pillDonePixelSize
                font.weight: Font.Bold
            }
        }

        Item {
            width: timerText.implicitWidth
            height: Math.max(rootTimerButton.theme.modules.timer.pillPieSize, timerText.implicitHeight)

            Text {
                id: timerText

                anchors.centerIn: parent
                text: rootTimerButton.service.displayText
                color: rootTimerButton.service.done ? rootTimerButton.theme.modules.timer.errorTextColor : rootTimerButton.theme.modules.bar.primaryTextColor
                font.family: "monospace"
                font.pixelSize: rootTimerButton.theme.modules.timer.pillTimePixelSize
                font.weight: Font.DemiBold
            }
        }
    }

    function tooltipText() {
        const lines = [];

        lines.push(rootTimerButton.service.labelText);
        lines.push(rootTimerButton.service.isCountdown ? "Countdown: " + rootTimerButton.service.displayText : "Elapsed: " + rootTimerButton.service.displayText);
        lines.push(rootTimerButton.service.stateText);
        lines.push("Left: open panel · Middle: pause/resume · Right: stop");
        return lines.join("\n");
    }
}
