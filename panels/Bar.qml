import QtQuick
import Quickshell
import "../modules" as Modules
import "../theme" as Theme

PanelWindow {
    id: rootBar

    Theme.QreepTheme {
        id: qreepTheme
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
            anchors.centerIn: parent
            theme: qreepTheme
        }
    }
}
