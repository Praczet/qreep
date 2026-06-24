import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

PopupWindow {
    id: rootPowerPanel

    required property QtObject theme
    required property Item anchorItem

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

    anchor {
        item: rootPowerPanel.anchorItem
        rect.x: rootPowerPanel.anchorItem.width - rootPowerPanel.width
        rect.y: -rootPowerPanel.anchorItem.y
    }

    implicitWidth: theme.power.sidebarWidth
    implicitHeight: anchorItem.QsWindow.window ? anchorItem.QsWindow.window.screen.height : 1
    visible: false
    color: "transparent"
    grabFocus: true

    onVisibleChanged: {
        if (!visible)
            pendingAction = null;
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
        anchors.fill: parent
        color: Qt.rgba(rootPowerPanel.theme.calendarBackground.r, rootPowerPanel.theme.calendarBackground.g, rootPowerPanel.theme.calendarBackground.b, rootPowerPanel.theme.power.sidebarOpacity)

        Rectangle {
            id: sidebar

            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: actionCard

                anchors.centerIn: parent
                width: rootPowerPanel.theme.power.cardWidth
                height: (rootPowerPanel.pendingAction === null ? actionList.implicitHeight : confirmActionList.implicitHeight) + rootPowerPanel.theme.power.cardPadding * 2
                radius: rootPowerPanel.theme.power.cardRadius
                color: rootPowerPanel.theme.moduleHoverBackground

                Column {
                    id: actionList
                    visible: rootPowerPanel.pendingAction === null

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootPowerPanel.theme.power.cardPadding
                    }
                    spacing: rootPowerPanel.theme.power.actionSpacing

                    Repeater {
                        model: rootPowerPanel.actions

                        delegate: Rectangle {
                            id: actionButton

                            required property var modelData

                            width: parent.width
                            height: rootPowerPanel.theme.power.actionHeight
                            radius: rootPowerPanel.theme.power.actionRadius
                            color: actionHover.hovered ? rootPowerPanel.theme.powerActionHoverBackground : rootPowerPanel.theme.powerActionBackground

                            Row {
                                anchors.centerIn: parent
                                spacing: rootPowerPanel.theme.power.actionContentSpacing

                                Item {
                                    width: rootPowerPanel.theme.power.actionIconSize
                                    height: rootPowerPanel.theme.power.actionIconSize
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
                                        colorization: rootPowerPanel.theme.power.actionIconColorization
                                        brightness: rootPowerPanel.theme.power.actionIconBrightness
                                        colorizationColor: rootPowerPanel.theme.powerActionIconColor
                                    }
                                }

                                Text {
                                    width: rootPowerPanel.theme.power.actionLabelWidth
                                    text: actionButton.modelData.label
                                    color: rootPowerPanel.theme.powerActionText
                                    font.pixelSize: rootPowerPanel.theme.power.actionTextPixelSize
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            HoverHandler {
                                id: actionHover

                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: {
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
                        margins: rootPowerPanel.theme.power.cardPadding
                    }
                    spacing: rootPowerPanel.theme.power.actionSpacing

                    Text {
                        width: parent.width
                        text: rootPowerPanel.pendingAction !== null ? rootPowerPanel.pendingAction.confirmTitle : ""
                        color: rootPowerPanel.theme.powerConfirmText
                        font.pixelSize: rootPowerPanel.theme.power.confirmTitlePixelSize
                        font.bold: true
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        text: rootPowerPanel.pendingAction !== null ? rootPowerPanel.pendingAction.confirmContent : ""
                        color: rootPowerPanel.theme.powerConfirmText
                        font.pixelSize: rootPowerPanel.theme.power.confirmContentPixelSize
                        wrapMode: Text.Wrap
                        bottomPadding: rootPowerPanel.theme.power.confirmContentBottomPadding
                    }

                    Row {
                        width: parent.width
                        spacing: rootPowerPanel.theme.power.confirmButtonSpacing

                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: rootPowerPanel.theme.power.actionHeight
                            radius: rootPowerPanel.theme.power.actionRadius
                            color: cancelHover.hovered ? rootPowerPanel.theme.powerActionHoverBackground : rootPowerPanel.theme.powerActionBackground

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: rootPowerPanel.theme.powerActionText
                                font.pixelSize: rootPowerPanel.theme.power.actionTextPixelSize
                            }

                            HoverHandler {
                                id: cancelHover

                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: rootPowerPanel.cancelPendingAction()
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: rootPowerPanel.theme.animationFastDuration
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: rootPowerPanel.theme.power.actionHeight
                            radius: rootPowerPanel.theme.power.actionRadius
                            color: confirmHover.hovered ? rootPowerPanel.theme.powerActionHoverBackground : rootPowerPanel.theme.powerActionBackground

                            Text {
                                anchors.centerIn: parent
                                text: "Confirm"
                                color: rootPowerPanel.theme.powerActionText
                                font.pixelSize: rootPowerPanel.theme.power.actionTextPixelSize
                            }

                            HoverHandler {
                                id: confirmHover

                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: rootPowerPanel.confirmPendingAction()
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
