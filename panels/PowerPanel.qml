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

    implicitWidth: theme.powerSidebarWidth
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
        color: Qt.rgba(rootPowerPanel.theme.calendarBackground.r, rootPowerPanel.theme.calendarBackground.g, rootPowerPanel.theme.calendarBackground.b, rootPowerPanel.theme.powerSidebarOpacity)

        Rectangle {
            id: sidebar

            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: actionCard

                anchors.centerIn: parent
                width: rootPowerPanel.theme.powerCardWidth
                height: (rootPowerPanel.pendingAction === null ? actionList.implicitHeight : confirmActionList.implicitHeight) + rootPowerPanel.theme.powerCardPadding * 2
                radius: rootPowerPanel.theme.powerCardRadius
                color: rootPowerPanel.theme.moduleHoverBackground

                Column {
                    id: actionList
                    visible: rootPowerPanel.pendingAction === null

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootPowerPanel.theme.powerCardPadding
                    }
                    spacing: rootPowerPanel.theme.powerActionSpacing

                    Repeater {
                        model: rootPowerPanel.actions

                        delegate: Rectangle {
                            id: actionButton

                            required property var modelData

                            width: parent.width
                            height: rootPowerPanel.theme.powerActionHeight
                            radius: rootPowerPanel.theme.powerActionRadius
                            color: actionHover.hovered ? rootPowerPanel.theme.powerActionHoverBackground : rootPowerPanel.theme.powerActionBackground

                            Row {
                                anchors.centerIn: parent
                                spacing: rootPowerPanel.theme.powerActionContentSpacing

                                Item {
                                    width: rootPowerPanel.theme.powerActionIconSize
                                    height: rootPowerPanel.theme.powerActionIconSize
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
                                        colorization: rootPowerPanel.theme.powerActionIconColorization
                                        brightness: rootPowerPanel.theme.powerActionIconBrightness
                                        colorizationColor: rootPowerPanel.theme.powerActionIconColor
                                    }
                                }

                                Text {
                                    width: rootPowerPanel.theme.powerActionLabelWidth
                                    text: actionButton.modelData.label
                                    color: rootPowerPanel.theme.powerActionText
                                    font.pixelSize: rootPowerPanel.theme.powerActionTextPixelSize
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
                        margins: rootPowerPanel.theme.powerCardPadding
                    }
                    spacing: rootPowerPanel.theme.powerActionSpacing

                    Text {
                        width: parent.width
                        text: rootPowerPanel.pendingAction !== null ? rootPowerPanel.pendingAction.confirmTitle : ""
                        color: rootPowerPanel.theme.powerConfirmText
                        font.pixelSize: rootPowerPanel.theme.powerConfirmTitlePixelSize
                        font.bold: true
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        text: rootPowerPanel.pendingAction !== null ? rootPowerPanel.pendingAction.confirmContent : ""
                        color: rootPowerPanel.theme.powerConfirmText
                        font.pixelSize: rootPowerPanel.theme.powerConfirmContentPixelSize
                        wrapMode: Text.Wrap
                        bottomPadding: rootPowerPanel.theme.powerConfirmContentBottomPadding
                    }

                    Row {
                        width: parent.width
                        spacing: rootPowerPanel.theme.powerConfirmButtonSpacing

                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: rootPowerPanel.theme.powerActionHeight
                            radius: rootPowerPanel.theme.powerActionRadius
                            color: cancelHover.hovered ? rootPowerPanel.theme.powerActionHoverBackground : rootPowerPanel.theme.powerActionBackground

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: rootPowerPanel.theme.powerActionText
                                font.pixelSize: rootPowerPanel.theme.powerActionTextPixelSize
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
                            height: rootPowerPanel.theme.powerActionHeight
                            radius: rootPowerPanel.theme.powerActionRadius
                            color: confirmHover.hovered ? rootPowerPanel.theme.powerActionHoverBackground : rootPowerPanel.theme.powerActionBackground

                            Text {
                                anchors.centerIn: parent
                                text: "Confirm"
                                color: rootPowerPanel.theme.powerActionText
                                font.pixelSize: rootPowerPanel.theme.powerActionTextPixelSize
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
