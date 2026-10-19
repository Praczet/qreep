import QtQuick
import QtQuick.Effects

// A combo as a small poster: its bands stacked, sharing the height. Used
// in the palette grid; the full-size combo is a ListView of PrismBand.
// A rounded Rectangle does not round its children, so the bands are drawn
// into a layer and masked by a rounded shape.
Item {
    id: rootPrismPoster

    required property QtObject pt
    required property QtObject service
    required property var colors
    property bool compact: true
    property real radius: 12

    Rectangle {
        id: mask

        anchors.fill: parent
        radius: rootPrismPoster.radius
        visible: false
        layer.enabled: true
    }

    Column {
        id: stack

        anchors.fill: parent
        visible: false
        layer.enabled: true

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

    MultiEffect {
        anchors.fill: parent
        source: stack
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Rectangle {
        anchors.fill: parent
        visible: rootPrismPoster.colors.length === 0
        radius: rootPrismPoster.radius
        color: rootPrismPoster.pt.cardColor
    }

    Text {
        anchors.centerIn: parent
        visible: rootPrismPoster.colors.length === 0
        text: "empty"
        color: rootPrismPoster.pt.secondaryTextColor
        font.pixelSize: rootPrismPoster.pt.metaPixelSize
    }
}
