import QtQuick

Rectangle {
    id: rootTimerActionButton

    required property QtObject theme
    property string label: ""
    property bool danger: false

    signal clicked

    implicitHeight: rootTimerActionButton.theme.modules.timer.buttonHeight
    radius: 7
    color: danger ? rootTimerActionButton.theme.modules.timer.dangerColor : rootTimerActionButton.theme.modules.timer.actionColor
    border.width: danger ? 1 : 0
    border.color: rootTimerActionButton.theme.modules.timer.dangerBorderColor

    Text {
        anchors.centerIn: parent
        text: rootTimerActionButton.label
        color: danger ? rootTimerActionButton.theme.modules.timer.primaryTextColor : rootTimerActionButton.theme.modules.timer.actionTextColor
        font.pixelSize: rootTimerActionButton.theme.modules.timer.bodyPixelSize
        font.weight: Font.DemiBold
    }

    MouseArea {
        anchors.fill: parent
        enabled: rootTimerActionButton.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: rootTimerActionButton.clicked()
    }
}
