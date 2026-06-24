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
        rect.y: rootSharedTooltip.anchorItem ? rootSharedTooltip.anchorItem.height + rootSharedTooltip.theme.tooltipOffsetY : 0
    }

    implicitWidth: Math.max(rootSharedTooltip.theme.tooltipMinimumWidth, tooltipTitle.implicitWidth + rootSharedTooltip.theme.tooltipHorizontalPadding * 2, tooltipText.implicitWidth + rootSharedTooltip.theme.tooltipHorizontalPadding * 2)
    implicitHeight: tooltipLayout.implicitHeight + rootSharedTooltip.theme.tooltipVerticalPadding * 2
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
        radius: rootSharedTooltip.theme.tooltipRadius
        color: rootSharedTooltip.theme.calendarBackground
        border.width: rootSharedTooltip.theme.tooltipBorderWidth
        border.color: rootSharedTooltip.style === "warning" ? rootSharedTooltip.theme.eventIndicator : rootSharedTooltip.theme.moduleHoverBackground

        Column {
            id: tooltipLayout

            anchors {
                fill: parent
                margins: rootSharedTooltip.theme.tooltipPadding
            }
            spacing: rootSharedTooltip.theme.tooltipSpacing

            Text {
                id: tooltipTitle

                visible: text.length > 0
                text: rootSharedTooltip.title
                color: rootSharedTooltip.theme.calendarHeaderText
                font.pixelSize: rootSharedTooltip.theme.tooltipTitlePixelSize
                font.weight: Font.DemiBold
            }

            Text {
                id: tooltipText

                text: rootSharedTooltip.content
                color: rootSharedTooltip.theme.calendarDayText
                font.pixelSize: rootSharedTooltip.theme.tooltipContentPixelSize
                lineHeight: rootSharedTooltip.theme.tooltipContentLineHeight
            }
        }
    }

    Timer {
        id: showTimer

        interval: rootSharedTooltip.theme.tooltipShowDelay
        repeat: false
        onTriggered: rootSharedTooltip.applyPendingRequest(true)
    }

    Timer {
        id: hideTimer

        interval: rootSharedTooltip.theme.tooltipHideDelay
        repeat: false
        onTriggered: hideAnimation.restart()
    }

    SequentialAnimation {
        id: showAnimation

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: 0
            to: rootSharedTooltip.theme.tooltipPopScale
            duration: rootSharedTooltip.theme.tooltipShowOutDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: rootSharedTooltip.theme.tooltipPopScale
            to: 1
            duration: rootSharedTooltip.theme.tooltipShowSettleDuration
            easing.type: Easing.InOutCubic
        }
    }

    SequentialAnimation {
        id: hideAnimation

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: 1
            to: rootSharedTooltip.theme.tooltipPopScale
            duration: rootSharedTooltip.theme.tooltipHideOutDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: rootSharedTooltip.theme.tooltipPopScale
            to: 0
            duration: rootSharedTooltip.theme.tooltipHideInDuration
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: rootSharedTooltip.visible = false
        }
    }
}
