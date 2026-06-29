import QtQuick
import Quickshell

Item {
    id: rootImageBlock

    required property QtObject theme
    property var config: ({})

    implicitWidth: numberValue(config.width, 320)
    implicitHeight: numberValue(config.height, 180)

    readonly property string imagePath: expandPath(stringValue(config.path, ""))
    readonly property int imageFillMode: fillModeValue(config.fillMode, Image.PreserveAspectFit)
    readonly property int imageHorizontalAlignment: horizontalAlignmentValue(config.horizontalAlignment, Image.AlignHCenter)
    readonly property int imageVerticalAlignment: verticalAlignmentValue(config.verticalAlignment, Image.AlignVCenter)
    readonly property bool showBackground: boolValue(config.showBackground, false)
    readonly property color backgroundColor: colorValue(config.backgroundColor, theme.modules.dashboard.backgroundColor)
    readonly property real radius: numberValue(config.radius, theme.modules.dashboard.cardRadius)

    clip: boolValue(config.clip, true)
    opacity: numberValue(config.opacity, 1)

    Rectangle {
        anchors.fill: parent
        visible: rootImageBlock.showBackground
        radius: rootImageBlock.radius
        color: rootImageBlock.backgroundColor
    }

    Image {
        id: chartImage

        anchors.fill: parent
        source: rootImageBlock.imagePath
        fillMode: rootImageBlock.imageFillMode
        horizontalAlignment: rootImageBlock.imageHorizontalAlignment
        verticalAlignment: rootImageBlock.imageVerticalAlignment
        smooth: boolValue(rootImageBlock.config.smooth, true)
        mipmap: boolValue(rootImageBlock.config.mipmap, true)
        cache: boolValue(rootImageBlock.config.cache, false)
        asynchronous: boolValue(rootImageBlock.config.asynchronous, true)
    }

    Text {
        anchors.centerIn: parent
        visible: rootImageBlock.imagePath.length === 0 || chartImage.status === Image.Error
        width: parent.width
        text: rootImageBlock.imagePath.length === 0 ? "Missing image path" : "Image failed to load"
        color: rootImageBlock.theme.modules.dashboard.secondaryTextColor
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font.pixelSize: rootImageBlock.theme.modules.dashboard.bodyPixelSize
    }

    function stringValue(value, fallback) {
        return typeof value === "string" && value.length > 0 ? value : fallback;
    }

    function numberValue(value, fallback) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function boolValue(value, fallback) {
        return typeof value === "boolean" ? value : fallback;
    }

    function colorValue(value, fallback) {
        if (typeof value !== "string" || value.length === 0)
            return fallback;

        return value.indexOf("{{") === 0 ? theme.colorToken(value, fallback) : value;
    }

    function expandPath(path) {
        const text = String(path || "");

        if (text === "~")
            return Quickshell.env("HOME") || text;

        if (text.indexOf("~/") === 0)
            return (Quickshell.env("HOME") || "") + text.slice(1);

        return text;
    }

    function fillModeValue(value, fallback) {
        switch (String(value || "")) {
        case "stretch":
            return Image.Stretch;
        case "preserveAspectCrop":
        case "crop":
            return Image.PreserveAspectCrop;
        case "tile":
            return Image.Tile;
        case "tileVertically":
            return Image.TileVertically;
        case "tileHorizontally":
            return Image.TileHorizontally;
        case "pad":
            return Image.Pad;
        case "preserveAspectFit":
        case "fit":
            return Image.PreserveAspectFit;
        default:
            return fallback;
        }
    }

    function horizontalAlignmentValue(value, fallback) {
        switch (String(value || "")) {
        case "left":
            return Image.AlignLeft;
        case "right":
            return Image.AlignRight;
        case "center":
            return Image.AlignHCenter;
        default:
            return fallback;
        }
    }

    function verticalAlignmentValue(value, fallback) {
        switch (String(value || "")) {
        case "top":
            return Image.AlignTop;
        case "bottom":
            return Image.AlignBottom;
        case "center":
            return Image.AlignVCenter;
        default:
            return fallback;
        }
    }
}
