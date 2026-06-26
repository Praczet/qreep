import QtQuick

QtObject {
    id: rootMprisTheme

    readonly property int pillMaxWidth: 300
    readonly property int pillContentSpacing: 8
    readonly property int pillIconPixelSize: 20
    readonly property int pillAlbumWidth: 60
    readonly property int pillTitleWidth: 78
    readonly property int pillArtistWidth: 96
    readonly property int pillTextPixelSize: 12
    readonly property int pillMutedTextPixelSize: 11
    readonly property int noteLayerWidth: 36
    readonly property int notePixelSize: 11
    readonly property int noteFadeDuration: 2300
    readonly property int noteStaggerDuration: 260
    readonly property bool animatePlayingNotes: true

    readonly property int controlButtonSize: 34
    readonly property int controlIconPixelSize: 18
    readonly property int controlSpacing: 8
    readonly property real disabledControlOpacity: 0.35

    readonly property int tooltipWidth: 340
    readonly property int tooltipArtSize: 72
    readonly property int tooltipSpacing: 10
    readonly property int tooltipTitlePixelSize: 14
    readonly property int tooltipBodyPixelSize: 12

    readonly property int panelWidth: 420
    readonly property int panelPadding: 16
    readonly property int panelRadius: 14
    readonly property int panelArtSize: 128
    readonly property int panelTopOffset: 10
    readonly property int panelTitlePixelSize: 16
    readonly property int panelBodyPixelSize: 12
    readonly property int panelRowSpacing: 12
}
