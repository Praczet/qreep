import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: rootPowerPanel

    required property QtObject theme

    signal actionRequested(string action)
    property var pendingAction: null

    readonly property var actions: [
        {
            icon: "system-lock-screen-symbolic",
            label: "Lock",
            action: "lock",
            destructive: false,
            confirmTitle: "Lock the screen",
            confirmContent: "Are you sure you want to lock the screen?"
        },
        {
            icon: "system-log-out-symbolic",
            label: "Log out",
            action: "logout",
            destructive: true,
            confirmTitle: "Log out",
            confirmContent: "Are you sure you want to log out?"
        },
        {
            icon: "media-playback-pause-symbolic",
            label: "Suspend",
            action: "suspend",
            destructive: true,
            confirmTitle: "Suspend the system",
            confirmContent: "Are you sure you want to suspend the system?"
        },
        {
            icon: "system-reboot-symbolic",
            label: "Reboot",
            action: "reboot",
            destructive: true,
            confirmTitle: "Reboot the system",
            confirmContent: "Are you sure you want to reboot the system?"
        },
        {
            icon: "system-shutdown-symbolic",
            label: "Power off",
            action: "poweroff",
            destructive: true,
            confirmTitle: "Power off the system",
            confirmContent: "Are you sure you want to power off the system?"
        }
    ]

    function requestAction(action) {
        if (!action.destructive) {
            rootPowerPanel.actionRequested(action.action);
            rootPowerPanel.visible = false;
            return;
        }
        pendingAction = action;
    }

    function confirmPendingAction() {
        if (pendingAction == null)
            return;
        rootPowerPanel.actionRequested(pendingAction.action);
        rootPowerPanel.visible = false;
        pendingAction = null;
    }

    function cancelPendingAction() {
        pendingAction = null;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: false
    color: "transparent"

    WlrLayershell.namespace: "qreep-popup-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusiveZone: 0

    onVisibleChanged: {
        if (visible) {
            background.forceActiveFocus();
        } else {
            pendingAction = null;
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: rootPowerPanel.visible
        onActivated: {
            if (rootPowerPanel.pendingAction !== null) {
                rootPowerPanel.cancelPendingAction();
                return;
            }

            rootPowerPanel.visible = false;
        }
    }

    Rectangle {
        id: background

        anchors.fill: parent
        color: "transparent"
        focus: true

        MouseArea {
            anchors.fill: parent
            onClicked: rootPowerPanel.visible = false
        }

        Rectangle {
            id: sidebar

            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
                topMargin: rootPowerPanel.theme.modules.bar.power.sidebarMargin
                rightMargin: rootPowerPanel.theme.modules.bar.power.sidebarMargin
                bottomMargin: rootPowerPanel.theme.modules.bar.power.sidebarMargin
            }
            width: rootPowerPanel.theme.modules.bar.power.sidebarWidth
            radius: rootPowerPanel.theme.modules.bar.power.sidebarRadius
            color: rootPowerPanel.theme.modules.bar.power.backgroundColor
            border.width: rootPowerPanel.theme.modules.bar.power.sidebarBorderWidth
            border.color: rootPowerPanel.theme.modules.bar.power.borderColor

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => mouse.accepted = true
            }

            Rectangle {
                id: actionCard

                anchors.centerIn: parent
                width: rootPowerPanel.theme.modules.bar.power.cardWidth
                height: (rootPowerPanel.pendingAction === null ? actionList.implicitHeight : confirmActionList.implicitHeight) + rootPowerPanel.theme.modules.bar.power.cardPadding * 2
                radius: rootPowerPanel.theme.modules.bar.power.cardRadius
                color: rootPowerPanel.theme.modules.bar.moduleHoverBackgroundColor

                Column {
                    id: actionList
                    visible: rootPowerPanel.pendingAction === null

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootPowerPanel.theme.modules.bar.power.cardPadding
                    }
                    spacing: rootPowerPanel.theme.modules.bar.power.actionSpacing

                    Repeater {
                        model: rootPowerPanel.actions

                        delegate: Rectangle {
                            id: actionButton

                            required property var modelData

                            width: parent.width
                            height: rootPowerPanel.theme.modules.bar.power.actionHeight
                            radius: rootPowerPanel.theme.modules.bar.power.actionRadius
                            color: actionHover.hovered ? rootPowerPanel.theme.modules.bar.power.actionHoverBackgroundColor : rootPowerPanel.theme.modules.bar.power.actionBackgroundColor

                            Row {
                                anchors.centerIn: parent
                                spacing: rootPowerPanel.theme.modules.bar.power.actionContentSpacing

                                Item {
                                    width: rootPowerPanel.theme.modules.bar.power.actionIconSize
                                    height: rootPowerPanel.theme.modules.bar.power.actionIconSize
                                    anchors.verticalCenter: parent.verticalCenter

                                    IconImage {
                                        id: icon

                                        anchors.fill: parent
                                        source: Quickshell.iconPath(actionButton.modelData.icon, "application-x-executable-symbolic")
                                        visible: false
                                    }

                                    MultiEffect {
                                        anchors.fill: parent
                                        source: icon
                                        colorization: rootPowerPanel.theme.modules.bar.power.actionIconColorization
                                        brightness: rootPowerPanel.theme.modules.bar.power.actionIconBrightness
                                        colorizationColor: rootPowerPanel.theme.modules.bar.power.actionIconColor
                                    }
                                }

                                Text {
                                    width: rootPowerPanel.theme.modules.bar.power.actionLabelWidth
                                    text: actionButton.modelData.label
                                    color: rootPowerPanel.theme.modules.bar.power.actionTextColor
                                    font.pixelSize: rootPowerPanel.theme.modules.bar.power.actionTextPixelSize
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            HoverHandler {
                                id: actionHover

                                cursorShape: Qt.PointingHandCursor
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    rootPowerPanel.requestAction(actionButton.modelData);
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: rootPowerPanel.theme.animationFastDuration
                                }
                            }
                        }
                    }
                }
                Column {
                    id: confirmActionList
                    visible: rootPowerPanel.pendingAction !== null

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootPowerPanel.theme.modules.bar.power.cardPadding
                    }
                    spacing: rootPowerPanel.theme.modules.bar.power.actionSpacing

                    Text {
                        width: parent.width
                        text: rootPowerPanel.pendingAction !== null ? rootPowerPanel.pendingAction.confirmTitle : ""
                        color: rootPowerPanel.theme.modules.bar.power.confirmTextColor
                        font.pixelSize: rootPowerPanel.theme.modules.bar.power.confirmTitlePixelSize
                        font.bold: true
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        text: rootPowerPanel.pendingAction !== null ? rootPowerPanel.pendingAction.confirmContent : ""
                        color: rootPowerPanel.theme.modules.bar.power.confirmTextColor
                        font.pixelSize: rootPowerPanel.theme.modules.bar.power.confirmContentPixelSize
                        wrapMode: Text.Wrap
                        bottomPadding: rootPowerPanel.theme.modules.bar.power.confirmContentBottomPadding
                    }

                    Row {
                        width: parent.width
                        spacing: rootPowerPanel.theme.modules.bar.power.confirmButtonSpacing

                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: rootPowerPanel.theme.modules.bar.power.actionHeight
                            radius: rootPowerPanel.theme.modules.bar.power.actionRadius
                            color: cancelHover.hovered ? rootPowerPanel.theme.modules.bar.power.actionHoverBackgroundColor : rootPowerPanel.theme.modules.bar.power.actionBackgroundColor

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: rootPowerPanel.theme.modules.bar.power.actionTextColor
                                font.pixelSize: rootPowerPanel.theme.modules.bar.power.actionTextPixelSize
                            }

                            HoverHandler {
                                id: cancelHover

                                cursorShape: Qt.PointingHandCursor
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: rootPowerPanel.cancelPendingAction()
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: rootPowerPanel.theme.animationFastDuration
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: rootPowerPanel.theme.modules.bar.power.actionHeight
                            radius: rootPowerPanel.theme.modules.bar.power.actionRadius
                            color: confirmHover.hovered ? rootPowerPanel.theme.modules.bar.power.actionHoverBackgroundColor : rootPowerPanel.theme.modules.bar.power.actionBackgroundColor

                            Text {
                                anchors.centerIn: parent
                                text: "Confirm"
                                color: rootPowerPanel.theme.modules.bar.power.actionTextColor
                                font.pixelSize: rootPowerPanel.theme.modules.bar.power.actionTextPixelSize
                            }

                            HoverHandler {
                                id: confirmHover

                                cursorShape: Qt.PointingHandCursor
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: rootPowerPanel.confirmPendingAction()
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: rootPowerPanel.theme.animationFastDuration
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
