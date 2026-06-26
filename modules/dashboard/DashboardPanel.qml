import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootDashboardPanel

    required property QtObject theme
    required property QtObject service

    signal closeRequested()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: Qt.rgba(rootDashboardPanel.theme.barBackground.r, rootDashboardPanel.theme.barBackground.g, rootDashboardPanel.theme.barBackground.b, rootDashboardPanel.theme.dashboard.overlayOpacity)

    WlrLayershell.namespace: "qreep-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusiveZone: 0

    Component.onCompleted: {
        background.forceActiveFocus();
        enterTimer.restart();
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: rootDashboardPanel.closeRequested()
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: {
            for (let index = 0; index < cardRepeater.count; index++) {
                const card = cardRepeater.itemAt(index);

                if (card)
                    card.entered = true;
            }
        }
    }

    Rectangle {
        id: background

        anchors.fill: parent
        color: "transparent"
        focus: true

        MouseArea {
            anchors.fill: parent
            onClicked: rootDashboardPanel.closeRequested()
        }
    }

    Repeater {
        id: cardRepeater

        model: rootDashboardPanel.service.blocks

        DashboardCard {
            required property var modelData

            theme: rootDashboardPanel.theme
            block: modelData
        }
    }

    Rectangle {
        visible: rootDashboardPanel.service.error.length > 0
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: rootDashboardPanel.theme.dashboard.placementMargin
        }
        width: Math.min(620, parent.width - rootDashboardPanel.theme.dashboard.placementMargin * 2)
        height: errorText.implicitHeight + rootDashboardPanel.theme.dashboard.cardPadding * 2
        radius: rootDashboardPanel.theme.dashboard.cardRadius
        color: Qt.rgba(rootDashboardPanel.theme.borg.errorColor.r, rootDashboardPanel.theme.borg.errorColor.g, rootDashboardPanel.theme.borg.errorColor.b, 0.16)
        border.width: rootDashboardPanel.theme.dashboard.cardBorderWidth
        border.color: rootDashboardPanel.theme.borg.errorColor

        Text {
            id: errorText

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: rootDashboardPanel.theme.dashboard.cardPadding
            }
            text: rootDashboardPanel.service.error
            color: rootDashboardPanel.theme.powerConfirmText
            font.pixelSize: rootDashboardPanel.theme.dashboard.bodyPixelSize
            wrapMode: Text.Wrap
        }
    }
}
