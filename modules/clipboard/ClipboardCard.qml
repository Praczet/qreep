import QtQuick
import QtQuick.Effects

Item {
    id: rootClipboardCard

    required property QtObject theme
    required property var entry
    property bool selected: false
    property color textColor: rootClipboardCard.selected ? rootClipboardCard.theme.modules.clipboard.headerSelectedTextColor : rootClipboardCard.theme.modules.clipboard.secondaryTextColor
    property bool hovered: hoverHandler.hovered
    property bool active: selected || hovered

    HoverHandler {
        id: hoverHandler
    }

    signal clicked
    signal starRequested
    signal deleteRequested

    width: rootClipboardCard.theme.modules.clipboard.cardWidth
    height: rootClipboardCard.theme.modules.clipboard.cardHeight

    transformOrigin: Item.Center
    scale: selected ? 1.15 : hovered ? 1.1 : 1.0
    z: selected ? 10 : hovered ? 5 : 0

    Behavior on scale {
        NumberAnimation {
            duration: rootClipboardCard.theme.modules.clipboard.animationDuration
            easing.type: Easing.OutCubic
        }
    }
    Rectangle {
        id: outerGlow

        anchors.fill: cardSurface
        radius: cardSurface.radius
        color: "transparent"

        visible: rootClipboardCard.selected || rootClipboardCard.hovered
        border.width: 1
        border.color: rootClipboardCard.selected ? rootClipboardCard.theme.modules.clipboard.cardGlowBorder : rootClipboardCard.theme.modules.clipboard.borderColor

        layer.enabled: visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            autoPaddingEnabled: true
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            shadowBlur: rootClipboardCard.selected ? 1.0 : 0.55
            shadowColor: rootClipboardCard.selected ? rootClipboardCard.theme.modules.clipboard.cardGlowOuter : Qt.rgba(rootClipboardCard.theme.modules.clipboard.accentColor.r, rootClipboardCard.theme.modules.clipboard.accentColor.g, rootClipboardCard.theme.modules.clipboard.accentColor.b, 0.22)
        }
    }

    Rectangle {
        id: bloomGlow

        anchors.fill: cardSurface
        radius: cardSurface.radius
        color: "transparent"

        visible: rootClipboardCard.selected
        border.width: 2
        border.color: rootClipboardCard.theme.modules.clipboard.cardGlowBorderStrong

        layer.enabled: visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            autoPaddingEnabled: true
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            shadowBlur: 0.45
            shadowColor: rootClipboardCard.theme.modules.clipboard.cardGlowBloom
        }
    }
    // Shadow-only layer. This item has no children, so the shadow is only the card shape,
    // not every Text/Button inside the card.
    Rectangle {
        id: shadowCaster

        anchors.fill: parent
        radius: rootClipboardCard.theme.modules.clipboard.cardRadius
        color: rootClipboardCard.active ? rootClipboardCard.theme.modules.clipboard.selectedCardColor : rootClipboardCard.theme.modules.clipboard.cardColor
        visible: false
        // visible: rootClipboardCard.active

        layer.enabled: rootClipboardCard.active
        layer.effect: MultiEffect {
            shadowEnabled: true
            autoPaddingEnabled: true
            shadowColor: "#99000000"
            shadowBlur: 0.7
            shadowVerticalOffset: 6
            shadowHorizontalOffset: 0
        }
    }

    Rectangle {
        id: cardSurface

        anchors.fill: parent
        radius: rootClipboardCard.theme.modules.clipboard.cardRadius
        color: rootClipboardCard.selected ? rootClipboardCard.theme.modules.clipboard.selectedCardColor : rootClipboardCard.theme.modules.clipboard.cardColor
        border.width: rootClipboardCard.theme.modules.clipboard.cardBorderWidth
        border.color: rootClipboardCard.selected ? rootClipboardCard.theme.modules.clipboard.selectedBorderColor : rootClipboardCard.theme.modules.clipboard.borderColor
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

        Rectangle {
            id: header

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: rootClipboardCard.theme.modules.clipboard.cardBorderWidth
            }

            height: rootClipboardCard.theme.modules.clipboard.headerHeight
            color: rootClipboardCard.selected ? rootClipboardCard.theme.modules.clipboard.headerBackgroundSelected : rootClipboardCard.theme.modules.clipboard.headerBackgroundColor
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
                    text: rootClipboardCard.entry.starred ? "󰐃" : "󰤰"
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

                readonly property int safeWidth: Math.max(0, width)
                readonly property int safeHeight: Math.max(0, height)

                columns: Math.max(0, Math.ceil(safeWidth / colorPreview.checkerSize))
                rows: Math.max(0, Math.ceil(safeHeight / colorPreview.checkerSize))

                Repeater {
                    model: Math.max(0, checkerLayer.columns * checkerLayer.rows)

                    Rectangle {
                        width: colorPreview.checkerSize
                        height: colorPreview.checkerSize

                        readonly property int col: checkerLayer.columns > 0 ? index % checkerLayer.columns : 0

                        readonly property int row: checkerLayer.columns > 0 ? Math.floor(index / checkerLayer.columns) : 0

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

        Rectangle {
            id: imagePreview

            visible: rootClipboardCard.entry.type === "image"

            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                bottom: footer.top
                margins: rootClipboardCard.theme.modules.clipboard.cardPadding
            }

            radius: 4
            color: rootClipboardCard.theme.modules.clipboard.searchColor
            border.width: 1
            border.color: rootClipboardCard.theme.modules.clipboard.borderColor
            clip: true

            Image {
                id: clipboardImage

                anchors.fill: parent
                source: rootClipboardCard.entry.imageSource || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                smooth: true
                mipmap: true
                visible: rootClipboardCard.entry.imageReady && status === Image.Ready
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 22
                color: Qt.rgba(rootClipboardCard.theme.modules.clipboard.panelColor.r, rootClipboardCard.theme.modules.clipboard.panelColor.g, rootClipboardCard.theme.modules.clipboard.panelColor.b, 0.78)
                visible: clipboardImage.visible

                Text {
                    anchors {
                        fill: parent
                        leftMargin: 6
                        rightMargin: 6
                    }
                    text: imageMetaText()
                    color: rootClipboardCard.theme.modules.clipboard.primaryTextColor
                    font.pixelSize: rootClipboardCard.theme.modules.clipboard.metaPixelSize
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - 16
                text: rootClipboardCard.entry.imageReady ? "image failed" : imageMetaText()
                color: rootClipboardCard.theme.modules.clipboard.secondaryTextColor
                font.pixelSize: rootClipboardCard.theme.modules.clipboard.bodyPixelSize
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: !clipboardImage.visible
            }
        }

        Text {
            visible: rootClipboardCard.entry.type !== "color" && rootClipboardCard.entry.type !== "image"
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

    function imageMetaText() {
        const parts = [];

        if (rootClipboardCard.entry.imageDimensions && rootClipboardCard.entry.imageDimensions.length > 0)
            parts.push(rootClipboardCard.entry.imageDimensions);

        if (rootClipboardCard.entry.imageMimeType && rootClipboardCard.entry.imageMimeType.length > 0)
            parts.push(rootClipboardCard.entry.imageMimeType.replace("image/", ""));

        return parts.length > 0 ? parts.join(" · ") : rootClipboardCard.entry.preview;
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
