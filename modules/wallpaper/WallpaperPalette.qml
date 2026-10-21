import QtQuick

// A wallpaper's dominant colours as one strip, each swatch as wide as its
// share of the image. Clickable strips report the swatch's hex.
Row {
    id: rootWallpaperPalette

    required property var colors
    property bool clickable: false
    property real swatchRadius: 0

    signal colorClicked(string hex)

    visible: colors !== undefined && colors !== null && colors.length > 0

    Repeater {
        model: rootWallpaperPalette.colors || []

        delegate: Rectangle {
            id: swatch

            required property var modelData

            width: rootWallpaperPalette.width * modelData.share
            height: rootWallpaperPalette.height
            radius: rootWallpaperPalette.swatchRadius
            color: modelData.hex

            MouseArea {
                anchors.fill: parent
                enabled: rootWallpaperPalette.clickable
                cursorShape: rootWallpaperPalette.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: rootWallpaperPalette.colorClicked(swatch.modelData.hex)
            }
        }
    }
}
