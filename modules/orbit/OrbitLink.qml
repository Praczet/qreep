import QtQuick

// The line between a node and its parent, following both while they move. It
// stops at the circles' edges, so it does not show through the faint parent,
// and it shrinks to nothing when a child folds back into its parent.
Rectangle {
    id: rootOrbitLink

    required property QtObject ot
    property Item childNode: null
    property Item parentNode: null
    required property real originX
    required property real originY

    readonly property bool linked: childNode !== null && parentNode !== null
    readonly property real dx: linked ? childNode.shownX - parentNode.shownX : 0
    readonly property real dy: linked ? childNode.shownY - parentNode.shownY : 0
    readonly property real distance: Math.sqrt(dx * dx + dy * dy)
    readonly property real parentEdge: linked ? parentNode.scale * ot.centerSize / 2 : 0
    readonly property real childEdge: linked ? childNode.scale * ot.centerSize / 2 : 0

    x: linked && distance > 0 ? originX + parentNode.shownX + dx / distance * parentEdge : 0
    y: (linked && distance > 0 ? originY + parentNode.shownY + dy / distance * parentEdge : 0) - height / 2
    width: Math.max(0, distance - parentEdge - childEdge)
    height: ot.linkWidth
    transformOrigin: Item.Left
    rotation: Math.atan2(dy, dx) * 180 / Math.PI
    antialiasing: true
    color: ot.textColor
    opacity: linked ? ot.linkOpacity * childNode.opacity * (childNode.role === "parent" ? ot.parentLinkBoost : 1) * (childNode.dimmed ? ot.dimmedOpacity : 1) : 0
    visible: linked && width > 0.5 && opacity > 0.001
}
