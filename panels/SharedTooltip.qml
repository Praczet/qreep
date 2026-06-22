import QtQuick
import Quickshell

PopupWindow {
    id: rootSharedTooltip

    required property QtObject theme

    property Item anchorItem
    property Item pendingAnchorItem
    property string title
    property string content
    property string style: "normal"
    property string pendingTitle
    property string pendingContent
    property string pendingStyle: "normal"

    anchor {
        item: rootSharedTooltip.anchorItem
        rect.x: rootSharedTooltip.anchorItem ? rootSharedTooltip.anchorItem.width / 2 - rootSharedTooltip.width / 2 : 0
        rect.y: rootSharedTooltip.anchorItem ? rootSharedTooltip.anchorItem.height + 8 : 0
    }

    implicitWidth: Math.max(180, tooltipTitle.implicitWidth + 32, tooltipText.implicitWidth + 32)
    implicitHeight: tooltipLayout.implicitHeight + 24
    color: "transparent"
    grabFocus: false

    function showFor(anchorItem, title, content, style) {
        hideTimer.stop();

        pendingAnchorItem = anchorItem;
        pendingTitle = title;
        pendingContent = content;
        pendingStyle = style || "normal";

        if (visible) {
            applyPendingRequest();
            return;
        }

        showTimer.restart();
    }

    function hideLater() {
        showTimer.stop();

        if (visible)
            hideTimer.restart();
    }

    function applyPendingRequest() {
        anchorItem = pendingAnchorItem;
        title = pendingTitle;
        content = pendingContent;
        style = pendingStyle;
        visible = true;
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: rootSharedTooltip.theme.calendarBackground
        border.width: 1
        border.color: rootSharedTooltip.style === "warning" ? rootSharedTooltip.theme.eventIndicator : rootSharedTooltip.theme.moduleHoverBackground

        Column {
            id: tooltipLayout

            anchors {
                fill: parent
                margins: 12
            }
            spacing: 4

            Text {
                id: tooltipTitle

                visible: text.length > 0
                text: rootSharedTooltip.title
                color: rootSharedTooltip.theme.calendarHeaderText
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                id: tooltipText

                text: rootSharedTooltip.content
                color: rootSharedTooltip.theme.calendarDayText
                font.pixelSize: 12
                lineHeight: 1.15
            }
        }
    }

    Timer {
        id: showTimer

        interval: 400
        repeat: false
        onTriggered: rootSharedTooltip.applyPendingRequest()
    }

    Timer {
        id: hideTimer

        interval: 500
        repeat: false
        onTriggered: rootSharedTooltip.visible = false
    }
}
