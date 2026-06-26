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
        rect.y: rootSharedTooltip.anchorItem ? rootSharedTooltip.anchorItem.height + rootSharedTooltip.theme.tooltip.offsetY : 0
    }

    implicitWidth: Math.max(rootSharedTooltip.theme.tooltip.minimumWidth, tooltipTitle.implicitWidth + rootSharedTooltip.theme.tooltip.horizontalPadding * 2, tooltipText.implicitWidth + rootSharedTooltip.theme.tooltip.horizontalPadding * 2)
    implicitHeight: tooltipLayout.implicitHeight + rootSharedTooltip.theme.tooltip.verticalPadding * 2
    color: "transparent"
    grabFocus: false

    function showFor(anchorItem, title, content, style) {
        hideTimer.stop()
        hideAnimation.stop()

        pendingAnchorItem = anchorItem
        pendingTitle = title
        pendingContent = content
        pendingStyle = style || "normal"

        if (visible) {
            applyPendingRequest(false)
            tooltipBody.scale = 1
            return
        }

        showTimer.restart()
    }

    function hideLater() {
        showTimer.stop()

        if (visible)
            hideTimer.restart()
    }

    function applyPendingRequest(animate) {
        anchorItem = pendingAnchorItem
        title = pendingTitle
        content = pendingContent
        style = pendingStyle
        visible = true

        if (animate)
            showAnimation.restart()
        else
            tooltipBody.scale = 1
    }

    Rectangle {
        id: tooltipBody

        anchors.fill: parent
        transformOrigin: Item.Center
        scale: 0
        radius: rootSharedTooltip.theme.tooltip.radius
        color: rootSharedTooltip.theme.calendarBackground
        border.width: rootSharedTooltip.theme.tooltip.borderWidth
        border.color: rootSharedTooltip.style === "warning" ? rootSharedTooltip.theme.eventIndicator : rootSharedTooltip.theme.moduleHoverBackground

        Column {
            id: tooltipLayout

            anchors {
                fill: parent
                margins: rootSharedTooltip.theme.tooltip.padding
            }
            spacing: rootSharedTooltip.theme.tooltip.spacing

            Text {
                id: tooltipTitle

                visible: text.length > 0
                text: rootSharedTooltip.title
                color: rootSharedTooltip.theme.calendarHeaderText
                font.pixelSize: rootSharedTooltip.theme.tooltip.titlePixelSize
                font.weight: Font.DemiBold
            }

            Text {
                id: tooltipText

                text: rootSharedTooltip.content
                color: rootSharedTooltip.theme.calendarDayText
                font.pixelSize: rootSharedTooltip.theme.tooltip.contentPixelSize
                lineHeight: rootSharedTooltip.theme.tooltip.contentLineHeight
            }
        }
    }

    Timer {
        id: showTimer

        interval: rootSharedTooltip.theme.tooltip.showDelay
        repeat: false
        onTriggered: rootSharedTooltip.applyPendingRequest(true)
    }

    Timer {
        id: hideTimer

        interval: rootSharedTooltip.theme.tooltip.hideDelay
        repeat: false
        onTriggered: hideAnimation.restart()
    }

    SequentialAnimation {
        id: showAnimation

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: 0
            to: rootSharedTooltip.theme.tooltip.popScale
            duration: rootSharedTooltip.theme.tooltip.showOutDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: rootSharedTooltip.theme.tooltip.popScale
            to: 1
            duration: rootSharedTooltip.theme.tooltip.showSettleDuration
            easing.type: Easing.InOutCubic
        }
    }

    SequentialAnimation {
        id: hideAnimation

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: 1
            to: rootSharedTooltip.theme.tooltip.popScale
            duration: rootSharedTooltip.theme.tooltip.hideOutDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: rootSharedTooltip.theme.tooltip.popScale
            to: 0
            duration: rootSharedTooltip.theme.tooltip.hideInDuration
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: rootSharedTooltip.visible = false
        }
    }
}
