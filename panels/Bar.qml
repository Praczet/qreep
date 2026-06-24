import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core" as Core
import "../modules" as Modules

PanelWindow {
    id: rootBar

    required property QtObject theme

    property alias leftSlotItems: leftSlot.data
    property alias centerSlotItems: centerSlot.data
    property alias rightSlotItems: rightSlot.data
    property alias overlayItems: overlayLayer.data

    signal osdTestRequested(string message, int durationMs)

    Core.EventStore {
        id: eventStore
        log: qreepLog
    }

    Core.Log {
        id: qreepLog

        notificationBackend: rootBar.theme.logNotificationBackend
        notifyWarnings: rootBar.theme.logNotifyWarnings
        notifyErrors: rootBar.theme.logNotifyErrors
        notificationDuration: rootBar.theme.logNotificationDuration
        warningColor: rootBar.theme.logWarningColor
        errorColor: rootBar.theme.logErrorColor
    }

    Core.PowerService {
        id: powerService
        log: qreepLog
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: rootBar.theme.bar.height
    color: "transparent"

    WlrLayershell.namespace: "qreep-bar"

    Rectangle {
        anchors.fill: parent
        color: rootBar.theme.barBackground

        Row {
            id: leftSlot
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: rootBar.theme.bar.sideMargin
            }
            spacing: rootBar.theme.bar.itemSpacing

            Modules.OsdTestButton {
                id: osdTestButton

                theme: rootBar.theme

                onClicked: rootBar.osdTestRequested("Qreep OSD test", rootBar.theme.osd.defaultDuration)
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }
        }

        Row {
            id: centerSlot

            anchors.centerIn: parent
            spacing: rootBar.theme.bar.itemSpacing

            Modules.Clock {
                id: clock

                theme: rootBar.theme
                events: eventStore

                onRightClicked: calendarPopup.visible = !calendarPopup.visible
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }
        }

        Row {
            id: rightSlot

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: rootBar.theme.bar.sideMargin
            }
            spacing: rootBar.theme.bar.itemSpacing

            Modules.Borg {
                id: borg

                theme: rootBar.theme

                onClicked: {
                    sharedTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }

            Modules.PowerButton {
                id: powerButton

                theme: rootBar.theme

                onClicked: {
                    powerPanel.visible = !powerPanel.visible;
                    sharedTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }
        }

        Item {
            id: overlayLayer

            anchors.fill: parent
            z: 10
        }

        SharedTooltip {
            id: sharedTooltip

            theme: rootBar.theme
        }

        CalendarPopup {
            id: calendarPopup

            theme: rootBar.theme
            anchorItem: clock
            events: eventStore
        }

        PowerPanel {
            id: powerPanel

            theme: rootBar.theme
            anchorItem: powerButton

            onActionRequested: action => powerService.request(action)
        }
    }
}
