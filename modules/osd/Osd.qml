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
    property string position: theme.modules.osd.defaultPosition
    property int iconSize: theme.modules.osd.iconSize
    property real progress: -1
    readonly property string normalizedPosition: normalizePosition(position)
    readonly property bool isBottomPosition: normalizedPosition.indexOf("bottom") === 0
    readonly property bool isLeftPosition: normalizedPosition.indexOf("left") !== -1
    readonly property bool isRightPosition: normalizedPosition.indexOf("right") !== -1
    readonly property bool hasIcon: icon.length > 0
    readonly property bool hasTitle: title.length > 0
    readonly property bool hasProgress: progress >= 0
    readonly property real clampedProgress: Math.max(0, Math.min(1, progress))
    readonly property int activeIconSize: hasProgress ? theme.modules.osd.progressIconSize : iconSize
    readonly property int maxTextWidth: Math.max(1, width - theme.modules.osd.screenPadding * 2 - theme.modules.osd.horizontalPadding * 2 - (hasIcon ? activeIconSize + theme.modules.osd.contentSpacing : 0))

    OsdService {
        id: osdService

        theme: rootOsd.theme

        onMessageRequested: (message, durationMs, position, title, icon, iconSize, progress) => rootOsd.showMessage(message, durationMs, position, title, icon, iconSize, progress)
        onHideRequested: rootOsd.hideMessage()
    }

    function normalizePosition(position) {
        const requestedPosition = String(position || rootOsd.theme.modules.osd.defaultPosition).toLowerCase();
        const allowedPositions = ["top", "top-left", "top-right", "bottom", "bottom-left", "bottom-right"];

        return allowedPositions.indexOf(requestedPosition) >= 0 ? requestedPosition : rootOsd.theme.modules.osd.defaultPosition;
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
        rootOsd.iconSize = Number.isFinite(parsedIconSize) && parsedIconSize > 0 ? parsedIconSize : rootOsd.theme.modules.osd.iconSize;
        rootOsd.progress = Number.isFinite(parsedProgress) ? parsedProgress : -1;
        hideTimer.interval = Number.isFinite(parsedDuration) && parsedDuration > 0 ? parsedDuration : rootOsd.theme.modules.osd.defaultDuration;
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

    implicitHeight: Math.max(osdCard.height + rootOsd.theme.modules.osd.topMargin * 2, rootOsd.theme.modules.osd.panelHeight)
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

        width: rootOsd.hasProgress ? Math.min(rootOsd.theme.modules.osd.progressCardWidth, rootOsd.width - rootOsd.theme.modules.osd.screenPadding * 2) : Math.min(osdContent.implicitWidth + rootOsd.theme.modules.osd.horizontalPadding * 2, rootOsd.width - rootOsd.theme.modules.osd.screenPadding * 2)
        height: osdLayout.implicitHeight + rootOsd.theme.modules.osd.verticalPadding * 2
        x: {
            if (rootOsd.isLeftPosition)
                return rootOsd.theme.modules.osd.screenPadding;

            if (rootOsd.isRightPosition)
                return rootOsd.width - width - rootOsd.theme.modules.osd.screenPadding;

            return (rootOsd.width - width) / 2;
        }
        y: rootOsd.isBottomPosition ? rootOsd.height - height - rootOsd.theme.modules.osd.topMargin : rootOsd.theme.modules.osd.topMargin
        radius: rootOsd.theme.modules.osd.radius
        color: rootOsd.theme.modules.osd.backgroundColor
        border.width: rootOsd.theme.modules.osd.borderWidth
        border.color: rootOsd.theme.modules.osd.borderColor

        Column {
            id: osdLayout

            anchors.centerIn: parent
            width: parent.width - rootOsd.theme.modules.osd.horizontalPadding * 2
            spacing: rootOsd.hasProgress ? rootOsd.theme.modules.osd.progressSpacing : 0

            Row {
                id: osdContent

                width: rootOsd.hasProgress ? parent.width : implicitWidth
                height: Math.max(rootOsd.hasIcon ? rootOsd.activeIconSize : 0, osdTextLayout.implicitHeight)
                spacing: rootOsd.theme.modules.osd.contentSpacing

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
                        colorization: rootOsd.theme.modules.osd.iconColorization
                        brightness: rootOsd.theme.modules.osd.iconBrightness
                        colorizationColor: rootOsd.theme.modules.osd.iconColor
                    }
                }

                Column {
                    id: osdTextLayout

                    width: Math.min(implicitWidth, rootOsd.maxTextWidth)
                    spacing: rootOsd.theme.modules.osd.textSpacing
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: osdTitle

                        width: rootOsd.hasProgress ? implicitWidth : Math.min(implicitWidth, rootOsd.maxTextWidth)
                        visible: rootOsd.hasTitle
                        text: rootOsd.title
                        color: rootOsd.theme.modules.osd.primaryTextColor
                        font.pixelSize: rootOsd.hasProgress ? rootOsd.theme.modules.osd.progressTitleTextPixelSize : rootOsd.theme.modules.osd.titleTextPixelSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        id: osdMessage

                        width: rootOsd.hasProgress ? implicitWidth : Math.min(implicitWidth, rootOsd.maxTextWidth)
                        text: rootOsd.message
                        color: rootOsd.hasTitle ? rootOsd.theme.modules.osd.secondaryTextColor : rootOsd.theme.modules.osd.primaryTextColor
                        font.pixelSize: rootOsd.hasProgress ? rootOsd.theme.modules.osd.progressMessageTextPixelSize : rootOsd.theme.modules.osd.messageTextPixelSize
                        font.weight: rootOsd.hasTitle ? Font.Normal : Font.DemiBold
                        wrapMode: Text.Wrap
                        horizontalAlignment: rootOsd.hasProgress ? Text.AlignHCenter : Text.AlignLeft
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: rootOsd.theme.modules.osd.progressHeight
                visible: rootOsd.hasProgress
                radius: height / 2
                color: rootOsd.theme.modules.osd.borderColor

                Rectangle {
                    width: parent.width * rootOsd.clampedProgress
                    height: parent.height
                    radius: parent.radius
                    color: rootOsd.theme.modules.osd.primaryTextColor
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
