import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootDashboardPanel

    required property QtObject theme
    required property QtObject service
    property QtObject aegisService
    required property bool panelOpen

    property bool presented: false

    signal closeRequested

    implicitWidth: screen.width
    implicitHeight: screen.height

    color: rootDashboardPanel.theme.modules.dashboard.overlayColor
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.namespace: "qreep-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        background.forceActiveFocus();
        if (panelOpen)
            enterTimer.restart();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            enterTimer.restart();
            return;
        }

        enterTimer.stop();
        presented = false;
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
        onTriggered: presented = true
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
            aegisService: rootDashboardPanel.aegisService
            block: modelData
            entered: rootDashboardPanel.presented
        }
    }

    Rectangle {
        visible: rootDashboardPanel.service.error.length > 0
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: rootDashboardPanel.theme.modules.dashboard.placementMargin
        }
        width: Math.min(620, parent.width - rootDashboardPanel.theme.modules.dashboard.placementMargin * 2)
        height: errorText.implicitHeight + rootDashboardPanel.theme.modules.dashboard.cardPadding * 2
        radius: rootDashboardPanel.theme.modules.dashboard.cardRadius
        color: Qt.rgba(rootDashboardPanel.theme.modules.dashboard.errorColor.r, rootDashboardPanel.theme.modules.dashboard.errorColor.g, rootDashboardPanel.theme.modules.dashboard.errorColor.b, 0.16)
        border.width: rootDashboardPanel.theme.modules.dashboard.cardBorderWidth
        border.color: rootDashboardPanel.theme.modules.dashboard.errorColor

        Text {
            id: errorText

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: rootDashboardPanel.theme.modules.dashboard.cardPadding
            }
            text: rootDashboardPanel.service.error
            color: rootDashboardPanel.theme.modules.dashboard.primaryTextColor
            font.pixelSize: rootDashboardPanel.theme.modules.dashboard.bodyPixelSize
            wrapMode: Text.Wrap
        }
    }
}
