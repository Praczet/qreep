import QtQuick
import QtQuick.Effects
import Quickshell
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
    property real progress: -1
    readonly property string normalizedPosition: normalizePosition(position)
    readonly property bool isBottomPosition: normalizedPosition.indexOf("bottom") === 0
    readonly property bool isLeftPosition: normalizedPosition.indexOf("left") !== -1
    readonly property bool isRightPosition: normalizedPosition.indexOf("right") !== -1
    readonly property bool hasIcon: icon.length > 0
    readonly property bool hasTitle: title.length > 0
    readonly property bool hasProgress: progress >= 0
    readonly property real clampedProgress: Math.max(0, Math.min(1, progress))
    readonly property int activeIconSize: hasProgress ? theme.osd.progressIconSize : iconSize
    readonly property int maxTextWidth: Math.max(1, width - theme.osd.screenPadding * 2 - theme.osd.horizontalPadding * 2 - (hasIcon ? activeIconSize + theme.osd.contentSpacing : 0))

    OsdService {
        id: osdService

        theme: rootOsd.theme

        onMessageRequested: (message, durationMs, position, title, icon, iconSize, progress) => rootOsd.showMessage(message, durationMs, position, title, icon, iconSize, progress)
        onHideRequested: rootOsd.hideMessage()
    }

    function normalizePosition(position) {
        const requestedPosition = String(position || rootOsd.theme.osd.defaultPosition).toLowerCase();
        const allowedPositions = ["top", "top-left", "top-right", "bottom", "bottom-left", "bottom-right"];

        return allowedPositions.indexOf(requestedPosition) >= 0 ? requestedPosition : rootOsd.theme.osd.defaultPosition;
    }

    function showMessage(message, durationMs, position, title, icon, iconSize, progress) {
        const parsedDuration = Number(durationMs);
        const parsedIconSize = Number(iconSize);
        const parsedProgress = Number(progress);

        rootOsd.icon = icon || "";
        rootOsd.title = title || "";
        rootOsd.message = message;
        rootOsd.position = normalizePosition(position);
        rootOsd.active = true;
        rootOsd.iconSize = Number.isFinite(parsedIconSize) && parsedIconSize > 0 ? parsedIconSize : rootOsd.theme.osd.iconSize;
        rootOsd.progress = Number.isFinite(parsedProgress) ? parsedProgress : -1;
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

        width: rootOsd.hasProgress ? Math.min(rootOsd.theme.osd.progressCardWidth, rootOsd.width - rootOsd.theme.osd.screenPadding * 2) : Math.min(osdContent.implicitWidth + rootOsd.theme.osd.horizontalPadding * 2, rootOsd.width - rootOsd.theme.osd.screenPadding * 2)
        height: osdLayout.implicitHeight + rootOsd.theme.osd.verticalPadding * 2
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

        Column {
            id: osdLayout

            anchors.centerIn: parent
            width: parent.width - rootOsd.theme.osd.horizontalPadding * 2
            spacing: rootOsd.hasProgress ? rootOsd.theme.osd.progressSpacing : 0

            Row {
                id: osdContent

                width: rootOsd.hasProgress ? parent.width : implicitWidth
                height: Math.max(rootOsd.hasIcon ? rootOsd.activeIconSize : 0, osdTextLayout.implicitHeight)
                spacing: rootOsd.theme.osd.contentSpacing

                Item {
                    width: rootOsd.activeIconSize
                    height: rootOsd.activeIconSize
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

                        width: rootOsd.hasProgress ? implicitWidth : Math.min(implicitWidth, rootOsd.maxTextWidth)
                        visible: rootOsd.hasTitle
                        text: rootOsd.title
                        color: rootOsd.theme.calendarHeaderText
                        font.pixelSize: rootOsd.hasProgress ? rootOsd.theme.osd.progressTitleTextPixelSize : rootOsd.theme.osd.titleTextPixelSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        id: osdMessage

                        width: rootOsd.hasProgress ? implicitWidth : Math.min(implicitWidth, rootOsd.maxTextWidth)
                        text: rootOsd.message
                        color: rootOsd.hasTitle ? rootOsd.theme.calendarDayText : rootOsd.theme.calendarHeaderText
                        font.pixelSize: rootOsd.hasProgress ? rootOsd.theme.osd.progressMessageTextPixelSize : rootOsd.theme.osd.messageTextPixelSize
                        font.weight: rootOsd.hasTitle ? Font.Normal : Font.DemiBold
                        wrapMode: Text.Wrap
                        horizontalAlignment: rootOsd.hasProgress ? Text.AlignHCenter : Text.AlignLeft
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: rootOsd.theme.osd.progressHeight
                visible: rootOsd.hasProgress
                radius: height / 2
                color: rootOsd.theme.moduleHoverBackground

                Rectangle {
                    width: parent.width * rootOsd.clampedProgress
                    height: parent.height
                    radius: parent.radius
                    color: rootOsd.theme.primaryText
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
