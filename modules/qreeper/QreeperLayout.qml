import QtQuick
import Quickshell
import Quickshell.Io

// Organic map layout shared by the minimap and the Atlas.
//
// The producer's grid positions are only a starting point. Every room gets a position here
// (unplaced rooms are seeded next to a neighbour), then a small force simulation settles it:
//   - each compass exit pulls its target towards the recorded direction (n = up, se = down
//     right); a pair confirmed both ways is one spring that pulls twice as hard
//   - named exits (enter, omp, ...) are plain springs with no direction
//   - rooms on the same level of the same map repel inside layoutRepelRadius, so nodes cannot
//     overlap; rooms of different maps or levels never pull or push each other
//   - rooms the user dragged are pinned and act as anchors
// It only ticks while something is moving and at least one map view is open, then sleeps.
//
// Positions and pins are QREEP's own state (layoutPath). Qreeper's database is never written.
// Units are map cells, the same units as the producer's x/y.
QtObject {
    id: rootQreeperLayout

    required property QtObject theme
    required property QtObject service
    // Bound by the controller: true while the minimap or the Atlas is open.
    property bool active: false

    readonly property string layoutPath: Quickshell.env("HOME") + "/.local/state/qreep/qreeper-layout.json"
    readonly property QtObject tuning: theme.modules.qreeper

    // Views read positions through point(); reading `revision` there makes bindings follow.
    property int revision: 0
    property bool settling: false
    property bool savedLoaded: false

    // id (string) -> { x, y, vx, vy, level, pinned }; `level` is the layer key 'map:level'
    property var nodes: ({})
    // id (string) -> { x, y, pinned } for pinned rooms from layoutPath, consumed when the room
    // first appears. Unpinned positions in the file are ignored: they are only simulation
    // output, and once stale (a rebuilt database reusing ids) they would override the
    // producer's grid. The springs cannot undo that when two rooms swap along one line.
    property var saved: ({})
    property var mutualPairs: ({})
    property int idleTicks: 0
    property int ticks: 0

    readonly property var offsets: ({
            north: [0, -1],
            south: [0, 1],
            east: [1, 0],
            west: [-1, 0],
            northeast: [1, -1],
            northwest: [-1, -1],
            southeast: [1, 1],
            southwest: [-1, 1]
        })
    readonly property var opposites: ({
            north: "south",
            south: "north",
            east: "west",
            west: "east",
            northeast: "southwest",
            southwest: "northeast",
            northwest: "southeast",
            southeast: "northwest"
        })

    readonly property Connections serviceConnection: Connections {
        target: rootQreeperLayout.service

        function onSnapshotApplied() {
            rootQreeperLayout.sync();
        }
    }

    readonly property FileView layoutFile: FileView {
        path: rootQreeperLayout.layoutPath
        preload: true
        printErrors: false

        onLoaded: rootQreeperLayout.loadSaved()
        onLoadFailed: rootQreeperLayout.savedLoaded = true
    }

    readonly property Process layoutWriter: Process {}

    readonly property Timer tickTimer: Timer {
        interval: rootQreeperLayout.tuning.layoutTickMs
        repeat: true
        running: rootQreeperLayout.settling && rootQreeperLayout.active
        onTriggered: rootQreeperLayout.step()
    }

    readonly property Timer saveTimer: Timer {
        interval: 1500
        repeat: false
        onTriggered: rootQreeperLayout.save()
    }

    // Public API -------------------------------------------------------------------------

    function point(id) {
        const unused = revision;
        return nodes[String(id)] || null;
    }

    function isPinned(id) {
        const unused = revision;
        const node = nodes[String(id)];
        return !!node && node.pinned;
    }

    // Drag: pin the room and put it under the pointer (cell coordinates).
    function drag(id, x, y) {
        const node = nodes[String(id)];

        if (!node)
            return;

        node.pinned = true;
        node.x = x;
        node.y = y;
        node.vx = 0;
        node.vy = 0;
        kick();
    }

    function endDrag(id) {
        kick();
        saveTimer.restart();
    }

    function unpin(id) {
        const node = nodes[String(id)];

        if (!node || !node.pinned)
            return;

        node.pinned = false;
        kick();
        saveTimer.restart();
    }

    // Re-run the layout from the producer's grid, keeping pinned rooms where they are.
    function rearrange() {
        const keep = {};

        for (const key in nodes) {
            if (nodes[key].pinned)
                keep[key] = nodes[key];
        }

        nodes = keep;
        saved = ({});
        sync();
        saveTimer.restart();
    }

    // Forget every position and pin, including the saved file's.
    function reset() {
        nodes = ({});
        saved = ({});
        sync();
        saveTimer.restart();
    }

    // Seeding ---------------------------------------------------------------------------

    // Layer key: each floor of each map is laid out on its own.
    function roomLevel(room) {
        const level = room.level !== null && room.level !== undefined ? room.level
            : room.z !== null && room.z !== undefined ? room.z : 0;
        return (room.mapId === null || room.mapId === undefined ? "-" : room.mapId) + ":" + level;
    }

    // Small deterministic offset so seeded rooms never start exactly on top of each other.
    function jitter(id, salt) {
        const value = Math.sin(Number(id) * 12.9898 + salt * 78.233) * 43758.5453;
        return (value - Math.floor(value) - 0.5) * 0.3;
    }

    function sync() {
        const rooms = service.rooms;
        const exits = service.exits;
        const next = {};
        const pending = [];

        for (let index = 0; index < rooms.length; index++) {
            const room = rooms[index];
            const key = String(room.id);
            const level = roomLevel(room);
            const existing = nodes[key];
            const stored = saved[key];

            if (existing) {
                existing.level = level;
                next[key] = existing;
            } else if (stored) {
                next[key] = { x: stored.x, y: stored.y, vx: 0, vy: 0, level: level, pinned: !!stored.pinned };
            } else if (room.placed) {
                next[key] = { x: room.x + jitter(room.id, 1), y: room.y + jitter(room.id, 2), vx: 0, vy: 0, level: level, pinned: false };
            } else {
                pending.push(room);
            }
        }

        // Unplaced rooms start beside a positioned neighbour, in the direction the exit says.
        // Repeat until nothing more can be seeded, so long chains are followed to their end.
        const growFromPlaced = () => {
            let progress = true;

            while (progress && pending.length > 0) {
                progress = false;

                for (let index = pending.length - 1; index >= 0; index--) {
                    const room = pending[index];
                    const seed = seedFor(room, next, exits);

                    if (seed) {
                        next[String(room.id)] = { x: seed.x, y: seed.y, vx: 0, vy: 0, level: roomLevel(room), pinned: false };
                        pending.splice(index, 1);
                        progress = true;
                    }
                }
            }
        };

        growFromPlaced();

        // What is left are separate areas with no position at all (e.g. after a producer
        // relayout). Start each one east of everything already laid out, then grow it, so
        // areas never land on top of each other.
        while (pending.length > 0) {
            let maxX = null;
            let minY = null;

            for (const key in next) {
                maxX = maxX === null ? next[key].x : Math.max(maxX, next[key].x);
                minY = minY === null ? next[key].y : Math.min(minY, next[key].y);
            }

            pending.sort((a, b) => a.id - b.id);
            const root = pending.shift();
            next[String(root.id)] = {
                x: maxX === null ? 0 : maxX + 3,
                y: minY === null ? 0 : minY,
                vx: 0,
                vy: 0,
                level: roomLevel(root),
                pinned: false
            };
            growFromPlaced();
        }

        const pairs = {};
        const recorded = {};

        for (let index = 0; index < exits.length; index++) {
            const exit = exits[index];
            if (exit.to !== null)
                recorded[exit.from + ":" + exit.direction] = exit.to;
        }

        for (let index = 0; index < exits.length; index++) {
            const exit = exits[index];
            const back = opposites[exit.direction];
            if (exit.to !== null && back && recorded[exit.to + ":" + back] === exit.from)
                pairs[exit.from + ">" + exit.to] = true;
        }

        nodes = next;
        mutualPairs = pairs;
        kick();
    }

    function seedFor(room, placed, exits) {
        for (let index = 0; index < exits.length; index++) {
            const exit = exits[index];
            let anchor = null;
            let sign = 1;

            if (exit.to === room.id && placed[String(exit.from)]) {
                anchor = placed[String(exit.from)];
            } else if (exit.from === room.id && exit.to !== null && placed[String(exit.to)]) {
                anchor = placed[String(exit.to)];
                sign = -1;
            }

            if (!anchor)
                continue;

            const offset = offsets[exit.direction] || [0.8, 0.8];
            return {
                x: anchor.x + sign * offset[0] + jitter(room.id, 5),
                y: anchor.y + sign * offset[1] + jitter(room.id, 6)
            };
        }

        return null;
    }

    // Simulation ------------------------------------------------------------------------

    function kick() {
        idleTicks = 0;
        ticks = 0;
        settling = true;
        revision++;
    }

    function step() {
        const keys = Object.keys(nodes);
        const exits = service.exits;
        const forces = {};
        const springStrength = tuning.layoutSpringStrength;
        const namedRest = tuning.layoutNamedRest;
        const radius = tuning.layoutRepelRadius;
        const repelStrength = tuning.layoutRepelStrength;

        for (let index = 0; index < keys.length; index++)
            forces[keys[index]] = { x: 0, y: 0 };

        // Exit springs.
        for (let index = 0; index < exits.length; index++) {
            const exit = exits[index];

            if (exit.to === null)
                continue;

            const fromKey = String(exit.from);
            const toKey = String(exit.to);
            const a = nodes[fromKey];
            const b = nodes[toKey];

            if (!a || !b || a === b || a.level !== b.level)
                continue;

            const offset = offsets[exit.direction];

            // The producer already says this compass exit lies about geography (looping valleys,
            // mazes). A spring would drag whole blocks of rooms across the map to obey it.
            if (offset && exit.geometry === "irregular")
                continue;
            let errorX;
            let errorY;
            let strength;

            if (offset) {
                // A pair confirmed both ways is one double spring, not two: the exit back would
                // pull the same pair again. Four times the pull on an 8-way grid (Valley of Eras,
                // 2026-10-14) made the step overshoot, so the layout bounced until layoutMaxTicks.
                if (mutualPairs[fromKey + ">" + toKey] && exit.from > exit.to)
                    continue;
                // Pull b towards a + offset (and a towards b - offset).
                errorX = b.x - a.x - offset[0];
                errorY = b.y - a.y - offset[1];
                strength = springStrength * (mutualPairs[fromKey + ">" + toKey] ? 2 : 1);
            } else {
                // Named exit: keep a comfortable distance, any direction.
                const dx = b.x - a.x;
                const dy = b.y - a.y;
                const distance = Math.max(0.001, Math.hypot(dx, dy));
                const stretch = (distance - namedRest) / distance;
                errorX = dx * stretch;
                errorY = dy * stretch;
                strength = springStrength * 0.5;
            }

            forces[fromKey].x += errorX * strength;
            forces[fromKey].y += errorY * strength;
            forces[toKey].x -= errorX * strength;
            forces[toKey].y -= errorY * strength;
        }

        // Repulsion between rooms on the same layer, using a spatial hash.
        const buckets = {};

        for (let index = 0; index < keys.length; index++) {
            const node = nodes[keys[index]];
            const bucket = node.level + ":" + Math.floor(node.x / radius) + ":" + Math.floor(node.y / radius);
            (buckets[bucket] = buckets[bucket] || []).push(keys[index]);
        }

        for (let index = 0; index < keys.length; index++) {
            const key = keys[index];
            const node = nodes[key];
            const column = Math.floor(node.x / radius);
            const row = Math.floor(node.y / radius);

            for (let dx = -1; dx <= 1; dx++) {
                for (let dy = -1; dy <= 1; dy++) {
                    const neighbours = buckets[node.level + ":" + (column + dx) + ":" + (row + dy)];

                    if (!neighbours)
                        continue;

                    for (let other = 0; other < neighbours.length; other++) {
                        const otherKey = neighbours[other];

                        if (otherKey <= key)
                            continue;

                        const peer = nodes[otherKey];
                        let ox = node.x - peer.x;
                        let oy = node.y - peer.y;
                        let distance = Math.hypot(ox, oy);

                        if (distance >= radius)
                            continue;

                        if (distance < 0.001) {
                            ox = jitter(Number(key) + Number(otherKey), 7) || 0.1;
                            oy = jitter(Number(key) * 3 + Number(otherKey), 8) || 0.1;
                            distance = Math.hypot(ox, oy);
                        }

                        const push = repelStrength * (radius - distance) / distance;
                        forces[key].x += ox * push;
                        forces[key].y += oy * push;
                        forces[otherKey].x -= ox * push;
                        forces[otherKey].y -= oy * push;
                    }
                }
            }
        }

        // Integrate.
        const damping = tuning.layoutDamping;
        const maxStep = tuning.layoutMaxStep;
        let fastest = 0;

        for (let index = 0; index < keys.length; index++) {
            const node = nodes[keys[index]];

            if (node.pinned) {
                node.vx = 0;
                node.vy = 0;
                continue;
            }

            node.vx = (node.vx + forces[keys[index]].x) * damping;
            node.vy = (node.vy + forces[keys[index]].y) * damping;

            const speed = Math.hypot(node.vx, node.vy);

            if (speed > maxStep) {
                node.vx *= maxStep / speed;
                node.vy *= maxStep / speed;
            }

            node.x += node.vx;
            node.y += node.vy;
            fastest = Math.max(fastest, Math.min(speed, maxStep));
        }

        ticks++;
        idleTicks = fastest < tuning.layoutRestSpeed ? idleTicks + 1 : 0;
        revision++;

        if (idleTicks > 30 || ticks > tuning.layoutMaxTicks) {
            settling = false;
            saveTimer.restart();
        }
    }

    // Persistence -----------------------------------------------------------------------

    function loadSaved() {
        savedLoaded = true;

        try {
            const document = JSON.parse(layoutFile.text());

            if (!document || document.version !== 1 || typeof document.rooms !== "object")
                return;

            const loaded = {};

            for (const key in document.rooms) {
                const entry = document.rooms[key];
                const x = Number(entry.x);
                const y = Number(entry.y);

                if (entry.pinned && Number.isFinite(x) && Number.isFinite(y))
                    loaded[key] = { x: x, y: y, pinned: true };
            }

            saved = loaded;

            // Positions may already exist from a snapshot that arrived first; saved pins win.
            for (const key in loaded) {
                const node = nodes[key];

                if (node) {
                    node.x = loaded[key].x;
                    node.y = loaded[key].y;
                    node.pinned = true;
                }
            }

            kick();
        } catch (error) {
            console.warn("Qreeper layout file ignored: " + error);
        }
    }

    function save() {
        const rooms = {};

        for (const key in nodes) {
            const node = nodes[key];
            rooms[key] = { x: Math.round(node.x * 1000) / 1000, y: Math.round(node.y * 1000) / 1000, pinned: node.pinned };
        }

        layoutWriter.running = false;
        layoutWriter.command = [
            "python3",
            "-c",
            "import json, os, sys\npath = sys.argv[1]\npayload = json.loads(sys.argv[2])\nos.makedirs(os.path.dirname(path), exist_ok=True)\ntemporary = path + '.tmp'\nwith open(temporary, 'w', encoding='utf-8') as handle:\n    json.dump(payload, handle)\n    handle.write('\\n')\nos.replace(temporary, path)",
            layoutPath,
            JSON.stringify({ version: 1, world: service.world, rooms: rooms })
        ];
        layoutWriter.running = true;
    }
}
