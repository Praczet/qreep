.pragma library

// Pure geometry: no QML, no theme object, so it can be tested with plain node.
//
// One ring around (0, 0), first node at twelve o'clock, going clockwise. Tab
// follows the same order. The radius grows until neighbours stop overlapping;
// when it hits maxRadius the nodes shrink instead, down to minNodeSize. Past
// that they overlap, which is a fair comment on a ring of forty things.
function ring(count, options) {
    let radius = Math.min(options.radius, options.maxRadius);
    let nodeSize = options.nodeSize;

    if (count > 1) {
        const sine = Math.sin(Math.PI / count);

        radius = Math.max(options.radius, (nodeSize + options.gap) / (2 * sine));
        if (radius > options.maxRadius) {
            radius = options.maxRadius;
            nodeSize = Math.max(options.minNodeSize, Math.min(nodeSize, 2 * radius * sine - options.gap));
        }
    }

    const points = [];

    for (let index = 0; index < count; index++) {
        const angle = -Math.PI / 2 + index * 2 * Math.PI / count;

        points.push({
            x: radius * Math.cos(angle),
            y: radius * Math.sin(angle)
        });
    }

    return {
        radius: radius,
        nodeSize: nodeSize,
        points: points
    };
}

function parentOf(id) {
    const slash = id.lastIndexOf("/");

    return slash < 0 ? "" : id.slice(0, slash);
}

// Where every node of the tree should be right now, relative to the middle of
// the screen: { id: { role, x, y, size, opacity, delay, ringIndex, parentLevel } }.
//
// Roles: "center", "ring", "parent", and "hidden". parentLevel is 1 for the
// direct parent, 2 for its parent, and so on, one per entry in parentSlots; any
// older ancestors stay hidden. A hidden node sits at size 0 on its nearest
// visible ancestor, so siblings shrink into the parent and children grow out of
// the node they belong to. Nothing here knows about
// animation; the nodes animate to whatever this says.
//
// `ids` are path-shaped ("root/0/2"), so the last segment is the ring index.
// options: { presented, bloomed, centerSize, staggerDelay, maxStagger,
//            parentSlots: [{ angle (degrees), radius, size, opacity }] }
function scene(ids, currentId, ringLayout, options) {
    const result = {};
    const slots = options.parentSlots.map(slot => ({
        x: slot.radius * Math.cos(slot.angle * Math.PI / 180),
        y: slot.radius * Math.sin(slot.angle * Math.PI / 180),
        size: slot.size,
        opacity: slot.opacity
    }));
    const levels = {};
    let ancestor = parentOf(currentId);

    for (let level = 1; ancestor.length > 0 && level <= slots.length; level++) {
        levels[ancestor] = level;
        ancestor = parentOf(ancestor);
    }

    function hiddenAt(point) {
        return {
            role: "hidden",
            x: point.x,
            y: point.y,
            size: 0,
            opacity: 0,
            delay: 0,
            ringIndex: -1,
            parentLevel: 0
        };
    }

    function visible(id) {
        if (id === currentId) {
            return {
                role: "center",
                x: 0,
                y: 0,
                size: options.centerSize,
                opacity: 1,
                delay: 0,
                ringIndex: -1,
                parentLevel: 0
            };
        }
        if (levels[id]) {
            const slot = slots[levels[id] - 1];

            return {
                role: "parent",
                x: slot.x,
                y: slot.y,
                size: slot.size,
                opacity: slot.opacity,
                delay: 0,
                ringIndex: -1,
                parentLevel: levels[id]
            };
        }
        if (options.bloomed && parentOf(id) === currentId) {
            const ringIndex = Number(id.slice(id.lastIndexOf("/") + 1));
            const point = ringLayout.points[ringIndex] || { x: 0, y: 0 };

            return {
                role: "ring",
                x: point.x,
                y: point.y,
                size: ringLayout.nodeSize,
                opacity: 1,
                delay: Math.min(ringIndex * options.staggerDelay, options.maxStagger),
                ringIndex: ringIndex,
                parentLevel: 0
            };
        }
        return null;
    }

    for (const id of ids) {
        if (!options.presented) {
            result[id] = hiddenAt({ x: 0, y: 0 });
            continue;
        }

        const shown = visible(id);

        if (shown) {
            result[id] = shown;
            continue;
        }

        // Anything from above the oldest shown parent lands in its slot.
        let anchor = slots[slots.length - 1];

        for (let up = parentOf(id); up.length > 0; up = parentOf(up)) {
            const shownAncestor = visible(up);

            if (shownAncestor) {
                anchor = shownAncestor;
                break;
            }
        }
        result[id] = hiddenAt(anchor);
    }

    return result;
}
