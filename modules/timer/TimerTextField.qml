import QtQuick

Rectangle {
    id: rootTimerTextField

    required property QtObject theme
    property alias text: input.text
    property string placeholder: ""
    readonly property bool controlActiveFocus: input.activeFocus

    signal accepted

    implicitHeight: rootTimerTextField.theme.modules.timer.fieldHeight
    radius: 7
    color: rootTimerTextField.theme.modules.timer.fieldColor
    border.width: 1
    border.color: input.activeFocus ? rootTimerTextField.theme.modules.timer.focusBorderColor : rootTimerTextField.theme.modules.timer.fieldBorderColor

    Text {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 10
            rightMargin: 10
        }
        text: rootTimerTextField.placeholder
        visible: input.text.length === 0 && !input.activeFocus
        color: rootTimerTextField.theme.modules.timer.secondaryTextColor
        font.pixelSize: rootTimerTextField.theme.modules.timer.bodyPixelSize
        elide: Text.ElideRight
    }

    TextInput {
        id: input

        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        color: rootTimerTextField.theme.modules.timer.primaryTextColor
        selectionColor: rootTimerTextField.theme.modules.timer.activeBorderColor
        selectedTextColor: rootTimerTextField.theme.modules.timer.panelColor
        font.pixelSize: rootTimerTextField.theme.modules.timer.bodyPixelSize
        verticalAlignment: TextInput.AlignVCenter
        clip: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                rootTimerTextField.accepted();
                event.accepted = true;
            }
        }
    }

    function focusInput() {
        input.forceActiveFocus();
    }

    function focusControl() {
        focusInput();
    }
}
