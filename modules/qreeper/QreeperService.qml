import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: rootQreeperService

    required property QtObject theme
    // Asleep: no file watch, no polling. The controller wakes it per session.
    property bool active: true
    readonly property string defaultSnapshotPath: Quickshell.env("HOME") + "/.local/state/qreeper/map.json"
    readonly property string snapshotPath: String(Quickshell.env("QREEP_QREEPER_MAP_PATH") || defaultSnapshotPath)
    property string loadState: "waiting"
    property string lastError: ""
    property bool stale: false
    property bool hasSnapshot: false
    property int revision: -1
    property string world: ""
    property string publishedAt: ""
    property double lastAppliedAt: 0
    property var currentRoomId: null
    property var rooms: []
    property var exits: []
    property var roomIndex: ({})
    // id (string) -> { name, type, realm, entranceRoomId } from the optional `maps` list.
    property var mapIndex: ({})
    // id (string) -> true for rooms with a named or up/down exit into another map (gate, enter,
    // portal). Compass doors are left out: the map view shows the room past them instead.
    property var gatewayIndex: ({})
    readonly property string displayState: loadState === "error" ? "error" : stale && hasSnapshot ? "stale" : loadState
    readonly property var currentRoom: roomForId(currentRoomId)
    readonly property string locationLabel: currentRoom ? roomLocation(currentRoom) : currentRoomId === null ? "location unresolved" : "room " + currentRoomId
    readonly property string statusLabel: displayState === "valid" ? "live snapshot" : displayState === "stale" ? "stale snapshot" : displayState === "error" ? "snapshot error" : "waiting for Qreeper"

    signal snapshotApplied(int revision)
    signal confirmedRoomTransition(var previousRoomId, var nextRoomId)

    readonly property FileView snapshotFile: FileView {
        path: rootQreeperService.active ? rootQreeperService.snapshotPath : ""
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: refreshDebounce.restart()
        onTextChanged: refreshDebounce.restart()
        onFileChanged: refreshDebounce.restart()
        onLoadFailed: error => {
            if (rootQreeperService.active)
                rootQreeperService.handleLoadFailure(error);
        }
    }

    readonly property Timer refreshDebounce: Timer {
        interval: 90
        repeat: false
        onTriggered: rootQreeperService.loadSnapshot()
    }

    // FileView watches the path, but atomic replacement behavior varies by watcher backend.
    // This is deliberately slow backup insurance, not a tiny polling furnace.
    readonly property Timer watcherFallback: Timer {
        interval: rootQreeperService.theme.modules.qreeper.watcherFallbackInterval
        repeat: true
        running: rootQreeperService.active
        onTriggered: rootQreeperService.snapshotFile.reload()
    }

    readonly property Timer staleTimer: Timer {
        interval: 30000
        repeat: true
        running: rootQreeperService.active
        onTriggered: rootQreeperService.updateStaleState()
    }

    function refresh() {
        if (!active)
            return;
        snapshotFile.reload();
        refreshDebounce.restart();
    }

    function handleLoadFailure(error) {
        if (error === FileViewError.FileNotFound) {
            if (!hasSnapshot) {
                loadState = "waiting";
                lastError = "Snapshot not found at " + snapshotPath;
            } else {
                stale = true;
            }
            return;
        }

        fail("Snapshot read failed: " + FileViewError.toString(error));
    }

    function loadSnapshot() {
        const contents = snapshotFile.text();

        if (contents.trim().length === 0) {
            if (!hasSnapshot)
                loadState = "waiting";
            return;
        }

        try {
            const normalized = normalizeSnapshot(JSON.parse(contents));

            if (hasSnapshot && normalized.revision <= revision)
                return;

            applySnapshot(normalized);
        } catch (error) {
            fail(String(error));
        }
    }

    function fail(message) {
        lastError = message;
        loadState = "error";
        if (hasSnapshot)
            stale = true;
    }

    function applySnapshot(snapshot) {
        const previousRoomId = currentRoomId;
        const index = {};

        for (let roomIndex = 0; roomIndex < snapshot.rooms.length; roomIndex++)
            index[String(snapshot.rooms[roomIndex].id)] = snapshot.rooms[roomIndex];

        const gateways = {};

        for (let exitIndex = 0; exitIndex < snapshot.exits.length; exitIndex++) {
            const edge = snapshot.exits[exitIndex];
            const from = index[String(edge.from)];
            const to = edge.to === null ? null : index[String(edge.to)];

            const compass = ["north", "south", "east", "west", "northeast", "northwest", "southeast", "southwest"].indexOf(edge.direction) >= 0;

            if (!compass && from && to && from.mapId !== null && to.mapId !== null && from.mapId !== to.mapId)
                gateways[String(edge.from)] = true;
        }

        rooms = snapshot.rooms;
        exits = snapshot.exits;
        roomIndex = index;
        mapIndex = snapshot.maps;
        gatewayIndex = gateways;
        revision = snapshot.revision;
        world = snapshot.world;
        publishedAt = snapshot.publishedAt;
        lastAppliedAt = Date.now();
        currentRoomId = snapshot.currentRoomId;
        hasSnapshot = true;
        loadState = "valid";
        lastError = "";
        updateStaleState();
        snapshotApplied(revision);

        if (previousRoomId !== null && previousRoomId !== currentRoomId)
            confirmedRoomTransition(previousRoomId, currentRoomId);
    }

    function updateStaleState() {
        if (!hasSnapshot) {
            stale = false;
            return;
        }

        stale = lastAppliedAt <= 0 || Date.now() - lastAppliedAt > theme.modules.qreeper.staleAfterMs;
    }

    function normalizeSnapshot(document) {
        if (!document || typeof document !== "object")
            throw new Error("Snapshot root must be an object");
        if (Number(document.schemaVersion) !== 1)
            throw new Error("Unsupported Qreeper schemaVersion: " + document.schemaVersion);
        if (!Array.isArray(document.rooms) || !Array.isArray(document.exits))
            throw new Error("Snapshot rooms and exits must be arrays");
        if (document.rooms.length > 3000 || document.exits.length > 10000)
            throw new Error("Snapshot exceeds the 3000 room / 10000 exit safety limit");

        const normalizedRevision = integer(document.revision, "revision", 0, 2147483647);
        const normalizedRooms = [];
        const knownRooms = {};
        const maps = normalizeMaps(document.maps);

        for (let index = 0; index < document.rooms.length; index++) {
            const room = normalizeRoom(document.rooms[index], index, maps);
            const key = String(room.id);

            if (knownRooms[key])
                throw new Error("Duplicate room id " + room.id);

            knownRooms[key] = true;
            normalizedRooms.push(room);
        }

        const normalizedCurrentRoomId = document.currentRoomId === null || document.currentRoomId === undefined
            ? null : integer(document.currentRoomId, "currentRoomId", 0, 2147483647);

        if (normalizedCurrentRoomId !== null && !knownRooms[String(normalizedCurrentRoomId)])
            throw new Error("currentRoomId does not reference a provided room");

        const normalizedExits = [];

        for (let index = 0; index < document.exits.length; index++)
            normalizedExits.push(normalizeExit(document.exits[index], index, knownRooms));

        return {
            schemaVersion: 1,
            world: shortText(document.world || "unknown", 80),
            revision: normalizedRevision,
            publishedAt: shortText(document.publishedAt || "", 80),
            currentRoomId: normalizedCurrentRoomId,
            rooms: normalizedRooms,
            exits: normalizedExits,
            maps: maps,
            layout: document.layout && typeof document.layout === "object" ? document.layout : {}
        };
    }

    // Optional `maps` list: id (string) -> { name, type, realm }. Bad entries are skipped.
    function normalizeMaps(source) {
        const maps = {};

        if (!Array.isArray(source))
            return maps;

        for (let index = 0; index < source.length && index < 3000; index++) {
            const map = source[index];
            const id = map && typeof map === "object" ? Number(map.id) : NaN;

            if (!Number.isInteger(id))
                continue;

            maps[String(id)] = {
                name: shortText(map.name || "", 160),
                type: shortText(map.type || "outdoor", 40),
                realm: map.realm === null || map.realm === undefined ? "" : shortText(map.realm, 160),
                entranceRoomId: Number.isInteger(Number(map.entranceRoomId)) && map.entranceRoomId !== null ? Number(map.entranceRoomId) : null
            };
        }

        return maps;
    }

    function normalizeRoom(source, index, maps) {
        if (!source || typeof source !== "object")
            throw new Error("Room " + index + " must be an object");

        const id = integer(source.id, "room id", 0, 2147483647);
        const x = nullableCoordinate(source.x);
        const y = nullableCoordinate(source.y);
        const z = nullableCoordinate(source.z);
        const requestedStatus = shortText(source.positionStatus || (x === null || y === null ? "unplaced" : "inferred"), 20);
        const positionStatus = ["fixed", "inferred", "unplaced"].indexOf(requestedStatus) >= 0 ? requestedStatus : "unplaced";
        const mapId = source.mapId === null || source.mapId === undefined ? null : Number(source.mapId);
        const map = mapId !== null && Number.isInteger(mapId) ? maps[String(mapId)] || null : null;
        const notes = [];
        const sourceNotes = Array.isArray(source.notes) ? source.notes.slice(0, 40) : [];

        for (let noteIndex = 0; noteIndex < sourceNotes.length; noteIndex++) {
            const note = sourceNotes[noteIndex];
            if (!note || typeof note !== "object")
                continue;
            notes.push({
                id: note.id === undefined || note.id === null ? null : integer(note.id, "note id", 0, 2147483647),
                text: shortText(note.text || "", 2000),
                createdAt: shortText(note.createdAt || "", 80)
            });
        }

        return {
            id: id,
            name: shortText(source.name || "Unnamed room", 240),
            description: source.description === null || source.description === undefined ? "" : shortText(source.description, 4000),
            realm: map && map.realm ? map.realm : shortText(source.realm || "", 160),
            area: shortText(source.area || "", 160),
            mapId: map ? mapId : null,
            mapName: map ? map.name : "",
            // "outdoor" when the producer sends no maps; anything else is drawn as indoors.
            mapType: map ? map.type : "outdoor",
            level: source.level === null || source.level === undefined ? null : integer(source.level, "room level", -1000, 1000),
            x: x,
            y: y,
            z: z,
            positionStatus: positionStatus,
            placed: positionStatus !== "unplaced" && x !== null && y !== null,
            marked: source.marked === true,
            notes: notes
        };
    }

    function normalizeExit(source, index, knownRooms) {
        if (!source || typeof source !== "object")
            throw new Error("Exit " + index + " must be an object");

        const from = integer(source.from, "exit from", 0, 2147483647);
        if (!knownRooms[String(from)])
            throw new Error("Exit " + index + " references missing source room " + from);
        const to = source.to === null || source.to === undefined ? null : integer(source.to, "exit to", 0, 2147483647);
        const allowedGeometry = ["regular", "irregular", "named", "unknown", "unplaced"];
        const boundary = source.boundary === "door" || source.boundary === "portal" ? source.boundary : null;
        const requestedGeometry = shortText(source.geometry || (to === null ? "unknown" : "regular"), 20);

        return {
            from: from,
            to: to,
            direction: shortText(source.direction || "unknown", 80),
            geometry: allowedGeometry.indexOf(requestedGeometry) >= 0 ? requestedGeometry : "irregular",
            boundary: boundary,
            targetKnown: to !== null && !!knownRooms[String(to)]
        };
    }

    function integer(value, label, minimum, maximum) {
        const number = Number(value);
        if (!Number.isFinite(number) || Math.floor(number) !== number || number < minimum || number > maximum)
            throw new Error(label + " must be an integer between " + minimum + " and " + maximum);
        return number;
    }

    function nullableCoordinate(value) {
        if (value === null || value === undefined)
            return null;
        const number = Number(value);
        if (!Number.isFinite(number))
            return null;
        return Math.max(-10000, Math.min(10000, number));
    }

    function shortText(value, limit) {
        return String(value).slice(0, limit);
    }

    function roomForId(id) {
        if (id === null || id === undefined)
            return null;
        return roomIndex[String(id)] || null;
    }

    function roomLocation(room) {
        if (!room)
            return "location unresolved";
        const area = room.mapName || room.area || room.realm || room.name;
        const level = room.level === null ? "level ?" : "level " + room.level;
        return area + " · " + level + " · #" + room.id;
    }

    function isGateway(id) {
        return !!gatewayIndex[String(id)];
    }

    function mapForId(id) {
        if (id === null || id === undefined)
            return null;
        return mapIndex[String(id)] || null;
    }

    // What the outside room should show for an exit: null, or "indoor" / "portal" / "outdoor"
    // when the exit leads into another map's entrance room (the way in, not the way out).
    function entranceMarker(edge) {
        if (edge.to === null)
            return null;

        const from = roomForId(edge.from);
        const to = roomForId(edge.to);

        if (!from || !to || to.mapId === null || from.mapId === to.mapId)
            return null;

        const map = mapForId(to.mapId);

        if (!map || map.entranceRoomId !== to.id)
            return null;
        if (edge.boundary === "portal")
            return "portal";
        return map.type === "outdoor" ? "outdoor" : "indoor";
    }

    function exitsFrom(roomId) {
        return exits.filter(edge => edge.from === roomId);
    }

    function exitsTo(roomId) {
        if (roomId === null || roomId === undefined)
            return [];
        return exits.filter(edge => edge.to === roomId);
    }
}
