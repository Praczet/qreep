import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootTimerButton

    required property QtObject service
    property bool completionWarning: false
    property bool completionAlertArmed: false

    tooltipTitle: "Timer"
    tooltipContent: tooltipText()
    tooltipStyle: completionWarning || service.done ? "warning" : "normal"
    color: completionWarning ? Qt.rgba(theme.warningColor.r, theme.warningColor.g, theme.warningColor.b, 0.24) : hovered ? theme.modules.bar.pill.hoverBackgroundColor : theme.modules.bar.pill.backgroundColor
    border.width: completionWarning ? 1 : 0
    border.color: theme.warningColor

    Row {
        id: timerContent

        spacing: rootTimerButton.theme.modules.timer.pillContentSpacing
        transformOrigin: Item.Center

        Item {
            id: countdownPie

            width: Math.max(rootTimerButton.theme.modules.timer.pillPieSize, rootTimerButton.theme.modules.bar.pill.height - 2)
            height: width
            visible: rootTimerButton.service.isCountdown

            Canvas {
                id: pieCanvas

                anchors.fill: parent

                onPaint: {
                    const ctx = getContext("2d");
                    const center = width / 2;
                    const radius = Math.max(1, width / 2 - rootTimerButton.theme.modules.timer.pillPieStrokeWidth);
                    const progress = rootTimerButton.service.done ? 1 : Math.max(0, Math.min(1, rootTimerButton.service.progress));
                    const finished = rootTimerButton.service.done || progress >= 0.999;
                    const statusColor = rootTimerButton.completionWarning ? rootTimerButton.theme.warningColor : rootTimerButton.service.done ? rootTimerButton.theme.modules.timer.errorTextColor : rootTimerButton.theme.modules.timer.progressFillColor;
                    const start = -Math.PI / 2;
                    const end = start + Math.PI * 2 * progress;

                    ctx.reset();
                    ctx.clearRect(0, 0, width, height);

                    ctx.beginPath();
                    ctx.arc(center, center, radius, 0, Math.PI * 2, false);
                    ctx.lineWidth = rootTimerButton.theme.modules.timer.pillPieStrokeWidth;
                    ctx.strokeStyle = rootTimerButton.completionWarning || rootTimerButton.service.done ? statusColor : rootTimerButton.theme.modules.timer.progressTrackColor;
                    ctx.stroke();

                    if (progress > 0) {
                        ctx.beginPath();
                        if (finished) {
                            ctx.arc(center, center, radius, 0, Math.PI * 2, false);
                            ctx.fillStyle = statusColor;
                            ctx.fill();
                        } else {
                            ctx.moveTo(center, center);
                            ctx.arc(center, center, radius, start, end, false);
                            ctx.closePath();
                            ctx.fillStyle = statusColor;
                            ctx.fill();
                        }
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

                    function onStarted() {
                        rootTimerButton.acknowledgeCompletion();
                        pieCanvas.requestPaint();
                    }

                    function onCompletionNotified() {
                        rootTimerButton.startCompletionAlert();
                    }
                }

                Component.onCompleted: requestPaint()
            }

            Text {
                anchors.centerIn: parent
                text: rootTimerButton.service.done ? "!" : ""
                color: rootTimerButton.completionWarning ? rootTimerButton.theme.modules.bar.pill.backgroundColor : rootTimerButton.theme.modules.timer.actionTextColor
                font.pixelSize: rootTimerButton.theme.modules.timer.pillDonePixelSize
                font.weight: Font.Bold
            }
        }

        Item {
            width: timerText.implicitWidth
            height: countdownPie.height

            Text {
                id: timerText

                anchors.centerIn: parent
                text: rootTimerButton.service.displayText
                color: rootTimerButton.completionWarning ? rootTimerButton.theme.warningColor : rootTimerButton.service.done ? rootTimerButton.theme.modules.timer.errorTextColor : rootTimerButton.theme.modules.bar.primaryTextColor
                font.family: "monospace"
                font.pixelSize: rootTimerButton.theme.modules.timer.pillTimePixelSize
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
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

    function startCompletionAlert() {
        completionAlertArmed = true;
        completionWarning = false;
        completionAnimation.restart();
    }

    function acknowledgeCompletion() {
        completionAlertArmed = false;
        completionWarning = false;
        completionAnimation.stop();
        timerContent.x = 0;
        timerContent.scale = 1;
    }

    onCompletionWarningChanged: pieCanvas.requestPaint()

    SequentialAnimation {
        id: completionAnimation

        loops: 3

        ParallelAnimation {
            NumberAnimation {
                target: timerContent
                property: "x"
                from: 0
                to: -5
                duration: 55
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: timerContent
                property: "scale"
                from: 1
                to: 1.18
                duration: 55
                easing.type: Easing.OutCubic
            }
        }

        NumberAnimation {
            target: timerContent
            property: "x"
            from: -5
            to: 5
            duration: 90
            easing.type: Easing.InOutCubic
        }

        ParallelAnimation {
            NumberAnimation {
                target: timerContent
                property: "x"
                from: 5
                to: 0
                duration: 55
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: timerContent
                property: "scale"
                from: 1.18
                to: 1
                duration: 55
                easing.type: Easing.OutCubic
            }
        }

        onStopped: {
            timerContent.x = 0;
            timerContent.scale = 1;

            if (completionAlertArmed)
                completionWarning = true;
        }
    }
}
