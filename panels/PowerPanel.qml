import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

PopupWindow {
    id: rootPowerPanel

    required property QtObject theme
    required property Item anchorItem

    signal actionRequested(string action)

    readonly property var actions: [
        {
            icon: "system-lock-screen-symbolic",
            label: "Lock",
            action: "lock"
        },
        {
            icon: "system-log-out-symbolic",
            label: "Log out",
            action: "logout"
        },
        {
            icon: "media-playback-pause-symbolic",
            label: "Suspend",
            action: "suspend"
        },
        {
            icon: "system-reboot-symbolic",
            label: "Reboot",
            action: "reboot"
        },
        {
            icon: "system-shutdown-symbolic",
            label: "Power off",
            action: "poweroff"
        }
    ]

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

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: rootPowerPanel.visible
        onActivated: rootPowerPanel.visible = false
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
                height: actionList.implicitHeight + rootPowerPanel.theme.powerCardPadding * 2
                radius: rootPowerPanel.theme.powerCardRadius
                color: rootPowerPanel.theme.moduleHoverBackground

                Column {
                    id: actionList

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
                                spacing: 14

                                Item {
                                    width: 30
                                    height: 30
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
                                        colorization: 1
                                        brightness: 1.2
                                        colorizationColor: rootPowerPanel.theme.powerActionIconColor
                                    }
                                }

                                Text {
                                    width: 92
                                    text: actionButton.modelData.label
                                    color: rootPowerPanel.theme.powerActionText
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            HoverHandler {
                                id: actionHover

                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: {
                                    rootPowerPanel.actionRequested(actionButton.modelData.action);
                                    rootPowerPanel.visible = false;
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
