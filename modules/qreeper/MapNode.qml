import QtQuick

// One room on the map. Click selects, drag moves (and pins) it, right-click unpins.
// Outdoor rooms are circles; rooms of any other map type (building, cave, sewer, ...) are
// rounded squares, so the inside of a building reads as inside at a glance. A room with an
// exit into another map that is not a compass door (gate, enter, portal) gets a second ring. A peek is a room
// of the neighbouring map shown faded just past its door. A room the player marked
// (`qreeper:mark-it`) gets a thick border and a tinted fill in the marked colour.
// The map's own pan handler never sees a drag that starts on a node (preventStealing).
Rectangle {
    id: rootMapNode

    required property QtObject theme
    required property var room
    property bool current: false
    property bool selected: false
    property bool pinned: false
    property bool gateway: false
    property bool peek: false
    readonly property bool hovered: nodeMouse.containsMouse
    signal clicked(var room)
    // `point` is in the parent's (the map view's) coordinates.
    signal dragMoved(var room, point point)
    signal dragFinished(var room)
    signal unpinRequested(var room)

    width: current ? theme.modules.qreeper.currentNodeSize : peek ? Math.round(theme.modules.qreeper.nodeSize * theme.modules.qreeper.peekScale) : theme.modules.qreeper.nodeSize
    height: width
    readonly property bool indoors: room.mapType !== "outdoor"
    radius: indoors ? width * theme.modules.qreeper.indoorNodeRadius : width / 2
    opacity: peek ? theme.modules.qreeper.peekOpacity : 1
    readonly property bool marked: room.marked === true
    color: current ? theme.modules.qreeper.currentColor : selected ? Qt.rgba(theme.modules.qreeper.accentColor.r, theme.modules.qreeper.accentColor.g, theme.modules.qreeper.accentColor.b, 0.28) : marked ? Qt.rgba(theme.modules.qreeper.markedColor.r, theme.modules.qreeper.markedColor.g, theme.modules.qreeper.markedColor.b, theme.modules.qreeper.markedFillAlpha) : theme.modules.qreeper.cardColor
    border.width: current || marked ? 3 : room.positionStatus === "inferred" ? 2 : 1
    border.color: current ? theme.modules.qreeper.primaryTextColor : marked ? theme.modules.qreeper.markedColor : room.positionStatus === "inferred" ? theme.modules.qreeper.irregularColor : theme.modules.qreeper.borderColor

    // Gateway ring: same shape as the node, a little larger, drawn behind it.
    Rectangle {
        visible: rootMapNode.gateway
        z: -1
        anchors.centerIn: parent
        width: parent.width + 2 * rootMapNode.theme.modules.qreeper.gatewayRingGap
        height: width
        radius: rootMapNode.indoors ? width * rootMapNode.theme.modules.qreeper.indoorNodeRadius : width / 2
        color: "transparent"
        border.width: 2
        border.color: rootMapNode.theme.modules.qreeper.accentColor
    }

    Text {
        anchors.centerIn: parent
        text: rootMapNode.room.id
        color: rootMapNode.current ? rootMapNode.theme.modules.qreeper.mapColor : rootMapNode.theme.modules.qreeper.primaryTextColor
        font.pixelSize: rootMapNode.theme.modules.qreeper.metaPixelSize
        font.weight: rootMapNode.current ? Font.Bold : Font.DemiBold
    }

    Rectangle {
        visible: rootMapNode.room.notes.length > 0
        width: 8
        height: 8
        radius: 4
        anchors.right: parent.right
        anchors.top: parent.top
        color: rootMapNode.theme.modules.qreeper.noteColor
        border.width: 1
        border.color: rootMapNode.theme.modules.qreeper.mapColor
    }

    // Pinned marker: a small square, bottom-left, so it never collides with the note dot.
    Rectangle {
        visible: rootMapNode.pinned
        width: 7
        height: 7
        radius: 1
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        color: rootMapNode.theme.modules.qreeper.accentColor
        border.width: 1
        border.color: rootMapNode.theme.modules.qreeper.mapColor
    }

    MouseArea {
        id: nodeMouse

        property point pressPoint: Qt.point(0, 0)
        property bool dragging: false

        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        onPressed: mouse => {
            pressPoint = Qt.point(mouse.x, mouse.y);
            dragging = false;
        }
        onPositionChanged: mouse => {
            if (!pressed || !(pressedButtons & Qt.LeftButton))
                return;

            // A few pixels of slack so a click with a shaky hand is still a click.
            if (!dragging && Math.abs(mouse.x - pressPoint.x) + Math.abs(mouse.y - pressPoint.y) > 4)
                dragging = true;

            if (dragging)
                rootMapNode.dragMoved(rootMapNode.room, mapToItem(rootMapNode.parent, mouse.x, mouse.y));
        }
        onReleased: mouse => {
            if (mouse.button === Qt.RightButton) {
                rootMapNode.unpinRequested(rootMapNode.room);
            } else if (dragging) {
                rootMapNode.dragFinished(rootMapNode.room);
            } else {
                rootMapNode.clicked(rootMapNode.room);
            }

            dragging = false;
        }
    }
}
