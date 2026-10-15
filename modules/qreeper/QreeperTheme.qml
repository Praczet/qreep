import QtQuick

QtObject {
    id: rootQreeperTheme

    required property QtObject qreep

    // Text size multiplier for the minimap and the Atlas. Node, grid, header, and control
    // sizes follow it so room ids still fit inside their rooms. This is the startup value;
    // `qreep-qreeper fontBigger/fontSmaller/setFontScale` change it until the next restart.
    property real fontScale: 1.0
    readonly property real fontScaleMinimum: 0.7
    readonly property real fontScaleMaximum: 2.0
    readonly property real fontScaleStep: 0.1

    readonly property int minimapWidth: 390
    readonly property int minimapHeight: 320
    readonly property int minimapTopMargin: 82
    readonly property int minimapRightMargin: 22
    readonly property int minimapScreenMargin: 12
    readonly property int headerHeight: Math.round(42 * fontScale)
    readonly property int panelPadding: 14
    readonly property int panelRadius: 15
    readonly property int atlasMargin: 34
    readonly property int atlasSidebarWidth: 310
    readonly property int controlSize: Math.round(28 * fontScale)
    readonly property int nodeSize: Math.round(26 * fontScale)
    readonly property int currentNodeSize: Math.round(34 * fontScale)
    // Corner radius of indoor (non-outdoor map) rooms, as a fraction of the node size.
    readonly property real indoorNodeRadius: 0.22
    // Entrance markers on the outside room (door into a building, portal, ...), in pixels.
    readonly property int entranceMarkerSize: 9
    // Off-map stubs name the map they lead to, cut to this many characters.
    readonly property int stubMapNameLength: 18
    // Gap between a gateway room (exit into another map) and its outer ring, in pixels.
    readonly property int gatewayRingGap: 4
    // Rooms of a neighbouring map shown just past a compass door.
    readonly property real peekOpacity: 0.55
    // How far past the door they sit (cells) and their size relative to a normal room.
    readonly property real peekDistance: 0.62
    readonly property real peekScale: 0.72
    readonly property int gridSpacing: Math.round(76 * fontScale)
    // Exit labels sit this far along the edge from their own room, hide below this zoom,
    // and named exits longer than this many cells become labelled stubs instead of curves.
    readonly property real edgeLabelPosition: 0.34
    readonly property int edgeLabelPixelSize: Math.round(9 * fontScale)
    readonly property int edgeLabelMinSpacing: Math.round(44 * fontScale)
    readonly property real namedCurveMaxCells: 2.5
    readonly property int hoverCardWidth: 220
    // Organic layout (QreeperLayout.qml). Units are map cells per tick.
    readonly property int layoutTickMs: 16
    readonly property real layoutSpringStrength: 0.08
    readonly property real layoutNamedRest: 1.4
    readonly property real layoutRepelRadius: 1.3
    readonly property real layoutRepelStrength: 0.25
    readonly property real layoutDamping: 0.8
    readonly property real layoutMaxStep: 0.25
    readonly property real layoutRestSpeed: 0.003
    readonly property int layoutMaxTicks: 1200
    // An exit draws solid when its target is within ~35° of the recorded direction.
    readonly property real layoutAgreeCos: 0.82
    readonly property int followDuration: 300
    // Share of the remaining distance the minimap camera covers per frame while following.
    readonly property real followEase: 0.18
    readonly property real minimumZoom: 0.35
    readonly property real maximumZoom: 2.4
    readonly property int staleAfterMs: 300000
    readonly property int watcherFallbackInterval: 2000

    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, 0.94)
    readonly property color atlasOverlayColor: Qt.rgba(qreep.background.r, qreep.background.g, qreep.background.b, 0.72)
    readonly property color mapColor: Qt.rgba(qreep.surfaceContainerLowest.r, qreep.surfaceContainerLowest.g, qreep.surfaceContainerLowest.b, 0.92)
    readonly property color cardColor: qreep.surfaceContainer
    readonly property color borderColor: qreep.outline
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color currentColor: qreep.primary
    readonly property color noteColor: qreep.warningColor
    readonly property color errorColor: qreep.error
    readonly property color successColor: qreep.successColor
    readonly property color unknownColor: qreep.on_surface_variant
    readonly property color irregularColor: qreep.warningColor
    // Rooms the player marked (`qreeper:mark-it`): thick border and a tinted fill.
    readonly property color markedColor: qreep.tertiary
    readonly property real markedFillAlpha: 0.3
    readonly property int titlePixelSize: Math.round(16 * fontScale)
    readonly property int bodyPixelSize: Math.round(13 * fontScale)
    readonly property int metaPixelSize: Math.round(11 * fontScale)
    readonly property int atlasTitlePixelSize: Math.round(19 * fontScale)
    // Glyph buttons (×, +, −, ◎, ↗).
    readonly property int iconPixelSize: Math.round(18 * fontScale)
}
