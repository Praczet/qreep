import QtQuick
import Quickshell

PopupWindow {
    id: rootMprisPanel

    required property QtObject theme
    required property QtObject service
    required property Item anchorItem

    anchor {
        item: rootMprisPanel.anchorItem
        rect.x: rootMprisPanel.anchorItem.width - rootMprisPanel.width
        rect.y: rootMprisPanel.anchorItem.height + rootMprisPanel.theme.modules.bar.mpris.panelTopOffset
    }

    implicitWidth: rootMprisPanel.theme.modules.bar.mpris.panelWidth
    implicitHeight: playerCard.implicitHeight
    visible: false
    color: "transparent"
    grabFocus: true

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: rootMprisPanel.visible
        onActivated: rootMprisPanel.visible = false
    }

    Rectangle {
        id: playerCard

        width: rootMprisPanel.width
        implicitHeight: playerLayout.implicitHeight + rootMprisPanel.theme.modules.bar.mpris.panelPadding * 2
        radius: rootMprisPanel.theme.modules.bar.mpris.panelRadius
        color: rootMprisPanel.theme.modules.bar.tooltip.backgroundColor
        border.width: rootMprisPanel.theme.modules.bar.tooltip.borderWidth
        border.color: rootMprisPanel.theme.modules.bar.moduleHoverBackgroundColor

        Column {
            id: playerLayout

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: rootMprisPanel.theme.modules.bar.mpris.panelPadding
            }
            spacing: rootMprisPanel.theme.modules.bar.mpris.panelRowSpacing

            Row {
                width: parent.width
                spacing: rootMprisPanel.theme.modules.bar.mpris.panelRowSpacing

                Rectangle {
                    width: rootMprisPanel.theme.modules.bar.mpris.panelArtSize
                    height: width
                    radius: 8
                    color: rootMprisPanel.theme.modules.bar.moduleHoverBackgroundColor
                    clip: true

                    Image {
                        id: albumArt

                        anchors.fill: parent
                        source: rootMprisPanel.service.artSource
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: albumArt.status !== Image.Ready
                        text: ""
                        color: rootMprisPanel.theme.modules.bar.secondaryTextColor
                        font.family: rootMprisPanel.theme.iconFontFamily
                        font.pixelSize: 46
                    }
                }

                Column {
                    width: parent.width - rootMprisPanel.theme.modules.bar.mpris.panelArtSize - parent.spacing
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        text: rootMprisPanel.service.title
                        color: rootMprisPanel.theme.modules.bar.tooltip.titleTextColor
                        font.pixelSize: rootMprisPanel.theme.modules.bar.mpris.panelTitlePixelSize
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        text: rootMprisPanel.service.artists
                        color: rootMprisPanel.theme.modules.bar.tooltip.contentTextColor
                        font.pixelSize: rootMprisPanel.theme.modules.bar.mpris.panelBodyPixelSize
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        text: rootMprisPanel.service.album
                        color: rootMprisPanel.theme.modules.bar.secondaryTextColor
                        font.pixelSize: rootMprisPanel.theme.modules.bar.mpris.panelBodyPixelSize
                        wrapMode: Text.Wrap
                    }

                    Text {
                        visible: rootMprisPanel.service.durationText.length > 0
                        width: parent.width
                        text: rootMprisPanel.service.durationText
                        color: rootMprisPanel.theme.modules.bar.secondaryTextColor
                        font.pixelSize: rootMprisPanel.theme.modules.bar.mpris.panelBodyPixelSize
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: rootMprisPanel.theme.modules.bar.mpris.controlSpacing

                MprisControlButton {
                    theme: rootMprisPanel.theme
                    icon: ""
                    enabled: rootMprisPanel.service.canGoPrevious
                    onTriggered: rootMprisPanel.service.previous()
                }

                MprisControlButton {
                    theme: rootMprisPanel.theme
                    icon: rootMprisPanel.service.toggleActionIcon
                    enabled: rootMprisPanel.service.canTogglePlaying
                    onTriggered: rootMprisPanel.service.togglePlaying()
                }

                MprisControlButton {
                    theme: rootMprisPanel.theme
                    icon: ""
                    enabled: rootMprisPanel.service.canGoNext
                    onTriggered: rootMprisPanel.service.next()
                }

                MprisControlButton {
                    theme: rootMprisPanel.theme
                    icon: ""
                    enabled: rootMprisPanel.service.canStop
                    onTriggered: rootMprisPanel.service.stop()
                }
            }
        }
    }
}
