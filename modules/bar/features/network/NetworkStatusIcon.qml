import QtQuick

Item {
    id: rootNetworkStatusIcon

    required property QtObject theme
    property string iconName
    property bool active: false

    width: theme.modules.bar.network.buttonIconPixelSize
    height: theme.modules.bar.network.buttonIconPixelSize
    opacity: active ? theme.modules.bar.network.activeOpacity : theme.modules.bar.network.inactiveOpacity

    Text {
        anchors.centerIn: parent
        text: rootNetworkStatusIcon.iconName
        color: rootNetworkStatusIcon.active ? rootNetworkStatusIcon.theme.modules.bar.network.activeColor : rootNetworkStatusIcon.theme.modules.bar.network.inactiveColor
        font.family: rootNetworkStatusIcon.theme.iconFontFamily
        font.pixelSize: rootNetworkStatusIcon.theme.modules.bar.network.buttonIconPixelSize
        lineHeight: 1
    }

    Behavior on opacity {
        NumberAnimation {
            duration: rootNetworkStatusIcon.theme.animationFastDuration
        }
    }
}
