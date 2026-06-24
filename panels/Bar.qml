import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core" as Core
import "../modules" as Modules
import "../theme" as Theme

PanelWindow {
    id: rootBar

    Theme.QreepTheme {
        id: qreepTheme
    }

    Core.EventStore {
        id: eventStore
        log: qreepLog
    }

    Core.Log {
        id: qreepLog

        notificationBackend: qreepTheme.logNotificationBackend
        notifyWarnings: qreepTheme.logNotifyWarnings
        notifyErrors: qreepTheme.logNotifyErrors
        notificationDuration: qreepTheme.logNotificationDuration
        warningColor: qreepTheme.logWarningColor
        errorColor: qreepTheme.logErrorColor
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

    implicitHeight: qreepTheme.barHeight
    color: "transparent"

    WlrLayershell.namespace: "qreep-bar"

    Rectangle {
        anchors.fill: parent
        color: qreepTheme.barBackground

        Modules.Clock {
            id: clock

            anchors.centerIn: parent
            theme: qreepTheme
            events: eventStore

            onRightClicked: calendarPopup.visible = !calendarPopup.visible
            onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
            onTooltipHideRequested: sharedTooltip.hideLater()
        }

        Modules.PowerButton {
            id: powerButton

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: qreepTheme.barPowerButtonRightMargin
            }
            theme: qreepTheme

            onClicked: {
                powerPanel.visible = !powerPanel.visible;
                sharedTooltip.hideLater();
            }
            onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
            onTooltipHideRequested: sharedTooltip.hideLater()
        }

        SharedTooltip {
            id: sharedTooltip

            theme: qreepTheme
        }

        CalendarPopup {
            id: calendarPopup

            theme: qreepTheme
            anchorItem: clock
            events: eventStore
        }

        PowerPanel {
            id: powerPanel

            theme: qreepTheme
            anchorItem: powerButton

            onActionRequested: action => powerService.request(action)
        }
    }
}
