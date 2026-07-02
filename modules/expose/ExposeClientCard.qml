import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Rectangle {
    id: rootExposeClientCard

    required property QtObject theme
    required property var client
    property bool selected: false
    property bool compact: false
    readonly property var previewSource: client.previewSource || null
    readonly property bool hasLivePreview: previewSource !== null
    readonly property string thumbPath: String(client.thumbPath || "")

    signal selectedRequested(var card)
    signal activated(var client)

    width: compact ? theme.modules.expose.miniCardWidth : theme.modules.expose.currentCardWidth
    height: compact ? theme.modules.expose.miniCardHeight : theme.modules.expose.currentCardHeight
    radius: theme.modules.expose.cardRadius
    color: cardHover.hovered || selected ? theme.modules.expose.cardHoverColor : theme.modules.expose.cardColor
    border.width: selected ? theme.modules.expose.selectedBorderWidth : theme.modules.expose.borderWidth
    border.color: selected ? theme.modules.expose.selectedBorderColor : theme.modules.expose.borderColor
    opacity: selected || !compact ? 1 : theme.modules.expose.inactiveCardOpacity
    scale: selected ? theme.modules.expose.selectedScale : 1
    clip: true

    Behavior on color {
        ColorAnimation {
            duration: rootExposeClientCard.theme.modules.expose.animationDuration
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: rootExposeClientCard.theme.modules.expose.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        id: cardHover

        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: {
            if (hovered)
                rootExposeClientCard.selectedRequested(rootExposeClientCard);
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: rootExposeClientCard.activated(rootExposeClientCard.client)
    }

    Rectangle {
        id: preview

        visible: !rootExposeClientCard.compact
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        height: rootExposeClientCard.theme.modules.expose.currentCardPreviewHeight
        radius: rootExposeClientCard.theme.modules.expose.previewRadius
        color: rootExposeClientCard.theme.modules.expose.previewColor
        border.width: 1
        border.color: Qt.rgba(rootExposeClientCard.theme.modules.expose.borderColor.r, rootExposeClientCard.theme.modules.expose.borderColor.g, rootExposeClientCard.theme.modules.expose.borderColor.b, 0.42)
        clip: true

        ScreencopyView {
            anchors.fill: parent
            captureSource: rootExposeClientCard.previewSource
            live: rootExposeClientCard.hasLivePreview && rootExposeClientCard.visible
            paintCursor: false
            constraintSize: Qt.size(width, height)
            visible: rootExposeClientCard.hasLivePreview
        }

        Image {
            anchors.fill: parent
            source: rootExposeClientCard.thumbPath.length > 0 ? "file://" + rootExposeClientCard.thumbPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            visible: !rootExposeClientCard.hasLivePreview && rootExposeClientCard.thumbPath.length > 0
        }

        Text {
            anchors.centerIn: parent
            visible: !rootExposeClientCard.hasLivePreview && rootExposeClientCard.thumbPath.length === 0
            text: rootExposeClientCard.client.floating ? "󰹙" : "󰖲"
            color: rootExposeClientCard.theme.modules.expose.secondaryTextColor
            font.family: rootExposeClientCard.theme.iconFontFamily
            font.pixelSize: 44
            opacity: 0.52
        }
    }

    Row {
        id: metaRow

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: compact ? 10 : 14
        }
        height: compact ? parent.height - 20 : 54
        spacing: compact ? 8 : 12

        IconImage {
            width: compact ? rootExposeClientCard.theme.modules.expose.miniIconSize : rootExposeClientCard.theme.modules.expose.iconSize
            height: width
            anchors.verticalCenter: parent.verticalCenter
            source: Quickshell.iconPath(String(rootExposeClientCard.client.iconName || ""), "application-x-executable-symbolic")
        }

        Column {
            width: parent.width - parent.spacing - (compact ? rootExposeClientCard.theme.modules.expose.miniIconSize : rootExposeClientCard.theme.modules.expose.iconSize)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: rootExposeClientCard.client.title.length > 0 ? rootExposeClientCard.client.title : rootExposeClientCard.client.appLabel
                color: rootExposeClientCard.theme.modules.expose.primaryTextColor
                font.pixelSize: compact ? rootExposeClientCard.theme.modules.expose.subtitlePixelSize : rootExposeClientCard.theme.modules.expose.titlePixelSize
                font.weight: compact ? Font.Normal : Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                visible: !rootExposeClientCard.compact
                width: parent.width
                text: rootExposeClientCard.client.className
                color: rootExposeClientCard.theme.modules.expose.secondaryTextColor
                font.pixelSize: rootExposeClientCard.theme.modules.expose.subtitlePixelSize
                elide: Text.ElideRight
            }
        }
    }
}
