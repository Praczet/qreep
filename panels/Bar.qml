import QtQuick
import Quickshell
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
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: qreepTheme.barHeight
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: qreepTheme.barBackground

        Modules.Clock {
            id: clock

            anchors.centerIn: parent
            theme: qreepTheme
            events: eventStore

            onRightClicked: calendarPopup.visible = !calendarPopup.visible
            onTooltipShowRequested: (anchorItem, title, content, style) =>
                sharedTooltip.showFor(anchorItem, title, content, style)
            onTooltipHideRequested: sharedTooltip.hideLater()
        }

        Modules.PowerButton {
            id: powerButton

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 4
            }
            theme: qreepTheme

            onTooltipShowRequested: (anchorItem, title, content, style) =>
                sharedTooltip.showFor(anchorItem, title, content, style)
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
    }
}
