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
        rect.y: rootMprisPanel.anchorItem.height + rootMprisPanel.theme.mpris.panelTopOffset
    }

    implicitWidth: rootMprisPanel.theme.mpris.panelWidth
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
        implicitHeight: playerLayout.implicitHeight + rootMprisPanel.theme.mpris.panelPadding * 2
        radius: rootMprisPanel.theme.mpris.panelRadius
        color: rootMprisPanel.theme.calendarBackground
        border.width: rootMprisPanel.theme.tooltip.borderWidth
        border.color: rootMprisPanel.theme.moduleHoverBackground

        Column {
            id: playerLayout

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: rootMprisPanel.theme.mpris.panelPadding
            }
            spacing: rootMprisPanel.theme.mpris.panelRowSpacing

            Row {
                width: parent.width
                spacing: rootMprisPanel.theme.mpris.panelRowSpacing

                Rectangle {
                    width: rootMprisPanel.theme.mpris.panelArtSize
                    height: width
                    radius: 8
                    color: rootMprisPanel.theme.moduleHoverBackground
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
                        color: rootMprisPanel.theme.secondaryText
                        font.family: rootMprisPanel.theme.iconFontFamily
                        font.pixelSize: 46
                    }
                }

                Column {
                    width: parent.width - rootMprisPanel.theme.mpris.panelArtSize - parent.spacing
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        text: rootMprisPanel.service.title
                        color: rootMprisPanel.theme.calendarHeaderText
                        font.pixelSize: rootMprisPanel.theme.mpris.panelTitlePixelSize
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        text: rootMprisPanel.service.artists
                        color: rootMprisPanel.theme.calendarDayText
                        font.pixelSize: rootMprisPanel.theme.mpris.panelBodyPixelSize
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        text: rootMprisPanel.service.album
                        color: rootMprisPanel.theme.secondaryText
                        font.pixelSize: rootMprisPanel.theme.mpris.panelBodyPixelSize
                        wrapMode: Text.Wrap
                    }

                    Text {
                        visible: rootMprisPanel.service.durationText.length > 0
                        width: parent.width
                        text: rootMprisPanel.service.durationText
                        color: rootMprisPanel.theme.secondaryText
                        font.pixelSize: rootMprisPanel.theme.mpris.panelBodyPixelSize
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: rootMprisPanel.theme.mpris.controlSpacing

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
