import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core" as Core
import "../modules" as Modules

PanelWindow {
    id: rootBar

    required property QtObject theme

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

    implicitHeight: rootBar.theme.barHeight
    color: "transparent"

    WlrLayershell.namespace: "qreep-bar"

    Rectangle {
        anchors.fill: parent
        color: rootBar.theme.barBackground

        Modules.OsdTestButton {
            id: osdTestButton

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: rootBar.theme.osdTestButtonLeftMargin
            }
            theme: rootBar.theme

            onClicked: rootBar.osdTestRequested("Qreep OSD test", rootBar.theme.osdDefaultDuration)
            onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
            onTooltipHideRequested: sharedTooltip.hideLater()
        }

        Modules.Clock {
            id: clock

            anchors.centerIn: parent
            theme: rootBar.theme
            events: eventStore

            onRightClicked: calendarPopup.visible = !calendarPopup.visible
            onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
            onTooltipHideRequested: sharedTooltip.hideLater()
        }

        Modules.Borg {
            id: borg

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            theme: rootBar.theme

            onClicked: {
                sharedTooltip.hideLater();
            }
            onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
            onTooltipHideRequested: sharedTooltip.hideLater()
        }

        Modules.PowerButton {
            id: powerButton

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: rootBar.theme.barPowerButtonRightMargin
            }
            theme: rootBar.theme

            onClicked: {
                powerPanel.visible = !powerPanel.visible;
                sharedTooltip.hideLater();
            }
            onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
            onTooltipHideRequested: sharedTooltip.hideLater()
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
