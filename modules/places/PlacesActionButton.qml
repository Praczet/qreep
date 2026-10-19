import QtQuick

// Main action button (editor, cockpit, folder, terminal, ...). Bigger than a
// chip, with its shortcut in a small key cap: dimmed, but readable.
Rectangle {
    id: rootPlacesActionButton

    required property QtObject pt
    property string icon: ""
    property string label: ""
    property string hint: ""
    property bool selected: false
    property string iconFontFamily: ""

    signal clicked

    implicitWidth: row.implicitWidth + 2 * pt.actionPadding
    implicitHeight: pt.actionHeight
    radius: pt.actionRadius
    color: selected ? pt.selectedRowColor : (mouse.containsMouse ? pt.hoveredRowColor : pt.chipColor)
    border.width: 1
    border.color: selected ? pt.selectedBorderColor : (mouse.containsMouse ? pt.withAlpha(pt.selectedBorderColor, 0.45) : "transparent")

    Behavior on color {
        ColorAnimation {
            duration: 90
        }
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: rootPlacesActionButton.icon
            color: rootPlacesActionButton.selected ? rootPlacesActionButton.pt.accentColor : rootPlacesActionButton.pt.primaryTextColor
            font.family: rootPlacesActionButton.iconFontFamily
            font.pixelSize: rootPlacesActionButton.pt.actionIconPixelSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: rootPlacesActionButton.label
            color: rootPlacesActionButton.selected ? rootPlacesActionButton.pt.accentColor : rootPlacesActionButton.pt.primaryTextColor
            font.pixelSize: rootPlacesActionButton.pt.actionPixelSize
            font.bold: rootPlacesActionButton.selected
        }

        // Key cap: outlined, text at reduced opacity, so it reads as a hint.
        Rectangle {
            visible: rootPlacesActionButton.hint.length > 0
            anchors.verticalCenter: parent.verticalCenter
            width: hintText.implicitWidth + 12
            height: hintText.implicitHeight + 4
            radius: 5
            color: rootPlacesActionButton.pt.withAlpha(rootPlacesActionButton.pt.primaryTextColor, 0.06)
            border.width: 1
            border.color: rootPlacesActionButton.pt.withAlpha(rootPlacesActionButton.pt.primaryTextColor, 0.22)

            Text {
                id: hintText

                anchors.centerIn: parent
                text: rootPlacesActionButton.hint
                color: rootPlacesActionButton.pt.primaryTextColor
                opacity: 0.68
                font.family: rootPlacesActionButton.pt.monoFontFamily
                font.pixelSize: rootPlacesActionButton.pt.metaPixelSize + 1
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: rootPlacesActionButton.clicked()
    }
}
