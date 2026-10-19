import QtQuick

// A combo as a small poster: its bands stacked, sharing the height. Used
// in the palette grid; the full-size combo is a ListView of PrismBand.
Rectangle {
    id: rootPrismPoster

    required property QtObject pt
    required property QtObject service
    required property var colors
    property bool compact: true

    color: pt.cardColor
    clip: true
    // Rounded corners for the stacked bands come from this mask's clip.
    layer.enabled: true

    Column {
        anchors.fill: parent

        Repeater {
            model: rootPrismPoster.colors

            PrismBand {
                required property var modelData

                width: rootPrismPoster.width
                height: rootPrismPoster.height / Math.max(1, rootPrismPoster.colors.length)
                pt: rootPrismPoster.pt
                hex: modelData.hex
                name: modelData.name
                ink: rootPrismPoster.service.textOn(modelData.hex, rootPrismPoster.colors)
                titlePixelSize: rootPrismPoster.compact ? 24 : rootPrismPoster.pt.bandTitlePixelSize
                interactive: false
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: rootPrismPoster.colors.length === 0
        text: "empty"
        color: rootPrismPoster.pt.secondaryTextColor
        font.pixelSize: rootPrismPoster.pt.metaPixelSize
    }
}
