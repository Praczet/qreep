import QtQuick
import Quickshell

QtObject {
    id: rootOrbitTheme

    required property QtObject qreep

    readonly property string configDir: Quickshell.env("HOME") + "/.config/qreep/orbit"

    readonly property int centerSize: 112
    readonly property int nodeSize: 76
    readonly property int minNodeSize: 40
    readonly property int ringRadius: 220
    // Clear space kept between neighbours on the ring.
    readonly property int nodeGap: 18
    readonly property int screenMargin: 48
    readonly property real iconRatio: 0.56
    readonly property real textRatio: 0.34
    readonly property int selectedBorderWidth: 2
    // Caption under the centre: selected node's name, then what it does.
    readonly property int captionOffset: 12
    readonly property int captionWidth: 240
    readonly property int captionPadding: 6
    readonly property int captionPixelSize: 15
    readonly property int detailPixelSize: 11
    readonly property int hintPixelSize: 11
    // The name next to each ring node, on its outer side, so the ring is
    // readable without selecting everything in turn.
    readonly property bool showNodeNames: true
    readonly property int nameMaxWidth: 150
    readonly property int namePixelSize: 12
    readonly property int nameGap: 6
    readonly property int hintSize: 20
    readonly property int borderWidth: 1
    readonly property int animationDuration: 160
    // The way back: nearest parent first, each one smaller and fainter, curling
    // around the centre inside the ring and away from the caption. Angles are
    // degrees clockwise from three o'clock. One entry per parent shown.
    readonly property var parentSlots: [
        { angle: 150, radius: 120, size: 46, opacity: 0.2 },
        { angle: 170, radius: 140, size: 34, opacity: 0.16 },
        { angle: 187, radius: 154, size: 24, opacity: 0.13 },
        { angle: 200, radius: 164, size: 16, opacity: 0.1 }
    ]
    // The line from every visible node to its parent.
    readonly property int linkWidth: 1
    readonly property real linkOpacity: 0.35
    // Parents are faint, so their lines need a boost to be seen at all.
    readonly property real parentLinkBoost: 3
    // Going inside a node: it travels to the middle while its siblings shrink
    // into the parent. After bloomDelay its children grow out, one by one.
    readonly property int moveDuration: 340
    readonly property int shrinkDuration: 220
    readonly property int growDuration: 380
    readonly property int bloomDelay: 200
    readonly property int staggerDelay: 28
    readonly property int maxStagger: 160
    readonly property real growOvershoot: 1.5
    // The ring turning slowly around the centre, clockwise. Labels stay upright,
    // and keys and Tab order do not care where a node has drifted to.
    readonly property bool ringRotationEnabled: true
    readonly property int ringRotationSeconds: 120
    readonly property real selectedScale: 1.12
    readonly property int selectDuration: 150
    // The open circle around the selected node. It grows out from behind the
    // node when selected and shrinks back behind it when not.
    readonly property real selectionRingScale: 1.25
    readonly property real selectionRingWidth: 2.5
    readonly property int selectionRingDuration: 240
    readonly property real selectionRingOvershoot: 1.8
    readonly property real dimmedOpacity: 0.25

    readonly property color overlayColor: withAlpha(qreep.background, 0.45)
    readonly property color centerColor: qreep.primaryContainer
    readonly property color centerTextColor: qreep.on_primary_container
    readonly property color nodeColor: withAlpha(qreep.surfaceContainerHigh, 0.92)
    readonly property color nodeBorderColor: qreep.outline
    readonly property color selectedColor: qreep.primary
    readonly property color selectedTextColor: qreep.on_primary
    readonly property color textColor: qreep.on_surface
    readonly property color detailColor: qreep.on_surface_variant
    readonly property color hintColor: withAlpha(qreep.surfaceContainerHighest, 0.95)
    readonly property color captionColor: withAlpha(qreep.background, 0.7)
    readonly property color errorColor: qreep.error

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
