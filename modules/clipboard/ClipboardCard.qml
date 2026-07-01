import QtQuick
import QtQuick.Effects

Rectangle {
    id: rootClipboardCard

    required property QtObject theme
    required property var entry
    property bool selected: false
    property color textColor: selected ? rootClipboardCard.theme.modules.clipboard.headerSelectedTextColor : rootClipboardCard.theme.modules.clipboard.secondaryTextColor
    // property color textColor: selected ? rootClipboardCard.theme.modules.clipboard.qreep.error : rootClipboardCard.theme.modules.clipboard.secondaryTextColor

    signal clicked
    signal starRequested
    signal deleteRequested
    layer.enabled: true

    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#99000000"
        shadowBlur: rootClipboardCard.selected ? 0.7 : 0.25
        shadowVerticalOffset: rootClipboardCard.selected ? 6 : 2
        shadowHorizontalOffset: 0
    }

    transformOrigin: Item.Center
    scale: selected ? 1.2 : 1.0
    z: selected ? 10 : 0

    width: rootClipboardCard.theme.modules.clipboard.cardWidth
    height: rootClipboardCard.theme.modules.clipboard.cardHeight
    radius: rootClipboardCard.theme.modules.clipboard.cardRadius
    color: selected ? rootClipboardCard.theme.modules.clipboard.selectedCardColor : rootClipboardCard.theme.modules.clipboard.cardColor
    border.width: rootClipboardCard.theme.modules.clipboard.cardBorderWidth
    border.color: selected ? rootClipboardCard.theme.modules.clipboard.selectedBorderColor : rootClipboardCard.theme.modules.clipboard.borderColor
    clip: true

    Behavior on color {
        ColorAnimation {
            duration: rootClipboardCard.theme.modules.clipboard.animationDuration
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: rootClipboardCard.theme.modules.clipboard.animationDuration
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: rootClipboardCard.clicked()
    }
    Behavior on scale {
        NumberAnimation {
            duration: rootClipboardCard.theme.modules.clipboard.animationDuration
            easing.type: Easing.OutCubic
        }
    }
    Rectangle {
        id: header

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: rootClipboardCard.theme.modules.clipboard.cardBorderWidth
        }

        height: rootClipboardCard.theme.modules.clipboard.headerHeight
        color: selected ? rootClipboardCard.theme.modules.clipboard.headerBackgroundSelected : rootClipboardCard.theme.modules.clipboard.headerBackgroundColor
        topRightRadius: rootClipboardCard.theme.modules.clipboard.cardRadius
        topLeftRadius: rootClipboardCard.theme.modules.clipboard.cardRadius

        Row {
            id: headerRow

            anchors.fill: parent
            spacing: 6

            Text {
                width: 16
                height: parent.height
                text: iconForType(rootClipboardCard.entry.type)
                color: rootClipboardCard.textColor
                font.pixelSize: rootClipboardCard.theme.modules.clipboard.typePixelSize
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width - 16 - starButton.width - deleteButton.width - parent.spacing * 3
                height: parent.height
                text: rootClipboardCard.entry.type
                color: rootClipboardCard.textColor
                font.pixelSize: rootClipboardCard.theme.modules.clipboard.typePixelSize
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Text {
                id: starButton

                width: rootClipboardCard.theme.modules.clipboard.iconButtonSize
                height: parent.height
                text: rootClipboardCard.entry.starred ? "" : ""
                color: rootClipboardCard.textColor
                font.pixelSize: rootClipboardCard.theme.modules.clipboard.typePixelSize + 2
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => {
                        mouse.accepted = true;
                        rootClipboardCard.starRequested();
                    }
                }
            }

            Text {
                id: deleteButton

                width: rootClipboardCard.theme.modules.clipboard.iconButtonSize
                height: parent.height
                text: ""
                color: rootClipboardCard.textColor
                font.pixelSize: rootClipboardCard.theme.modules.clipboard.typePixelSize
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => {
                        mouse.accepted = true;
                        rootClipboardCard.deleteRequested();
                    }
                }
            }
        }
    }

    Rectangle {
        id: colorPreview

        visible: rootClipboardCard.entry.type === "color"

        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: footer.top
            margins: rootClipboardCard.theme.modules.clipboard.cardPadding
        }

        color: "transparent"
        clip: true

        property int checkerSize: 8

        // Back checker layer
        Grid {
            id: checkerLayer

            anchors.fill: parent
            columns: Math.ceil(width / colorPreview.checkerSize)
            rows: Math.ceil(height / colorPreview.checkerSize)

            Repeater {
                model: checkerLayer.columns * checkerLayer.rows

                Rectangle {
                    width: colorPreview.checkerSize
                    height: colorPreview.checkerSize

                    readonly property int col: index % checkerLayer.columns
                    readonly property int row: Math.floor(index / checkerLayer.columns)

                    color: (row + col) % 2 === 0 ? "#d0d0d0" : "#f2f2f2"
                }
            }
        }

        // Actual copied color layer
        Rectangle {
            anchors.fill: parent
            color: rootClipboardCard.entry.color
        }

        // Text layer
        Text {
            anchors.centerIn: parent
            text: rootClipboardCard.entry.preview
            color: readableTextColor(rootClipboardCard.entry.color)
            font.pixelSize: rootClipboardCard.theme.modules.clipboard.bodyPixelSize * 1.25
        }

        // Border on top
        Rectangle {
            anchors.fill: parent
            radius: colorPreview.radius
            color: "transparent"
            border.width: 1
            border.color: rootClipboardCard.theme.modules.clipboard.borderColor
        }
    }

    Text {
        visible: rootClipboardCard.entry.type !== "color"
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: footer.top
            margins: rootClipboardCard.theme.modules.clipboard.cardPadding
        }
        text: rootClipboardCard.entry.preview
        color: rootClipboardCard.theme.modules.clipboard.primaryTextColor
        font.family: rootClipboardCard.entry.type === "code" ? "monospace" : "sans-serif"
        font.pixelSize: rootClipboardCard.theme.modules.clipboard.bodyPixelSize
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        maximumLineCount: 6
    }

    Text {
        id: footer

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: rootClipboardCard.theme.modules.clipboard.cardPadding
        }
        height: 12
        text: rootClipboardCard.entry.id
        color: rootClipboardCard.theme.modules.clipboard.secondaryTextColor
        font.pixelSize: rootClipboardCard.theme.modules.clipboard.metaPixelSize
        elide: Text.ElideRight
    }

    function iconForType(type) {
        if (type === "image")
            return "󰋩";
        if (type === "code")
            return "󰅩";
        if (type === "color")
            return "";

        return "󰉿";
    }
    function srgbToLinear(value) {
        return value <= 0.03928 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
    }

    function relativeLuminance(color) {
        const r = srgbToLinear(color.r);
        const g = srgbToLinear(color.g);
        const b = srgbToLinear(color.b);

        return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }

    function contrastRatio(colorA, colorB) {
        const l1 = relativeLuminance(colorA);
        const l2 = relativeLuminance(colorB);

        const lighter = Math.max(l1, l2);
        const darker = Math.min(l1, l2);

        return (lighter + 0.05) / (darker + 0.05);
    }

    function readableTextColor(backgroundColor) {
        const white = Qt.rgba(1, 1, 1, 1);
        const black = Qt.rgba(0, 0, 0, 1);

        return contrastRatio(backgroundColor, white) >= contrastRatio(backgroundColor, black) ? white : black;
    }
}
