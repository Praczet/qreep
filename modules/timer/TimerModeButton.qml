import QtQuick

Rectangle {
    id: rootTimerModeButton

    required property QtObject theme
    property string label: ""
    property bool active: false

    signal clicked

    implicitHeight: rootTimerModeButton.theme.modules.timer.buttonHeight
    radius: 7
    color: active ? rootTimerModeButton.theme.modules.timer.activeColor : rootTimerModeButton.theme.modules.timer.fieldColor
    border.width: 1
    border.color: active ? rootTimerModeButton.theme.modules.timer.activeBorderColor : rootTimerModeButton.theme.modules.timer.fieldBorderColor

    Text {
        anchors.centerIn: parent
        text: rootTimerModeButton.label
        color: rootTimerModeButton.theme.modules.timer.primaryTextColor
        font.pixelSize: rootTimerModeButton.theme.modules.timer.bodyPixelSize
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: rootTimerModeButton.clicked()
    }
}
