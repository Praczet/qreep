import QtQuick

// One configured block: documents and folders as file rows, apps as icon
// tiles. Unknown types say so instead of vanishing. Keyboard selection comes
// from the detail pane (isFileSelected), clicks go through `activated`.
PlacesSection {
    id: rootPlacesBlock

    required property QtObject service
    required property QtObject detailPane
    required property var block
    property string iconFontFamily: ""

    signal activated(var item)

    title: block.title
    subtitle: block.type === "apps" || block.items.length === 0 ? "" : block.items.length + (block.items.length === 1 ? " item" : " items")
    shortcut: detailPane.shortcutFor(block.id)
    focused: detailPane.focusedCard === block.id

    // documents / folders
    Repeater {
        model: rootPlacesBlock.block.type === "apps" ? [] : rootPlacesBlock.block.items

        PlacesFileRow {
            required property var modelData
            required property int index

            pt: rootPlacesBlock.pt
            tag: modelData.kind === "folder" ? "󰉋" : rootPlacesBlock.fileGlyph(modelData.path)
            tagColor: rootPlacesBlock.pt.accentColor
            path: modelData.label
            selected: rootPlacesBlock.detailPane.isFileSelected(rootPlacesBlock.block.id, index)
            onSelectedChanged: {
                if (selected)
                    rootPlacesBlock.detailPane.ensureVisible(this);
            }
            onClicked: rootPlacesBlock.activated(modelData)
        }
    }

    // apps: icon above name, selected tile outlined like a file row.
    Flow {
        visible: rootPlacesBlock.block.type === "apps"
        width: parent.width
        spacing: 8

        Repeater {
            model: rootPlacesBlock.block.type === "apps" ? rootPlacesBlock.block.items : []

            Rectangle {
                id: appTile

                required property var modelData
                required property int index
                readonly property var entry: rootPlacesBlock.service.appEntry(modelData.id)
                readonly property bool selected: rootPlacesBlock.detailPane.isFileSelected(rootPlacesBlock.block.id, index)

                width: 92
                height: 84
                radius: rootPlacesBlock.pt.rowRadius
                color: selected ? rootPlacesBlock.pt.selectedRowColor : (tileMouse.containsMouse ? rootPlacesBlock.pt.hoveredRowColor : "transparent")
                border.width: selected ? 1 : 0
                border.color: rootPlacesBlock.pt.selectedBorderColor
                opacity: entry ? 1 : 0.5

                onSelectedChanged: {
                    if (selected)
                        rootPlacesBlock.detailPane.ensureVisible(this);
                }

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 10
                    width: 40
                    height: 40
                    sourceSize.width: 80
                    sourceSize.height: 80
                    source: rootPlacesBlock.service.appIcon(appTile.modelData.id)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Text {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 6
                    }
                    horizontalAlignment: Text.AlignHCenter
                    text: appTile.entry ? appTile.entry.name : appTile.modelData.id + " ?"
                    color: rootPlacesBlock.pt.primaryTextColor
                    font.pixelSize: rootPlacesBlock.pt.metaPixelSize + 1
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: tileMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootPlacesBlock.activated(appTile.modelData)
                }
            }
        }
    }

    Text {
        visible: rootPlacesBlock.block.items.length === 0
        width: parent.width
        text: ["documents", "folders", "apps"].indexOf(rootPlacesBlock.block.type) < 0 ? "Unknown block type \"" + rootPlacesBlock.block.type + "\" (not built yet, or a typo)." : "Nothing listed yet: add \"items\" in places.json."
        color: rootPlacesBlock.pt.secondaryTextColor
        font.pixelSize: rootPlacesBlock.pt.metaPixelSize + 1
        wrapMode: Text.Wrap
    }

    function fileGlyph(path) {
        const extension = String(path).replace(/^.*\./, "").toLowerCase();

        if (extension === "pdf")
            return "󰈦";
        if (["doc", "docx", "odt", "rtf"].indexOf(extension) >= 0)
            return "󰈬";
        if (["xls", "xlsx", "ods", "csv"].indexOf(extension) >= 0)
            return "󰈛";
        if (["png", "jpg", "jpeg", "svg", "webp", "gif"].indexOf(extension) >= 0)
            return "󰈟";
        if (extension === "md")
            return "󰍔";
        return "󰈙";
    }
}
