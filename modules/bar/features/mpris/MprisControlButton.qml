import QtQuick

Rectangle {
    id: rootMprisControlButton

    required property QtObject theme
    property string icon

    signal triggered

    width: theme.modules.bar.mpris.controlButtonSize
    height: width
    radius: width / 2
    color: controlHover.hovered && enabled ? theme.modules.bar.moduleBackgroundColor : "transparent"
    opacity: enabled ? 1 : theme.modules.bar.mpris.disabledControlOpacity

    Text {
        anchors.centerIn: parent
        text: rootMprisControlButton.icon
        color: rootMprisControlButton.theme.modules.bar.primaryTextColor
        font.family: rootMprisControlButton.theme.iconFontFamily
        font.pixelSize: rootMprisControlButton.theme.modules.bar.mpris.controlIconPixelSize
    }

    HoverHandler {
        id: controlHover

        enabled: rootMprisControlButton.enabled
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: rootMprisControlButton.enabled
        onTapped: rootMprisControlButton.triggered()
    }

    Behavior on color {
        ColorAnimation {
            duration: rootMprisControlButton.theme.animationFastDuration
        }
    }
}
