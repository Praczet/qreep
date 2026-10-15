import QtQuick

// Action chooser: "Open with" for notes, actions for screenshots and files.
// Rows are numbered; the first option is the default.
Rectangle {
    id: rootKipChooser

    required property QtObject kipTheme
    required property string iconFontFamily
    required property string title
    required property var options
    property int selectedIndex: 0

    signal picked(int index)

    height: chooserColumn.implicitHeight + 16
    radius: rootKipChooser.kipTheme.rowRadius
    color: rootKipChooser.kipTheme.inputColor
    border.width: 1
    border.color: rootKipChooser.kipTheme.focusBorderColor

    Column {
        id: chooserColumn

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 8
        }
        spacing: 2

        Text {
            width: parent.width
            text: rootKipChooser.title
            color: rootKipChooser.kipTheme.secondaryTextColor
            font.pixelSize: rootKipChooser.kipTheme.metaPixelSize + 1
            elide: Text.ElideMiddle
            bottomPadding: 4
        }

        Repeater {
            model: rootKipChooser.options

            Rectangle {
                id: openerRow

                required property var modelData
                required property int index

                readonly property bool selected: index === rootKipChooser.selectedIndex

                width: parent.width
                height: rootKipChooser.kipTheme.commandRowHeight - 6
                radius: rootKipChooser.kipTheme.rowRadius
                color: selected ? rootKipChooser.kipTheme.selectedRowColor : (openerMouse.containsMouse ? rootKipChooser.kipTheme.hoveredRowColor : "transparent")

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 8
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        text: openerRow.modelData.icon
                        color: rootKipChooser.kipTheme.accentColor
                        font.family: rootKipChooser.iconFontFamily
                        font.pixelSize: rootKipChooser.kipTheme.iconPixelSize - 2
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 90
                        text: (openerRow.index + 1) + "  " + openerRow.modelData.label
                        color: rootKipChooser.kipTheme.primaryTextColor
                        font.pixelSize: rootKipChooser.kipTheme.bodyPixelSize
                        font.bold: openerRow.selected
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: openerRow.modelData.hint
                        color: rootKipChooser.kipTheme.secondaryTextColor
                        font.pixelSize: rootKipChooser.kipTheme.metaPixelSize + 1
                    }
                }

                MouseArea {
                    id: openerMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        rootKipChooser.picked(openerRow.index);
                    }
                }
            }
        }
    }
}
