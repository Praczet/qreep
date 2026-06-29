import QtQuick
import Quickshell

PopupWindow {
    id: rootMprisTooltip

    required property QtObject theme
    required property QtObject service

    property Item anchorItem

    anchor {
        item: rootMprisTooltip.anchorItem
        rect.x: rootMprisTooltip.anchorItem ? rootMprisTooltip.anchorItem.width / 2 - rootMprisTooltip.width / 2 : 0
        rect.y: rootMprisTooltip.anchorItem ? rootMprisTooltip.anchorItem.height + rootMprisTooltip.theme.modules.bar.tooltip.offsetY : 0
    }

    implicitWidth: rootMprisTooltip.theme.modules.bar.mpris.tooltipWidth
    implicitHeight: tooltipLayout.implicitHeight + rootMprisTooltip.theme.modules.bar.tooltip.verticalPadding * 2
    color: "transparent"
    grabFocus: false

    function showFor(anchorItem) {
        hideTimer.stop();
        hideAnimation.stop();
        rootMprisTooltip.anchorItem = anchorItem;

        if (visible) {
            tooltipBody.scale = 1;
            return;
        }

        showTimer.restart();
    }

    function hideLater() {
        showTimer.stop();

        if (visible)
            hideTimer.restart();
    }

    Rectangle {
        id: tooltipBody

        anchors.fill: parent
        transformOrigin: Item.Center
        scale: 0
        radius: rootMprisTooltip.theme.modules.bar.tooltip.radius
        color: rootMprisTooltip.theme.modules.bar.tooltip.backgroundColor
        border.width: rootMprisTooltip.theme.modules.bar.tooltip.borderWidth
        border.color: rootMprisTooltip.theme.modules.bar.moduleHoverBackgroundColor

        Row {
            id: tooltipLayout

            anchors {
                fill: parent
                margins: rootMprisTooltip.theme.modules.bar.tooltip.padding
            }
            spacing: rootMprisTooltip.theme.modules.bar.mpris.tooltipSpacing

            Rectangle {
                width: rootMprisTooltip.theme.modules.bar.mpris.tooltipArtSize
                height: width
                radius: 6
                color: rootMprisTooltip.theme.modules.bar.moduleHoverBackgroundColor
                clip: true

                Image {
                    id: albumArt

                    anchors.fill: parent
                    source: rootMprisTooltip.service.artSource
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: albumArt.status !== Image.Ready
                    text: ""
                    color: rootMprisTooltip.theme.modules.bar.secondaryTextColor
                    font.family: rootMprisTooltip.theme.iconFontFamily
                    font.pixelSize: 28
                }
            }

            Column {
                width: parent.width - rootMprisTooltip.theme.modules.bar.mpris.tooltipArtSize - parent.spacing
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    text: "From: " + rootMprisTooltip.service.playerSource
                    color: rootMprisTooltip.theme.modules.bar.secondaryTextColor
                    elide: Text.ElideRight
                    font.pixelSize: rootMprisTooltip.theme.modules.bar.mpris.tooltipBodyPixelSize
                }

                Text {
                    width: parent.width
                    text: rootMprisTooltip.service.tooltipSubtitle
                    color: rootMprisTooltip.theme.modules.bar.tooltip.titleTextColor
                    elide: Text.ElideRight
                    font.pixelSize: rootMprisTooltip.theme.modules.bar.mpris.tooltipTitlePixelSize
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: rootMprisTooltip.service.tooltipDetail
                    color: rootMprisTooltip.theme.modules.bar.tooltip.contentTextColor
                    wrapMode: Text.Wrap
                    font.pixelSize: rootMprisTooltip.theme.modules.bar.mpris.tooltipBodyPixelSize
                    lineHeight: rootMprisTooltip.theme.modules.bar.tooltip.contentLineHeight
                }
            }
        }
    }

    Timer {
        id: showTimer

        interval: rootMprisTooltip.theme.modules.bar.tooltip.showDelay
        repeat: false
        onTriggered: {
            rootMprisTooltip.visible = true;
            showAnimation.restart();
        }
    }

    Timer {
        id: hideTimer

        interval: rootMprisTooltip.theme.modules.bar.tooltip.hideDelay
        repeat: false
        onTriggered: hideAnimation.restart()
    }

    SequentialAnimation {
        id: showAnimation

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: 0
            to: rootMprisTooltip.theme.modules.bar.tooltip.popScale
            duration: rootMprisTooltip.theme.modules.bar.tooltip.showOutDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: rootMprisTooltip.theme.modules.bar.tooltip.popScale
            to: 1
            duration: rootMprisTooltip.theme.modules.bar.tooltip.showSettleDuration
            easing.type: Easing.InOutCubic
        }
    }

    SequentialAnimation {
        id: hideAnimation

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: 1
            to: rootMprisTooltip.theme.modules.bar.tooltip.popScale
            duration: rootMprisTooltip.theme.modules.bar.tooltip.hideOutDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: rootMprisTooltip.theme.modules.bar.tooltip.popScale
            to: 0
            duration: rootMprisTooltip.theme.modules.bar.tooltip.hideInDuration
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: rootMprisTooltip.visible = false
        }
    }
}
