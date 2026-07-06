import QtQuick

Rectangle {
    id: rootNetworkAction

    required property QtObject theme
    property string label
    property bool enabled: true

    signal triggered

    implicitWidth: Math.max(actionLabel.implicitWidth, 80) + theme.modules.bar.network.actionPadding * 2
    implicitHeight: theme.modules.bar.network.actionHeight
    radius: theme.modules.bar.network.actionRadius
    color: actionTapHandler.pressed ? theme.modules.bar.network.rowHoverBackgroundColor : theme.modules.bar.network.actionBackgroundColor
    opacity: enabled ? 1 : 0.4

    Text {
        id: actionLabel

        anchors.centerIn: parent
        text: rootNetworkAction.label
        color: rootNetworkAction.theme.modules.bar.network.actionTextColor
        font.pixelSize: rootNetworkAction.theme.modules.bar.network.bodyPixelSize
        font.weight: Font.DemiBold
    }

    TapHandler {
        id: actionTapHandler

        enabled: rootNetworkAction.enabled
        onTapped: rootNetworkAction.triggered()
    }
}
