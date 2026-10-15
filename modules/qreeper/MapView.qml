import QtQuick

Item {
    id: rootMapView

    required property QtObject theme
    required property QtObject service
    // QreeperLayout: positions for every room, shared with the other map view.
    required property QtObject layout
    property real cameraX: 0
    property real cameraY: 0
    property real zoom: 1
    property int level: 0
    // Only rooms of this map are drawn; null draws every map. Exits to other maps become stubs.
    property var mapId: null
    // Rooms of other maps just past a compass door of this map, drawn small and faded a short
    // way beyond the door (peekDistance cells, so they never sit on the street room that the
    // map grid puts there): id (string) -> { from, dx, dy }. Named exits stay stubs.
    readonly property var peeks: computePeeks(service.exits, mapId, level)
    property var selectedRoomId: null
    property bool interactive: true
    property bool userPanActive: false
    // Keep the camera on the current room, every frame, while the layout settles around it.
    // Pan stops it (userPanActive); zoom does not.
    property bool follow: false
    property bool hasCentered: false
    property var hoveredRoomId: null
    readonly property real spacing: theme.modules.qreeper.gridSpacing * zoom

    signal roomSelected(var room)
    signal manuallyPanned

    clip: true

    Rectangle {
        anchors.fill: parent
        color: rootMapView.theme.modules.qreeper.mapColor
    }

    Canvas {
        id: edgeCanvas

        anchors.fill: parent

        // Every exit is drawn from its own room, with a direction label near that room:
        //   regular    straight solid line; arrowhead when the way back is not also regular
        //   irregular  dashed curve leaving in the *recorded* direction, bending to the target
        //   named      accent curve to a nearby target
        //   offmap     labelled stub ("enter → #8") when the target is unplaced, on another
        //              level, or too far for a sensible curve
        //   unknown    short dotted stub, never travelled
        //   loop       short dotted stub marked ↺, an exit back into its own room
        // An exit into another map's entrance also gets a marker on its own room, just off the
        // node in the exit's direction: rounded square into a building/cave/..., ring for a
        // portal, diamond into another outdoor map.
        onPaint: {
            const context = getContext("2d");
            const qreeperTheme = rootMapView.theme.modules.qreeper;
            const exits = rootMapView.service.exits;
            const labels = [];
            const markers = [];
            const regularPairs = {};
            const namedSlots = {};

            context.reset();
            context.clearRect(0, 0, width, height);
            context.lineWidth = 2;

            // Judge every exit by what is on screen, not by the producer's grid: the layout moves.
            const shapes = [];

            for (let index = 0; index < exits.length; index++) {
                const shape = rootMapView.edgeShape(exits[index]);
                shapes.push(shape);

                if (shape === "regular")
                    regularPairs[exits[index].from + ">" + exits[index].to] = true;
            }

            for (let index = 0; index < exits.length; index++) {
                const edge = exits[index];
                const fromRoom = rootMapView.service.roomForId(edge.from);

                if (!rootMapView.roomVisible(fromRoom))
                    continue;

                // A peeked room shows only its way back into this map: no stubs, no markers.
                if (rootMapView.isPeek(fromRoom)) {
                    const back = edge.to === null ? null : rootMapView.service.roomForId(edge.to);
                    if (!back || back.mapId !== rootMapView.mapId)
                        continue;
                }

                const start = rootMapView.roomPoint(fromRoom);
                const shortName = rootMapView.directionLabel(edge.direction);
                let slot = 0;

                if (!rootMapView.directionOffset(edge.direction)) {
                    slot = namedSlots[edge.from] || 0;
                    namedSlots[edge.from] = slot + 1;
                }

                const marker = rootMapView.service.entranceMarker(edge);

                if (marker)
                    markers.push({ kind: marker, point: rootMapView.markerPoint(start, edge.direction, slot) });

                if (edge.to === null) {
                    const stub = rootMapView.stubPoint(start, edge.direction, slot, 0.42);
                    context.beginPath();
                    context.setLineDash([3, 4]);
                    context.strokeStyle = qreeperTheme.unknownColor;
                    context.moveTo(start.x, start.y);
                    context.lineTo(stub.x, stub.y);
                    context.stroke();
                    labels.push({ point: rootMapView.stubPoint(start, edge.direction, slot, 0.58), text: shortName + " ?", color: qreeperTheme.unknownColor });
                    continue;
                }

                // An exit that loops back into its own room: a short stub marked with ↺.
                if (edge.to === edge.from) {
                    const loopTip = rootMapView.stubPoint(start, edge.direction, slot, 0.42);
                    context.beginPath();
                    context.setLineDash([2, 3]);
                    context.strokeStyle = qreeperTheme.secondaryTextColor;
                    context.moveTo(start.x, start.y);
                    context.lineTo(loopTip.x, loopTip.y);
                    context.stroke();
                    labels.push({ point: rootMapView.stubPoint(start, edge.direction, slot, 0.58), text: shortName + " ↺", color: qreeperTheme.secondaryTextColor });
                    continue;
                }

                const toRoom = rootMapView.service.roomForId(edge.to);

                const end = rootMapView.roomVisible(toRoom) ? rootMapView.roomPoint(toRoom) : null;
                const far = end && !rootMapView.directionOffset(edge.direction)
                    && Math.hypot(end.x - start.x, end.y - start.y) > rootMapView.spacing * qreeperTheme.namedCurveMaxCells;

                if (!end || far) {
                    const tip = rootMapView.stubPoint(start, edge.direction, slot, 0.62);
                    context.beginPath();
                    context.setLineDash([6, 4]);
                    context.strokeStyle = qreeperTheme.accentColor;
                    context.moveTo(start.x, start.y);
                    context.lineTo(tip.x, tip.y);
                    context.stroke();
                    rootMapView.drawArrowhead(context, start, tip, qreeperTheme.accentColor, 0);
                    labels.push({ point: rootMapView.stubPoint(start, edge.direction, slot, 0.86), text: shortName + " → " + rootMapView.stubTarget(fromRoom, toRoom, edge.to), color: qreeperTheme.accentColor });
                    continue;
                }

                if (shapes[index] === "regular") {
                    // Rule one: leave in the recorded direction, then follow the path. With an
                    // organic layout the target is rarely exactly there, so this is a gentle curve.
                    const leaving = rootMapView.curveControl(start, end, edge.direction, false);
                    const twoWay = !!regularPairs[edge.to + ">" + edge.from];

                    // A two-way pair is one corridor: draw its line once (from the lower id),
                    // keep both direction labels.
                    if (!twoWay || edge.from < edge.to) {
                        context.beginPath();
                        context.setLineDash([]);
                        context.strokeStyle = qreeperTheme.borderColor;
                        context.moveTo(start.x, start.y);
                        context.quadraticCurveTo(leaving.x, leaving.y, end.x, end.y);
                        context.stroke();
                    }

                    if (!twoWay)
                        rootMapView.drawArrowhead(context, leaving, end, qreeperTheme.borderColor);

                    labels.push({ point: rootMapView.curvePoint(start, leaving, end, qreeperTheme.edgeLabelPosition), text: shortName, color: qreeperTheme.secondaryTextColor });
                    continue;
                }

                const control = rootMapView.curveControl(start, end, edge.direction, true);
                const color = shapes[index] === "named" ? qreeperTheme.accentColor : qreeperTheme.irregularColor;

                context.beginPath();
                context.setLineDash([6, 5]);
                context.strokeStyle = color;
                context.moveTo(start.x, start.y);
                context.quadraticCurveTo(control.x, control.y, end.x, end.y);
                context.stroke();

                rootMapView.drawArrowhead(context, control, end, color);
                labels.push({ point: rootMapView.curvePoint(start, control, end, qreeperTheme.edgeLabelPosition), text: shortName, color: color });
            }

            for (let index = 0; index < markers.length; index++)
                rootMapView.drawEntranceMarker(context, markers[index]);

            // Labels last, on a small backing so they stay readable over crossing lines.
            if (rootMapView.spacing < qreeperTheme.edgeLabelMinSpacing)
                return;

            context.setLineDash([]);
            context.font = "600 " + qreeperTheme.edgeLabelPixelSize + "px sans-serif";
            context.textAlign = "center";
            context.textBaseline = "middle";

            for (let index = 0; index < labels.length; index++) {
                const label = labels[index];
                const textWidth = context.measureText(label.text).width;
                const boxHeight = qreeperTheme.edgeLabelPixelSize + 4;

                context.fillStyle = qreeperTheme.mapColor;
                context.fillRect(label.point.x - textWidth / 2 - 3, label.point.y - boxHeight / 2, textWidth + 6, boxHeight);
                context.fillStyle = label.color;
                context.fillText(label.text, label.point.x, label.point.y);
            }
        }
    }

    Repeater {
        model: rootMapView.service.rooms

        MapNode {
            required property var modelData

            theme: rootMapView.theme
            room: modelData
            current: modelData.id === rootMapView.service.currentRoomId
            selected: modelData.id === rootMapView.selectedRoomId
            visible: rootMapView.roomVisible(modelData)
            x: rootMapView.roomPoint(modelData).x - width / 2
            y: rootMapView.roomPoint(modelData).y - height / 2

            pinned: rootMapView.layout.isPinned(modelData.id)
            peek: rootMapView.isPeek(modelData)
            gateway: !peek && rootMapView.service.isGateway(modelData.id)

            onClicked: room => {
                rootMapView.selectedRoomId = room.id;
                rootMapView.roomSelected(room);
            }
            // Dragging a room pins it where it is dropped; right-click releases the pin.
            onDragMoved: (room, point) => rootMapView.layout.drag(room.id, rootMapView.cameraX + (point.x - rootMapView.width / 2) / rootMapView.spacing, rootMapView.cameraY + (point.y - rootMapView.height / 2) / rootMapView.spacing)
            onDragFinished: room => rootMapView.layout.endDrag(room.id)
            onUnpinRequested: room => rootMapView.layout.unpin(room.id)
            onHoveredChanged: {
                if (hovered)
                    rootMapView.hoveredRoomId = modelData.id;
                else if (rootMapView.hoveredRoomId === modelData.id)
                    rootMapView.hoveredRoomId = null;
            }
        }
    }

    // Hover card: name, id/area/level, and notes. It follows the node when the camera moves and
    // flips to whichever side has room, so it never leaves the map (and the minimap's input mask).
    Rectangle {
        id: hoverCard

        readonly property var room: rootMapView.service.roomForId(rootMapView.hoveredRoomId)
        readonly property point anchorPoint: room ? rootMapView.roomPoint(room) : Qt.point(0, 0)
        readonly property int gap: rootMapView.theme.modules.qreeper.currentNodeSize / 2 + 6
        readonly property int notesShown: 3

        visible: !!room && rootMapView.roomVisible(room)
        z: 10
        width: Math.min(rootMapView.theme.modules.qreeper.hoverCardWidth, rootMapView.width - 16)
        height: hoverLayout.implicitHeight + 16
        radius: 8
        color: rootMapView.theme.modules.qreeper.cardColor
        border.width: 1
        border.color: rootMapView.theme.modules.qreeper.borderColor
        x: {
            const right = anchorPoint.x + gap;
            const left = anchorPoint.x - gap - width;
            const preferred = right + width <= rootMapView.width - 8 ? right : left;
            return Math.max(8, Math.min(preferred, rootMapView.width - width - 8));
        }
        y: Math.max(8, Math.min(anchorPoint.y - height / 2, rootMapView.height - height - 8))

        Column {
            id: hoverLayout

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 3

            Text {
                width: parent.width
                text: hoverCard.room ? hoverCard.room.name : ""
                color: rootMapView.theme.modules.qreeper.primaryTextColor
                font.pixelSize: rootMapView.theme.modules.qreeper.bodyPixelSize
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }

            Text {
                width: parent.width
                text: hoverCard.room ? rootMapView.service.roomLocation(hoverCard.room) : ""
                color: rootMapView.theme.modules.qreeper.secondaryTextColor
                font.pixelSize: rootMapView.theme.modules.qreeper.metaPixelSize
                wrapMode: Text.Wrap
            }

            Repeater {
                model: hoverCard.room ? hoverCard.room.notes.slice(-hoverCard.notesShown) : []

                Text {
                    required property var modelData

                    width: hoverLayout.width
                    text: "• " + modelData.text
                    color: rootMapView.theme.modules.qreeper.noteColor
                    font.pixelSize: rootMapView.theme.modules.qreeper.metaPixelSize
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }

            Text {
                width: parent.width
                visible: !!hoverCard.room && hoverCard.room.notes.length > hoverCard.notesShown
                text: hoverCard.room ? "+" + (hoverCard.room.notes.length - hoverCard.notesShown) + " older notes in the Atlas" : ""
                color: rootMapView.theme.modules.qreeper.secondaryTextColor
                font.pixelSize: rootMapView.theme.modules.qreeper.metaPixelSize
            }
        }
    }

    Rectangle {
        id: unplacedCurrent

        visible: !!rootMapView.service.currentRoom && !rootMapView.layout.point(rootMapView.service.currentRoomId)
        anchors.centerIn: parent
        width: Math.min(260, parent.width - 32)
        height: unplacedLayout.implicitHeight + 28
        radius: rootMapView.theme.modules.qreeper.panelRadius
        color: rootMapView.theme.modules.qreeper.cardColor
        border.width: 2
        border.color: rootMapView.theme.modules.qreeper.irregularColor

        Column {
            id: unplacedLayout
            anchors.centerIn: parent
            width: parent.width - 28
            spacing: 6

            Text {
                width: parent.width
                text: "Unplaced current room · #" + (rootMapView.service.currentRoom ? rootMapView.service.currentRoom.id : "?")
                color: rootMapView.theme.modules.qreeper.irregularColor
                font.pixelSize: rootMapView.theme.modules.qreeper.metaPixelSize
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: rootMapView.service.currentRoom ? rootMapView.service.currentRoom.name : "Location unresolved"
                color: rootMapView.theme.modules.qreeper.primaryTextColor
                font.pixelSize: rootMapView.theme.modules.qreeper.titlePixelSize
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                visible: text.length > 0
                text: rootMapView.inboundLabel(rootMapView.service.currentRoomId)
                color: rootMapView.theme.modules.qreeper.primaryTextColor
                font.pixelSize: rootMapView.theme.modules.qreeper.bodyPixelSize
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: "The graph edge is real. The compass position is not known yet. No scenery has been invented."
                color: rootMapView.theme.modules.qreeper.secondaryTextColor
                font.pixelSize: rootMapView.theme.modules.qreeper.metaPixelSize
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    DragHandler {
        id: panHandler
        enabled: rootMapView.interactive
        target: null
        acceptedButtons: Qt.LeftButton
        property real startCameraX: 0
        property real startCameraY: 0

        onActiveChanged: {
            if (active) {
                cameraXAnimation.stop();
                cameraYAnimation.stop();
                startCameraX = rootMapView.cameraX;
                startCameraY = rootMapView.cameraY;
                rootMapView.userPanActive = true;
                rootMapView.manuallyPanned();
            }
        }
        onTranslationChanged: {
            if (!active)
                return;
            rootMapView.cameraX = startCameraX - translation.x / rootMapView.spacing;
            rootMapView.cameraY = startCameraY - translation.y / rootMapView.spacing;
        }
    }

    WheelHandler {
        enabled: rootMapView.interactive
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const factor = event.angleDelta.y > 0 ? 1.12 : 0.89;
            rootMapView.zoom = Math.max(rootMapView.theme.modules.qreeper.minimumZoom, Math.min(rootMapView.theme.modules.qreeper.maximumZoom, rootMapView.zoom * factor));
            // Zooming keeps the centre, so a following view keeps following.
            if (!rootMapView.follow) {
                rootMapView.userPanActive = true;
                rootMapView.manuallyPanned();
            }
            event.accepted = true;
        }
    }

    Timer {
        id: followTicker
        interval: 16
        repeat: true
        running: rootMapView.follow && !rootMapView.userPanActive && rootMapView.visible
        onTriggered: rootMapView.followStep()
    }

    NumberAnimation {
        id: cameraXAnimation
        target: rootMapView
        property: "cameraX"
        duration: rootMapView.theme.modules.qreeper.followDuration
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: cameraYAnimation
        target: rootMapView
        property: "cameraY"
        duration: rootMapView.theme.modules.qreeper.followDuration
        easing.type: Easing.OutCubic
    }

    Connections {
        target: rootMapView.service
        function onSnapshotApplied() {
            edgeCanvas.requestPaint();
            // A view opened before the first snapshot has nothing to center on yet.
            // Frame the first placed current room once; routine movement is the owner's business.
            if (!rootMapView.hasCentered)
                rootMapView.centerOnCurrent(false);
        }
    }
    Connections {
        target: rootMapView.layout
        function onRevisionChanged() {
            edgeCanvas.requestPaint();
            // Layout positions can arrive after the snapshot; frame the current room once.
            if (!rootMapView.hasCentered)
                rootMapView.centerOnCurrent(false);
        }
    }
    onCameraXChanged: edgeCanvas.requestPaint()
    onCameraYChanged: edgeCanvas.requestPaint()
    onZoomChanged: edgeCanvas.requestPaint()
    onLevelChanged: edgeCanvas.requestPaint()
    onMapIdChanged: edgeCanvas.requestPaint()
    onWidthChanged: edgeCanvas.requestPaint()
    onHeightChanged: edgeCanvas.requestPaint()

    function roomLevel(room) {
        if (!room)
            return null;
        if (room.level !== null)
            return room.level;
        return room.z;
    }

    // Where an off-map stub leads: another map by name, otherwise the room id.
    function stubTarget(fromRoom, toRoom, toId) {
        if (toRoom && toRoom.mapId !== null && toRoom.mapId !== fromRoom.mapId) {
            const map = service.mapForId(toRoom.mapId);
            if (map) {
                const limit = theme.modules.qreeper.stubMapNameLength;
                return map.name.length > limit ? map.name.slice(0, limit - 1) + "…" : map.name;
            }
        }
        return "#" + toId;
    }

    function roomVisible(room) {
        if (!room)
            return false;
        if (isPeek(room))
            return cellPoint(room.id) !== null;
        return layout.point(room.id) !== null && roomLevel(room) === level
            && (mapId === null || room.mapId === mapId);
    }

    function isPeek(room) {
        return !!room && mapId !== null && room.mapId !== mapId && !!peeks[String(room.id)];
    }

    function computePeeks(exits, viewMap, viewLevel) {
        const result = {};

        if (viewMap === null)
            return result;

        for (let index = 0; index < exits.length; index++) {
            const edge = exits[index];
            const offset = directionOffset(edge.direction);
            const from = service.roomForId(edge.from);
            const to = edge.to === null ? null : service.roomForId(edge.to);

            if (!offset || !from || !to || from.mapId !== viewMap || to.mapId === viewMap
                || roomLevel(from) !== viewLevel || result[String(to.id)])
                continue;

            const distance = theme.modules.qreeper.peekDistance / Math.hypot(offset[0], offset[1]);
            result[String(to.id)] = { from: from.id, dx: offset[0] * distance, dy: offset[1] * distance };
        }

        return result;
    }

    // Layout position in cells; a peeked room sits just past its door.
    function cellPoint(id) {
        const peek = mapId !== null ? peeks[String(id)] : null;
        const room = peek ? service.roomForId(id) : null;

        if (room && room.mapId !== mapId) {
            const anchor = layout.point(peek.from);
            return anchor ? { x: anchor.x + peek.dx, y: anchor.y + peek.dy } : null;
        }
        return layout.point(id);
    }

    function roomPoint(room) {
        const position = room ? cellPoint(room.id) : null;

        if (!position)
            return Qt.point(width / 2, height / 2);
        return Qt.point(width / 2 + (position.x - cameraX) * spacing, height / 2 + (position.y - cameraY) * spacing);
    }

    // How to draw an exit, from the current layout: "regular" when the target lies roughly in
    // the recorded direction (within layoutAgreeCos), "irregular" when it contradicts it,
    // "named" for exits without a compass direction. Up/down connect different levels and are
    // never drawn as lines. Called once per exit per paint, before any drawing.
    function edgeShape(edge) {
        const offset = directionOffset(edge.direction);

        if (!offset)
            return edge.direction === "up" || edge.direction === "down" ? edge.geometry : "named";

        const from = cellPoint(edge.from);
        const to = edge.to === null ? null : cellPoint(edge.to);

        if (!from || !to)
            return edge.geometry;

        const dx = to.x - from.x;
        const dy = to.y - from.y;
        const length = Math.hypot(dx, dy) * Math.hypot(offset[0], offset[1]);

        if (length < 0.0001)
            return "irregular";

        return (dx * offset[0] + dy * offset[1]) / length >= theme.modules.qreeper.layoutAgreeCos ? "regular" : "irregular";
    }

    // Screen-plane offset for a compass direction, or null for named exits and up/down.
    function directionOffset(direction) {
        const offsets = {
            north: [0, -1], northeast: [1, -1], east: [1, 0], southeast: [1, 1],
            south: [0, 1], southwest: [-1, 1], west: [-1, 0], northwest: [-1, -1]
        };
        return offsets[String(direction || "").toLowerCase()] || null;
    }

    // Short map label for an exit: compass and up/down abbreviated, named exits kept whole.
    function directionLabel(direction) {
        const abbreviations = {
            north: "n", northeast: "ne", east: "e", southeast: "se",
            south: "s", southwest: "sw", west: "w", northwest: "nw",
            up: "u", down: "d"
        };
        const name = String(direction || "?");
        return abbreviations[name.toLowerCase()] || name;
    }

    // Point `length` cells out from `start` for a stub. Compass exits use their own direction.
    // Up/down and named exits have none, so they take the in-between angles (22.5° off the
    // compass lines) in a fixed order, which keeps them off real compass edges and off each other.
    function stubPoint(start, direction, slot, length) {
        let offset = directionOffset(direction);

        if (!offset) {
            const name = String(direction || "").toLowerCase();
            const between = [[0.92, -0.38], [-0.92, -0.38], [0.92, 0.38], [-0.92, 0.38], [0.38, 0.92], [-0.38, -0.92]];

            if (name === "up")
                offset = [0.38, -0.92];
            else if (name === "down")
                offset = [-0.38, 0.92];
            else
                offset = between[(slot || 0) % between.length];
        } else {
            const norm = Math.hypot(offset[0], offset[1]);
            offset = [offset[0] / norm, offset[1] / norm];
        }

        return Qt.point(start.x + offset[0] * spacing * length, start.y + offset[1] * spacing * length);
    }

    function lerpPoint(start, end, t) {
        return Qt.point(start.x + (end.x - start.x) * t, start.y + (end.y - start.y) * t);
    }

    // Point at parameter t on the quadratic curve start -> control -> end.
    function curvePoint(start, control, end, t) {
        const u = 1 - t;
        return Qt.point(u * u * start.x + 2 * u * t * control.x + t * t * end.x, u * u * start.y + 2 * u * t * control.y + t * t * end.y);
    }

    // Control point for a non-regular edge. Compass exits pull the curve out along the
    // recorded direction; named exits bow to the right of travel so a pair of opposite
    // edges (`enter`/`out`) draws as two separate arcs instead of one line.
    // Compass exits also bow to the right of their recorded direction, more for longer edges.
    // Without the bow, an exit whose direction points straight at a far target (`72 east -> 73`
    // with two unrelated rooms in between) draws as a straight dashed line through those rooms
    // and reads as a corridor that does not exist. The bow also splits a pair of opposite
    // exits into two arcs.
    // `bowed` is for irregular exits only; regular ones just leave in their direction.
    function curveControl(start, end, direction, bowed) {
        const offset = directionOffset(direction);
        const distance = Math.hypot(end.x - start.x, end.y - start.y);

        if (offset) {
            const length = Math.hypot(offset[0], offset[1]);
            const ux = offset[0] / length;
            const uy = offset[1] / length;
            const reach = bowed ? Math.max(spacing * 0.75, distance * 0.45) : distance * 0.5;
            const bow = bowed ? Math.max(spacing * 0.25, distance * 0.22) : 0;
            // Right-hand side of travel in screen coordinates (y grows downward).
            return Qt.point(start.x + ux * reach - uy * bow, start.y + uy * reach + ux * bow);
        }

        const dx = end.x - start.x;
        const dy = end.y - start.y;
        return Qt.point((start.x + end.x) / 2 - dy * 0.25, (start.y + end.y) / 2 + dx * 0.25);
    }

    // Small filled arrowhead pointing along `from -> end`. By default the tip stops just outside
    // the destination node; pass `inset` 0 to put it exactly at `end` (stub tips).
    function drawArrowhead(context, from, end, color, inset) {
        let dx = end.x - from.x;
        let dy = end.y - from.y;
        const length = Math.sqrt(dx * dx + dy * dy);

        if (length < 0.001)
            return;

        dx /= length;
        dy /= length;

        const tipDistance = inset === undefined ? theme.modules.qreeper.nodeSize / 2 + 2 : inset;
        const size = 7;
        const tipX = end.x - dx * tipDistance;
        const tipY = end.y - dy * tipDistance;

        context.beginPath();
        context.setLineDash([]);
        context.fillStyle = color;
        context.moveTo(tipX, tipY);
        context.lineTo(tipX - dx * size - dy * size * 0.55, tipY - dy * size + dx * size * 0.55);
        context.lineTo(tipX - dx * size + dy * size * 0.55, tipY - dy * size - dx * size * 0.55);
        context.closePath();
        context.fill();
    }

    // Where an entrance marker sits: just outside the node, along the exit.
    function markerPoint(start, direction, slot) {
        const tip = stubPoint(start, direction, slot, 1);
        const dx = tip.x - start.x;
        const dy = tip.y - start.y;
        const length = Math.max(0.001, Math.hypot(dx, dy));
        const distance = theme.modules.qreeper.nodeSize / 2 + theme.modules.qreeper.entranceMarkerSize;
        return Qt.point(start.x + dx / length * distance, start.y + dy / length * distance);
    }

    function drawEntranceMarker(context, marker) {
        const qreeperTheme = theme.modules.qreeper;
        const size = qreeperTheme.entranceMarkerSize;
        const half = size / 2;
        const x = marker.point.x;
        const y = marker.point.y;

        context.setLineDash([]);
        context.lineWidth = 1.5;
        context.strokeStyle = qreeperTheme.mapColor;
        context.fillStyle = qreeperTheme.accentColor;
        context.beginPath();

        if (marker.kind === "portal") {
            context.arc(x, y, half, 0, Math.PI * 2);
            context.lineWidth = 2.5;
            context.strokeStyle = qreeperTheme.accentColor;
            context.stroke();
            context.lineWidth = 2;
            return;
        }

        if (marker.kind === "indoor") {
            const radius = size * qreeperTheme.indoorNodeRadius;
            context.moveTo(x - half + radius, y - half);
            context.arcTo(x + half, y - half, x + half, y + half, radius);
            context.arcTo(x + half, y + half, x - half, y + half, radius);
            context.arcTo(x - half, y + half, x - half, y - half, radius);
            context.arcTo(x - half, y - half, x + half, y - half, radius);
        } else {
            context.moveTo(x, y - half);
            context.lineTo(x + half, y);
            context.lineTo(x, y + half);
            context.lineTo(x - half, y);
        }

        context.closePath();
        context.fill();
        context.stroke();
        context.lineWidth = 2;
    }

    function inboundLabel(roomId) {
        const inbound = service.exitsTo(roomId);
        if (inbound.length === 0)
            return "";
        return "Reached via " + inbound.slice(0, 4).map(edge => edge.direction + " from #" + edge.from).join(", ")
            + (inbound.length > 4 ? " (+" + (inbound.length - 4) + " more)" : "");
    }

    function centerOnRoom(room, animated) {
        const position = room ? layout.point(room.id) : null;

        if (!position)
            return;
        hasCentered = true;
        level = roomLevel(room);
        cameraXAnimation.stop();
        cameraYAnimation.stop();
        if (!animated) {
            cameraX = position.x;
            cameraY = position.y;
            return;
        }
        cameraXAnimation.from = cameraX;
        cameraXAnimation.to = position.x;
        cameraYAnimation.from = cameraY;
        cameraYAnimation.to = position.y;
        cameraXAnimation.start();
        cameraYAnimation.start();
    }

    // One follow frame: ease the camera towards the current room (and onto its floor).
    function followStep() {
        const room = service.currentRoom;
        const position = room ? layout.point(room.id) : null;

        if (!position)
            return;

        const roomFloor = roomLevel(room);
        if (roomFloor !== null && roomFloor !== level)
            level = roomFloor;

        const dx = position.x - cameraX;
        const dy = position.y - cameraY;

        if (Math.abs(dx) < 0.002 && Math.abs(dy) < 0.002)
            return;

        cameraXAnimation.stop();
        cameraYAnimation.stop();
        hasCentered = true;
        const ease = theme.modules.qreeper.followEase;
        cameraX = Math.abs(dx) < 0.01 ? position.x : cameraX + dx * ease;
        cameraY = Math.abs(dy) < 0.01 ? position.y : cameraY + dy * ease;
    }

    function centerOnCurrent(animated) {
        centerOnRoom(service.currentRoom, animated);
    }
}
