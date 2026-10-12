import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootDelayedScreenshotDialog

    required property QtObject theme
    property int initialDelaySeconds: 3
    property string initialBackend: "flameshot"
    property int delaySeconds: 3
    property string selectedBackend: "flameshot"
    property bool presented: false

    signal accepted(int delaySeconds, string backend)
    signal cancelled

    implicitWidth: screen.width
    implicitHeight: screen.height

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.namespace: "qreep-screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        delaySeconds = clampDelay(initialDelaySeconds);
        selectedBackend = normalizedBackend(initialBackend);
        delayInput.text = String(delaySeconds);
        delayInput.forceActiveFocus();
        enterTimer.start();
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: rootDelayedScreenshotDialog.cancelled()
    }

    Shortcut {
        sequence: "Return"
        context: Qt.WindowShortcut
        onActivated: rootDelayedScreenshotDialog.submit()
    }

    Shortcut {
        sequence: "Enter"
        context: Qt.WindowShortcut
        onActivated: rootDelayedScreenshotDialog.submit()
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: rootDelayedScreenshotDialog.presented = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rootDelayedScreenshotDialog.cancelled()
    }

    Rectangle {
        id: panel

        width: Math.min(rootDelayedScreenshotDialog.theme.modules.screenshot.panelWidth, rootDelayedScreenshotDialog.width - rootDelayedScreenshotDialog.theme.modules.screenshot.screenMargin * 2)
        height: content.implicitHeight + rootDelayedScreenshotDialog.theme.modules.screenshot.panelPadding * 2
        anchors.centerIn: parent
        radius: rootDelayedScreenshotDialog.theme.modules.screenshot.panelRadius
        color: rootDelayedScreenshotDialog.theme.modules.screenshot.panelColor
        border.width: 1
        border.color: rootDelayedScreenshotDialog.theme.modules.screenshot.borderColor
        opacity: rootDelayedScreenshotDialog.presented ? 1 : 0
        scale: rootDelayedScreenshotDialog.presented ? 1 : 0.97

        Behavior on opacity {
            NumberAnimation {
                duration: rootDelayedScreenshotDialog.theme.modules.screenshot.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: rootDelayedScreenshotDialog.theme.modules.screenshot.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Column {
            id: content

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: rootDelayedScreenshotDialog.theme.modules.screenshot.panelPadding
            }
            spacing: rootDelayedScreenshotDialog.theme.modules.screenshot.sectionSpacing

            Text {
                width: parent.width
                text: "Delayed Screenshot"
                color: rootDelayedScreenshotDialog.theme.modules.screenshot.primaryTextColor
                font.pixelSize: rootDelayedScreenshotDialog.theme.modules.screenshot.titlePixelSize
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                width: parent.width
                height: rootDelayedScreenshotDialog.theme.modules.screenshot.fieldHeight
                spacing: rootDelayedScreenshotDialog.theme.modules.screenshot.rowSpacing

                Text {
                    width: rootDelayedScreenshotDialog.theme.modules.screenshot.labelWidth
                    height: parent.height
                    text: "Delay:"
                    color: rootDelayedScreenshotDialog.theme.modules.screenshot.primaryTextColor
                    font.pixelSize: rootDelayedScreenshotDialog.theme.modules.screenshot.bodyPixelSize
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: rootDelayedScreenshotDialog.theme.modules.screenshot.delayFieldWidth
                    height: parent.height
                    radius: rootDelayedScreenshotDialog.theme.modules.screenshot.controlRadius
                    color: rootDelayedScreenshotDialog.theme.modules.screenshot.controlColor
                    border.width: 1
                    border.color: delayInput.activeFocus ? rootDelayedScreenshotDialog.theme.modules.screenshot.focusBorderColor : rootDelayedScreenshotDialog.theme.modules.screenshot.borderColor

                    Rectangle {
                        width: rootDelayedScreenshotDialog.theme.modules.screenshot.stepButtonWidth
                        height: parent.height
                        radius: parent.radius
                        color: decrementHover.hovered ? rootDelayedScreenshotDialog.theme.modules.screenshot.hoverColor : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "−"
                            color: rootDelayedScreenshotDialog.theme.modules.screenshot.primaryTextColor
                            font.pixelSize: rootDelayedScreenshotDialog.theme.modules.screenshot.bodyPixelSize + 2
                        }

                        HoverHandler {
                            id: decrementHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: rootDelayedScreenshotDialog.setDelay(rootDelayedScreenshotDialog.delaySeconds - 1)
                        }
                    }

                    TextInput {
                        id: delayInput

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                            leftMargin: rootDelayedScreenshotDialog.theme.modules.screenshot.stepButtonWidth
                            rightMargin: rootDelayedScreenshotDialog.theme.modules.screenshot.stepButtonWidth
                        }
                        activeFocusOnTab: true
                        color: rootDelayedScreenshotDialog.theme.modules.screenshot.primaryTextColor
                        selectionColor: rootDelayedScreenshotDialog.theme.modules.screenshot.accentColor
                        selectedTextColor: rootDelayedScreenshotDialog.theme.modules.screenshot.panelColor
                        font.pixelSize: rootDelayedScreenshotDialog.theme.modules.screenshot.bodyPixelSize
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator {
                            bottom: 0
                            top: 30
                        }

                        onEditingFinished: rootDelayedScreenshotDialog.commitDelay()

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Up) {
                                rootDelayedScreenshotDialog.setDelay(rootDelayedScreenshotDialog.delaySeconds + 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                rootDelayedScreenshotDialog.setDelay(rootDelayedScreenshotDialog.delaySeconds - 1);
                                event.accepted = true;
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: rootDelayedScreenshotDialog.theme.modules.screenshot.stepButtonWidth
                        height: parent.height
                        radius: parent.radius
                        color: incrementHover.hovered ? rootDelayedScreenshotDialog.theme.modules.screenshot.hoverColor : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: rootDelayedScreenshotDialog.theme.modules.screenshot.primaryTextColor
                            font.pixelSize: rootDelayedScreenshotDialog.theme.modules.screenshot.bodyPixelSize + 2
                        }

                        HoverHandler {
                            id: incrementHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: rootDelayedScreenshotDialog.setDelay(rootDelayedScreenshotDialog.delaySeconds + 1)
                        }
                    }
                }

                Text {
                    height: parent.height
                    text: "sec"
                    color: rootDelayedScreenshotDialog.theme.modules.screenshot.secondaryTextColor
                    font.pixelSize: rootDelayedScreenshotDialog.theme.modules.screenshot.metaPixelSize
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Row {
                width: parent.width
                height: rootDelayedScreenshotDialog.theme.modules.screenshot.fieldHeight
                spacing: rootDelayedScreenshotDialog.theme.modules.screenshot.rowSpacing

                Text {
                    width: rootDelayedScreenshotDialog.theme.modules.screenshot.labelWidth
                    height: parent.height
                    text: "App:"
                    color: rootDelayedScreenshotDialog.theme.modules.screenshot.primaryTextColor
                    font.pixelSize: rootDelayedScreenshotDialog.theme.modules.screenshot.bodyPixelSize
                    verticalAlignment: Text.AlignVCenter
                }

                Row {
                    width: rootDelayedScreenshotDialog.theme.modules.screenshot.backendWidth
                    height: parent.height
                    spacing: 0

                    Repeater {
                        id: backendRepeater

                        model: ["Flameshot", "Grim"]

                        delegate: Rectangle {
                            id: rootBackendButton

                            required property string modelData
                            required property int index

                            readonly property string backendId: modelData.toLowerCase()
                            readonly property bool selected: rootDelayedScreenshotDialog.selectedBackend === backendId

                            width: rootDelayedScreenshotDialog.theme.modules.screenshot.backendButtonWidth
                            height: parent.height
                            activeFocusOnTab: true
                            topLeftRadius: index === 0 ? rootDelayedScreenshotDialog.theme.modules.screenshot.controlRadius : 0
                            bottomLeftRadius: index === 0 ? rootDelayedScreenshotDialog.theme.modules.screenshot.controlRadius : 0
                            topRightRadius: index === backendRepeater.count - 1 ? rootDelayedScreenshotDialog.theme.modules.screenshot.controlRadius : 0
                            bottomRightRadius: index === backendRepeater.count - 1 ? rootDelayedScreenshotDialog.theme.modules.screenshot.controlRadius : 0
                            color: selected ? rootDelayedScreenshotDialog.theme.modules.screenshot.selectedColor : backendHover.hovered ? rootDelayedScreenshotDialog.theme.modules.screenshot.hoverColor : rootDelayedScreenshotDialog.theme.modules.screenshot.controlColor
                            border.width: activeFocus || selected ? 1 : 0
                            border.color: rootDelayedScreenshotDialog.theme.modules.screenshot.focusBorderColor

                            Text {
                                anchors.centerIn: parent
                                text: rootBackendButton.modelData
                                color: rootBackendButton.selected ? rootDelayedScreenshotDialog.theme.modules.screenshot.accentColor : rootDelayedScreenshotDialog.theme.modules.screenshot.primaryTextColor
                                font.pixelSize: rootDelayedScreenshotDialog.theme.modules.screenshot.bodyPixelSize
                                font.weight: rootBackendButton.selected ? Font.DemiBold : Font.Normal
                            }

                            HoverHandler {
                                id: backendHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: rootDelayedScreenshotDialog.selectedBackend = rootBackendButton.backendId
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Space) {
                                    rootDelayedScreenshotDialog.selectedBackend = rootBackendButton.backendId;
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                                    const nextIndex = event.key === Qt.Key_Left ? Math.max(0, index - 1) : Math.min(backendRepeater.count - 1, index + 1);
                                    const nextButton = backendRepeater.itemAt(nextIndex);
                                    rootDelayedScreenshotDialog.selectedBackend = backendRepeater.model[nextIndex].toLowerCase();
                                    if (nextButton)
                                        nextButton.forceActiveFocus();
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: rootDelayedScreenshotDialog.theme.modules.screenshot.buttonHeight

                Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: rootDelayedScreenshotDialog.theme.modules.screenshot.rowSpacing

                    Rectangle {
                        width: rootDelayedScreenshotDialog.theme.modules.screenshot.buttonWidth
                        height: parent.height
                        activeFocusOnTab: true
                        radius: rootDelayedScreenshotDialog.theme.modules.screenshot.controlRadius
                        color: cancelHover.hovered ? rootDelayedScreenshotDialog.theme.modules.screenshot.hoverColor : rootDelayedScreenshotDialog.theme.modules.screenshot.controlColor
                        border.width: activeFocus ? 1 : 0
                        border.color: rootDelayedScreenshotDialog.theme.modules.screenshot.focusBorderColor

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: rootDelayedScreenshotDialog.theme.modules.screenshot.primaryTextColor
                            font.pixelSize: rootDelayedScreenshotDialog.theme.modules.screenshot.bodyPixelSize
                        }

                        HoverHandler {
                            id: cancelHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: rootDelayedScreenshotDialog.cancelled()
                        }

                        Keys.onSpacePressed: event => {
                            rootDelayedScreenshotDialog.cancelled();
                            event.accepted = true;
                        }
                    }

                    Rectangle {
                        width: rootDelayedScreenshotDialog.theme.modules.screenshot.buttonWidth
                        height: parent.height
                        activeFocusOnTab: true
                        radius: rootDelayedScreenshotDialog.theme.modules.screenshot.controlRadius
                        color: okHover.hovered ? rootDelayedScreenshotDialog.theme.modules.screenshot.hoverColor : rootDelayedScreenshotDialog.theme.modules.screenshot.selectedColor
                        border.width: 1
                        border.color: rootDelayedScreenshotDialog.theme.modules.screenshot.focusBorderColor

                        Text {
                            anchors.centerIn: parent
                            text: "OK"
                            color: rootDelayedScreenshotDialog.theme.modules.screenshot.accentColor
                            font.pixelSize: rootDelayedScreenshotDialog.theme.modules.screenshot.bodyPixelSize
                            font.weight: Font.DemiBold
                        }

                        HoverHandler {
                            id: okHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: rootDelayedScreenshotDialog.submit()
                        }

                        Keys.onSpacePressed: event => {
                            rootDelayedScreenshotDialog.submit();
                            event.accepted = true;
                        }
                    }
                }
            }
        }
    }

    function clampDelay(value) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? Math.max(0, Math.min(30, Math.round(parsed))) : 3;
    }

    function normalizedBackend(value) {
        return String(value || "flameshot").toLowerCase() === "grim" ? "grim" : "flameshot";
    }

    function setDelay(value) {
        delaySeconds = clampDelay(value);
        delayInput.text = String(delaySeconds);
    }

    function commitDelay() {
        setDelay(delayInput.text.length > 0 ? delayInput.text : initialDelaySeconds);
    }

    function submit() {
        commitDelay();
        accepted(delaySeconds, selectedBackend);
    }
}
