import QtQuick

// One colour of a combo: the band filled with it, its name in a big serif
// and the hex in a thin box, both in `ink` (another colour of the combo).
Rectangle {
    id: rootPrismBand

    required property QtObject pt
    required property string hex
    required property string name
    required property color ink
    property int titlePixelSize: 54
    property bool selected: false
    property bool favorite: false
    property bool interactive: true
    property string iconFont: ""
    // Set both to make the band draggable onto the sidebar (PrismPanel's
    // dragPress / dragMove / dragRelease / consumeDragClick).
    property var dragGhost: null
    property var dragHost: null

    signal clicked
    signal doubleClicked

    // Qt reads 8-digit hex as #aarrggbb; hex is #rrggbbaa.
    color: hex.length === 9 ? "#" + hex.slice(7, 9) + hex.slice(1, 7) : hex

    Column {
        anchors.centerIn: parent
        width: parent.width - 16
        spacing: Math.max(4, rootPrismBand.titlePixelSize / 5)

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: rootPrismBand.name
            color: rootPrismBand.ink
            font.family: rootPrismBand.pt.bandFontFamily
            font.pixelSize: Math.min(rootPrismBand.titlePixelSize, rootPrismBand.height * 0.4)
            elide: Text.ElideRight
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: hexText.implicitWidth + 12
            height: hexText.implicitHeight + 4
            color: "transparent"
            border.width: 1
            border.color: rootPrismBand.ink

            Text {
                id: hexText

                anchors.centerIn: parent
                text: rootPrismBand.hex.toUpperCase()
                color: rootPrismBand.ink
                font.pixelSize: Math.max(9, Math.min(rootPrismBand.pt.bodyPixelSize, rootPrismBand.titlePixelSize / 3))
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        visible: rootPrismBand.selected
        color: "transparent"
        radius: 8
        border.width: 2
        border.color: rootPrismBand.ink
    }

    Text {
        anchors {
            right: parent.right
            top: parent.top
            margins: 14
        }
        visible: rootPrismBand.favorite
        text: "󰓎"
        color: rootPrismBand.ink
        font.family: rootPrismBand.iconFont
        font.pixelSize: 16
    }

    MouseArea {
        id: bandMouse

        readonly property bool draggable: rootPrismBand.dragGhost !== null && rootPrismBand.dragHost !== null

        anchors.fill: parent
        enabled: rootPrismBand.interactive
        cursorShape: Qt.PointingHandCursor
        drag.target: draggable ? rootPrismBand.dragGhost : null
        drag.threshold: 10
        preventStealing: draggable

        onPressed: mouse => {
            if (draggable)
                rootPrismBand.dragHost.dragPress(bandMouse, mouse, rootPrismBand.hex, rootPrismBand.name);
        }
        onPositionChanged: {
            if (draggable)
                rootPrismBand.dragHost.dragMove(bandMouse);
        }
        onReleased: {
            if (draggable)
                rootPrismBand.dragHost.dragRelease();
        }
        onClicked: {
            if (draggable && rootPrismBand.dragHost.consumeDragClick())
                return;
            rootPrismBand.clicked();
        }
        onDoubleClicked: rootPrismBand.doubleClicked()
    }
}
