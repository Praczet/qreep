import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: rootOsd

    required property QtObject theme

    property string icon
    property string title
    property string message
    property bool active: false
    property string position: theme.osd.defaultPosition
    property int iconSize: theme.osd.iconSize
    readonly property string normalizedPosition: normalizePosition(position)
    readonly property bool isBottomPosition: normalizedPosition.indexOf("bottom") === 0
    readonly property bool isLeftPosition: normalizedPosition.indexOf("left") !== -1
    readonly property bool isRightPosition: normalizedPosition.indexOf("right") !== -1
    readonly property bool hasIcon: icon.length > 0
    readonly property bool hasTitle: title.length > 0
    readonly property int maxTextWidth: Math.max(1, width - theme.osd.screenPadding * 2 - theme.osd.horizontalPadding * 2 - (hasIcon ? iconSize + theme.osd.contentSpacing : 0))

    IpcHandler {
        target: "osd"

        function showMessage(message: string, durationMs: string) {
            rootOsd.showMessage(message, durationMs);
        }

        function showJSON(payload: string) {
            try {
                const request = JSON.parse(payload);

                if (!request.message) {
                    throw new Error("Missing required fields");
                }

                // biome-ignore format: This is a valid use case for optional chaining
                rootOsd.showMessage(request.message, request.durationMs || rootOsd.theme.osd.defaultDuration, request.position || rootOsd.theme.osd.defaultPosition, request.title || "", request.icon || "", request.iconSize || rootOsd.theme.osd.iconSize);
            } catch (e) {
                rootOsd.showMessage("Invalid JSON payload", rootOsd.theme.osd.defaultDuration);
            }
        }

        function hideMessage() {
            rootOsd.hideMessage();
        }
    }

    function normalizePosition(position) {
        const requestedPosition = String(position || rootOsd.theme.osd.defaultPosition).toLowerCase();
        const allowedPositions = ["top", "top-left", "top-right", "bottom", "bottom-left", "bottom-right"];

        return allowedPositions.indexOf(requestedPosition) >= 0 ? requestedPosition : rootOsd.theme.osd.defaultPosition;
    }

    function showMessage(message, durationMs, position, title, icon, iconSize) {
        const parsedDuration = Number(durationMs);
        const parsedIconSize = Number(iconSize);

        rootOsd.icon = icon || "";
        rootOsd.title = title || "";
        rootOsd.message = message;
        rootOsd.position = normalizePosition(position);
        rootOsd.active = true;
        rootOsd.iconSize = Number.isFinite(parsedIconSize) && parsedIconSize > 0 ? parsedIconSize : rootOsd.theme.osd.iconSize;
        hideTimer.interval = Number.isFinite(parsedDuration) && parsedDuration > 0 ? parsedDuration : rootOsd.theme.osd.defaultDuration;
        hideTimer.restart();
    }

    function hideMessage() {
        hideTimer.stop();
        active = false;
    }

    anchors {
        top: !rootOsd.isBottomPosition
        bottom: rootOsd.isBottomPosition
        left: true
        right: true
    }

    implicitHeight: Math.max(osdCard.height + rootOsd.theme.osd.topMargin * 2, rootOsd.theme.osd.panelHeight)
    visible: active
    color: "transparent"
    mask: Region {
        item: osdCard
    }

    WlrLayershell.namespace: "qreep-popup-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    Rectangle {
        id: osdCard

        width: Math.min(osdContent.implicitWidth + rootOsd.theme.osd.horizontalPadding * 2, rootOsd.width - rootOsd.theme.osd.screenPadding * 2)
        height: osdContent.height + rootOsd.theme.osd.verticalPadding * 2
        x: {
            if (rootOsd.isLeftPosition)
                return rootOsd.theme.osd.screenPadding;

            if (rootOsd.isRightPosition)
                return rootOsd.width - width - rootOsd.theme.osd.screenPadding;

            return (rootOsd.width - width) / 2;
        }
        y: rootOsd.isBottomPosition ? rootOsd.height - height - rootOsd.theme.osd.topMargin : rootOsd.theme.osd.topMargin
        radius: rootOsd.theme.osd.radius
        color: Qt.rgba(rootOsd.theme.calendarBackground.r, rootOsd.theme.calendarBackground.g, rootOsd.theme.calendarBackground.b, rootOsd.theme.osd.opacity)
        border.width: rootOsd.theme.osd.borderWidth
        border.color: rootOsd.theme.moduleHoverBackground

        Row {
            id: osdContent

            anchors.centerIn: parent
            width: parent.width - rootOsd.theme.osd.horizontalPadding * 2
            height: Math.max(rootOsd.hasIcon ? rootOsd.iconSize : 0, osdTextLayout.implicitHeight)
            spacing: rootOsd.theme.osd.contentSpacing

            Item {
                width: rootOsd.iconSize
                height: rootOsd.iconSize
                implicitWidth: width
                implicitHeight: height
                anchors.verticalCenter: parent.verticalCenter
                visible: rootOsd.hasIcon

                IconImage {
                    id: osdIcon

                    anchors.fill: parent
                    source: rootOsd.hasIcon ? Quickshell.iconPath(rootOsd.icon, rootOsd.icon) : ""
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: osdIcon
                    colorization: rootOsd.theme.power.actionIconColorization
                    brightness: rootOsd.theme.power.actionIconBrightness
                    colorizationColor: rootOsd.theme.powerActionIconColor
                }
            }

            Column {
                id: osdTextLayout

                width: Math.min(implicitWidth, rootOsd.maxTextWidth)
                spacing: rootOsd.theme.osd.textSpacing
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: osdTitle

                    width: Math.min(implicitWidth, rootOsd.maxTextWidth)
                    visible: rootOsd.hasTitle
                    text: rootOsd.title
                    color: rootOsd.theme.calendarHeaderText
                    font.pixelSize: rootOsd.theme.osd.titleTextPixelSize
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    id: osdMessage

                    width: Math.min(implicitWidth, rootOsd.maxTextWidth)
                    text: rootOsd.message
                    color: rootOsd.hasTitle ? rootOsd.theme.calendarDayText : rootOsd.theme.calendarHeaderText
                    font.pixelSize: rootOsd.theme.osd.messageTextPixelSize
                    font.weight: rootOsd.hasTitle ? Font.Normal : Font.DemiBold
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    Timer {
        id: hideTimer

        repeat: false
        onTriggered: rootOsd.active = false
    }
}
