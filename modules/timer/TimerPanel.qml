import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootTimerPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    property bool presented: false
    property string selectedMode: "countdown"

    signal closeRequested

    implicitWidth: screen.width
    implicitHeight: screen.height

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.namespace: "qreep-timer"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        durationInput.focusInput();
        if (panelOpen)
            enterTimer.restart();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            if (selectedMode === "countdown")
                durationInput.focusInput();
            else
                labelInput.focusInput();

            enterTimer.restart();
            return;
        }

        enterTimer.stop();
        presented = false;
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: rootTimerPanel.closeRequested()
    }

    Shortcut {
        sequence: "Space"
        context: Qt.WindowShortcut
        onActivated: rootTimerPanel.service.toggleRunning()
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: presented = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rootTimerPanel.closeRequested()
    }

    Rectangle {
        id: panel

        width: Math.min(rootTimerPanel.theme.modules.timer.panelWidth, rootTimerPanel.width - rootTimerPanel.theme.modules.timer.panelMinMargin * 2)
        height: content.implicitHeight + rootTimerPanel.theme.modules.timer.panelPadding * 2
        anchors.centerIn: parent
        radius: rootTimerPanel.theme.modules.timer.panelRadius
        color: rootTimerPanel.theme.modules.timer.panelColor
        border.width: 1
        border.color: rootTimerPanel.theme.modules.timer.panelBorderColor
        opacity: rootTimerPanel.presented ? 1 : 0
        scale: rootTimerPanel.presented ? 1 : 0.98
        clip: true

        Behavior on opacity {
            NumberAnimation {
                duration: rootTimerPanel.theme.modules.timer.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: rootTimerPanel.theme.modules.timer.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: content

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: rootTimerPanel.theme.modules.timer.panelPadding
            }
            spacing: rootTimerPanel.theme.modules.timer.gap

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: rootTimerPanel.theme.modules.timer.headerHeight
                spacing: rootTimerPanel.theme.modules.timer.gap

                Text {
                    Layout.fillWidth: true
                    text: "Timer"
                    color: rootTimerPanel.theme.modules.timer.primaryTextColor
                    font.pixelSize: rootTimerPanel.theme.modules.timer.titlePixelSize
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: rootTimerPanel.service.stateText
                    color: rootTimerPanel.service.done ? rootTimerPanel.theme.modules.timer.accentTextColor : rootTimerPanel.theme.modules.timer.secondaryTextColor
                    font.pixelSize: rootTimerPanel.theme.modules.timer.metaPixelSize
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: rootTimerPanel.theme.modules.timer.displayHeight
                radius: 8
                color: rootTimerPanel.theme.modules.timer.fieldColor
                border.width: 1
                border.color: rootTimerPanel.theme.modules.timer.fieldBorderColor
                clip: true

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: rootTimerPanel.service.displayText
                        color: rootTimerPanel.theme.modules.timer.primaryTextColor
                        font.family: "monospace"
                        font.pixelSize: rootTimerPanel.theme.modules.timer.displayPixelSize
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: rootTimerPanel.service.hasState ? rootTimerPanel.service.labelText : "no timer running"
                        color: rootTimerPanel.theme.modules.timer.secondaryTextColor
                        font.pixelSize: rootTimerPanel.theme.modules.timer.bodyPixelSize
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 4
                    color: rootTimerPanel.theme.modules.timer.progressTrackColor

                    Rectangle {
                        width: parent.width * rootTimerPanel.service.progress
                        height: parent.height
                        color: rootTimerPanel.theme.modules.timer.progressFillColor

                        Behavior on width {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: rootTimerPanel.theme.modules.timer.buttonHeight
                spacing: rootTimerPanel.theme.modules.timer.gap

                TimerModeButton {
                    label: "Countdown"
                    active: rootTimerPanel.selectedMode === "countdown"
                    theme: rootTimerPanel.theme
                    Layout.fillWidth: true
                    onClicked: {
                        rootTimerPanel.selectedMode = "countdown";
                        durationInput.focusInput();
                    }
                }

                TimerModeButton {
                    label: "Count up"
                    active: rootTimerPanel.selectedMode === "timer"
                    theme: rootTimerPanel.theme
                    Layout.fillWidth: true
                    onClicked: {
                        rootTimerPanel.selectedMode = "timer";
                        labelInput.focusInput();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: rootTimerPanel.theme.modules.timer.fieldHeight
                spacing: rootTimerPanel.theme.modules.timer.gap
                visible: rootTimerPanel.selectedMode === "countdown"

                Repeater {
                    model: ["5m", "10m", "25m", "45m"]

                    TimerModeButton {
                        required property string modelData

                        label: modelData
                        active: durationInput.text === modelData
                        theme: rootTimerPanel.theme
                        Layout.preferredWidth: rootTimerPanel.theme.modules.timer.smallButtonWidth
                        onClicked: {
                            durationInput.text = modelData;
                            durationInput.focusInput();
                        }
                    }
                }

                TimerTextField {
                    id: durationInput

                    Layout.fillWidth: true
                    theme: rootTimerPanel.theme
                    text: "25m"
                    placeholder: "duration"
                    onAccepted: rootTimerPanel.startFromPanel()
                }
            }

            TimerTextField {
                id: finishAtInput

                Layout.fillWidth: true
                Layout.preferredHeight: rootTimerPanel.theme.modules.timer.fieldHeight
                visible: rootTimerPanel.selectedMode === "countdown"
                theme: rootTimerPanel.theme
                placeholder: "finish at HH:MM"
                onAccepted: rootTimerPanel.startFromPanel()
            }

            TimerTextField {
                id: labelInput

                Layout.fillWidth: true
                Layout.preferredHeight: rootTimerPanel.theme.modules.timer.fieldHeight
                theme: rootTimerPanel.theme
                placeholder: "label"
                onAccepted: rootTimerPanel.startFromPanel()
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: rootTimerPanel.theme.modules.timer.buttonHeight
                spacing: rootTimerPanel.theme.modules.timer.gap

                Text {
                    Layout.preferredWidth: 92
                    text: "Notification"
                    color: rootTimerPanel.theme.modules.timer.secondaryTextColor
                    font.pixelSize: rootTimerPanel.theme.modules.timer.bodyPixelSize
                    verticalAlignment: Text.AlignVCenter
                }

                TimerModeButton {
                    label: "Notify"
                    active: rootTimerPanel.service.notificationMode === "notify"
                    theme: rootTimerPanel.theme
                    Layout.fillWidth: true
                    onClicked: rootTimerPanel.service.setNotificationMode("notify")
                }

                TimerModeButton {
                    label: "OSD"
                    active: rootTimerPanel.service.notificationMode === "osd"
                    theme: rootTimerPanel.theme
                    Layout.fillWidth: true
                    onClicked: rootTimerPanel.service.setNotificationMode("osd")
                }
            }

            Text {
                Layout.fillWidth: true
                text: rootTimerPanel.service.lastError
                visible: rootTimerPanel.service.lastError.length > 0
                color: rootTimerPanel.theme.modules.timer.errorTextColor
                font.pixelSize: rootTimerPanel.theme.modules.timer.metaPixelSize
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: rootTimerPanel.theme.modules.timer.buttonHeight
                spacing: rootTimerPanel.theme.modules.timer.gap

                TimerActionButton {
                    label: rootTimerPanel.service.running ? "Pause" : (rootTimerPanel.service.hasState ? "Resume" : "Start")
                    theme: rootTimerPanel.theme
                    Layout.fillWidth: true
                    onClicked: {
                        if (!rootTimerPanel.service.hasState)
                            rootTimerPanel.startFromPanel();
                        else
                            rootTimerPanel.service.toggleRunning();
                    }
                }

                TimerActionButton {
                    label: "Stop"
                    theme: rootTimerPanel.theme
                    danger: true
                    Layout.preferredWidth: rootTimerPanel.theme.modules.timer.actionButtonWidth
                    enabled: rootTimerPanel.service.hasState
                    opacity: enabled ? 1 : 0.45
                    onClicked: rootTimerPanel.service.stop()
                }
            }
        }
    }

    function startFromPanel() {
        if (selectedMode === "countdown") {
            if (finishAtInput.text.trim().length > 0)
                service.startCountdownUntil(finishAtInput.text, labelInput.text);
            else
                service.startCountdown(durationInput.text, labelInput.text);
        } else {
            service.startTimer(labelInput.text);
        }
    }
}
