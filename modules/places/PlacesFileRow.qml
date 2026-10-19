import QtQuick

// A clickable file line: short tag (git status, age, ...) and the path.
// Click (or Enter while `selected`) opens the "Open with" chooser.
Rectangle {
    id: rootPlacesFileRow

    required property QtObject pt
    property string tag: ""
    property color tagColor: pt.secondaryTextColor
    property string path: ""
    property string trailing: ""
    property bool selected: false

    signal clicked

    width: parent ? parent.width : 0
    height: 24
    radius: 6
    color: selected ? pt.selectedRowColor : (mouse.containsMouse ? pt.hoveredRowColor : "transparent")
    border.width: selected ? 1 : 0
    border.color: pt.selectedBorderColor

    Text {
        id: tagText

        anchors {
            left: parent.left
            leftMargin: 6
            verticalCenter: parent.verticalCenter
        }
        width: 22
        text: rootPlacesFileRow.tag
        color: rootPlacesFileRow.tagColor
        font.family: rootPlacesFileRow.pt.monoFontFamily
        font.pixelSize: rootPlacesFileRow.pt.metaPixelSize
        font.bold: true
    }

    Text {
        anchors {
            left: tagText.right
            leftMargin: 6
            right: trailingText.left
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        text: rootPlacesFileRow.path
        color: rootPlacesFileRow.pt.primaryTextColor
        font.family: rootPlacesFileRow.pt.monoFontFamily
        font.pixelSize: rootPlacesFileRow.pt.metaPixelSize + 1
        elide: Text.ElideMiddle
    }

    Text {
        id: trailingText

        anchors {
            right: parent.right
            rightMargin: 6
            verticalCenter: parent.verticalCenter
        }
        text: rootPlacesFileRow.trailing
        color: rootPlacesFileRow.pt.secondaryTextColor
        font.family: rootPlacesFileRow.pt.monoFontFamily
        font.pixelSize: rootPlacesFileRow.pt.metaPixelSize
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: rootPlacesFileRow.clicked()
    }
}
