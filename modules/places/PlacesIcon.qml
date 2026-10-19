import QtQuick
import QtQuick.Effects

// Project icon: a themed (usually symbolic) icon tinted to `color`, else the
// config's nerd-font glyph, else the first letter of the name.
Item {
    id: rootPlacesIcon

    property string source: ""
    property string glyph: ""
    property string name: ""
    property color color: "white"
    property string fontFamily: ""

    Image {
        id: image

        anchors.fill: parent
        source: rootPlacesIcon.source
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: image
        visible: image.status === Image.Ready
        colorization: 1
        colorizationColor: rootPlacesIcon.color
        brightness: 1
    }

    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: rootPlacesIcon.glyph.length > 0 ? rootPlacesIcon.glyph : rootPlacesIcon.name.slice(0, 1).toUpperCase()
        color: rootPlacesIcon.color
        font.family: rootPlacesIcon.fontFamily
        font.pixelSize: rootPlacesIcon.height * 0.72
        font.bold: rootPlacesIcon.glyph.length === 0
    }
}
