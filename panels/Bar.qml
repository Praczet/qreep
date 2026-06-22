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
        }

        CalendarPopup {
            id: calendarPopup

            theme: qreepTheme
            anchorItem: clock
            events: eventStore
        }
    }
}
