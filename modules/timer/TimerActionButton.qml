import QtQuick

Rectangle {
    id: rootTimerActionButton

    required property QtObject theme
    property string label: ""
    property bool danger: false
    readonly property bool controlActiveFocus: activeFocus

    signal clicked

    activeFocusOnTab: true
    implicitHeight: rootTimerActionButton.theme.modules.timer.buttonHeight
    radius: 7
    color: danger ? rootTimerActionButton.theme.modules.timer.dangerColor : rootTimerActionButton.theme.modules.timer.actionColor
    border.width: danger || activeFocus ? 1 : 0
    border.color: activeFocus ? rootTimerActionButton.theme.modules.timer.focusBorderColor : rootTimerActionButton.theme.modules.timer.dangerBorderColor

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

    Keys.onPressed: event => {
        if (!rootTimerActionButton.enabled)
            return;

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            rootTimerActionButton.clicked();
            event.accepted = true;
        }
    }

    function focusControl() {
        forceActiveFocus();
    }
}
