import QtQuick

// Small rounded label. Clickable when something listens to `clicked`;
// `hint` shows the keyboard shortcut dimmed on the right.
Rectangle {
    id: rootPlacesChip

    required property QtObject pt
    property string text: ""
    property string hint: ""
    property bool accent: false
    property bool mono: false
    property string fontFamily: ""
    property color textColor: accent ? pt.accentColor : pt.primaryTextColor

    signal clicked

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 28
    radius: height / 2
    color: mouse.containsMouse ? pt.hoveredRowColor : (accent ? pt.selectedRowColor : pt.chipColor)
    border.width: accent ? 1 : 0
    border.color: pt.selectedBorderColor

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 560)
            text: rootPlacesChip.text
            color: rootPlacesChip.textColor
            font.family: rootPlacesChip.mono ? rootPlacesChip.pt.monoFontFamily : rootPlacesChip.fontFamily
            font.pixelSize: rootPlacesChip.pt.metaPixelSize + 1
            elide: Text.ElideRight
        }

        Text {
            visible: rootPlacesChip.hint.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: rootPlacesChip.hint
            color: rootPlacesChip.pt.secondaryTextColor
            font.family: rootPlacesChip.pt.monoFontFamily
            font.pixelSize: rootPlacesChip.pt.metaPixelSize
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: rootPlacesChip.clicked()
    }
}
