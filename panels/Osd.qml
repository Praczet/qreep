import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: rootOsd

    required property QtObject theme

    property string message
    property bool active: false

    IpcHandler {
        target: "osd"

        function showMessage(message: string, durationMs: string) {
            rootOsd.showMessage(message, durationMs);
        }

        function hideMessage() {
            rootOsd.hideMessage();
        }
    }

    function showMessage(message, durationMs) {
        const parsedDuration = Number(durationMs);

        rootOsd.message = message;
        rootOsd.active = true;
        hideTimer.interval = Number.isFinite(parsedDuration) && parsedDuration > 0 ? parsedDuration : rootOsd.theme.osdDefaultDuration;
        hideTimer.restart();
    }

    function hideMessage() {
        hideTimer.stop();
        active = false;
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: rootOsd.theme.osdPanelHeight
    visible: active
    color: "transparent"
    mask: Region {
        item: osdCard
    }

    WlrLayershell.namespace: "qreep-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    Rectangle {
        id: osdCard

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: rootOsd.theme.osdTopMargin
        }

        width: Math.min(osdText.implicitWidth + rootOsd.theme.osdHorizontalPadding * 2, rootOsd.width - rootOsd.theme.osdScreenPadding * 2)
        implicitHeight: osdText.implicitHeight + rootOsd.theme.osdVerticalPadding * 2
        radius: rootOsd.theme.osdRadius
        color: Qt.rgba(rootOsd.theme.calendarBackground.r, rootOsd.theme.calendarBackground.g, rootOsd.theme.calendarBackground.b, rootOsd.theme.osdOpacity)
        border.width: rootOsd.theme.osdBorderWidth
        border.color: rootOsd.theme.moduleHoverBackground

        Text {
            id: osdText

            anchors.centerIn: parent
            width: parent.width - rootOsd.theme.osdHorizontalPadding * 2
            text: rootOsd.message
            color: rootOsd.theme.calendarHeaderText
            font.pixelSize: rootOsd.theme.osdTextPixelSize
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }

    Timer {
        id: hideTimer

        repeat: false
        onTriggered: rootOsd.active = false
    }
}
