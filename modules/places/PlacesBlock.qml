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

    // Live for calendar and todos, the config list for the rest.
    readonly property var items: service.blockItems(block)
    readonly property bool listType: block.type === "documents" || block.type === "folders" || block.type === "folder"

    title: block.title
    subtitle: subtitleText()
    shortcut: detailPane.shortcutFor(block.id)
    focused: detailPane.focusedCard === block.id

    // documents / folders
    Repeater {
        model: rootPlacesBlock.listType ? rootPlacesBlock.items : []

        PlacesFileRow {
            required property var modelData
            required property int index

            pt: rootPlacesBlock.pt
            tag: modelData.kind === "folder" ? "󰉋" : rootPlacesBlock.fileGlyph(modelData.path)
            tagColor: rootPlacesBlock.pt.accentColor
            path: modelData.label
            trailing: modelData.time ? rootPlacesBlock.service.ago(modelData.time) : ""
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
            model: rootPlacesBlock.block.type === "apps" ? rootPlacesBlock.items : []

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

    // calendar: a day heading whenever the day changes, then time + title.
    Repeater {
        model: rootPlacesBlock.block.type === "calendar" ? rootPlacesBlock.items : []

        Column {
            id: eventItem

            required property var modelData
            required property int index
            readonly property bool newDay: index === 0 || rootPlacesBlock.items[index - 1].day !== modelData.day

            width: parent.width
            spacing: 2

            Text {
                visible: eventItem.newDay
                topPadding: eventItem.index === 0 ? 0 : 6
                text: eventItem.modelData.day
                color: rootPlacesBlock.pt.secondaryTextColor
                font.pixelSize: rootPlacesBlock.pt.metaPixelSize
                font.bold: true
            }

            PlacesFileRow {
                pt: rootPlacesBlock.pt
                tag: eventItem.modelData.allDay ? "󰃭" : "󰥔"
                tagColor: rootPlacesBlock.pt.accentColor
                path: eventItem.modelData.time + "  " + eventItem.modelData.title
                trailing: eventItem.modelData.location.length > 28 ? eventItem.modelData.location.slice(0, 27) + "…" : eventItem.modelData.location
                selected: rootPlacesBlock.detailPane.isFileSelected(rootPlacesBlock.block.id, eventItem.index)
                onSelectedChanged: {
                    if (selected)
                        rootPlacesBlock.detailPane.ensureVisible(this);
                }
                onClicked: rootPlacesBlock.activated(eventItem.modelData)
            }
        }
    }

    // todos: state tag, the task, and the page it lives on.
    Repeater {
        model: rootPlacesBlock.block.type === "todos" ? rootPlacesBlock.items : []

        PlacesFileRow {
            required property var modelData
            required property int index

            pt: rootPlacesBlock.pt
            tag: modelData.state === "NOW" || modelData.state === "DOING" ? "󰐊" : modelData.state === "LATER" || modelData.state === "WAITING" ? "󰔟" : "☐"
            tagColor: modelData.state === "NOW" || modelData.state === "DOING" ? rootPlacesBlock.pt.warningColor : modelData.state === "TODO" ? rootPlacesBlock.pt.accentColor : rootPlacesBlock.pt.secondaryTextColor
            path: modelData.text
            trailing: modelData.page
            selected: rootPlacesBlock.detailPane.isFileSelected(rootPlacesBlock.block.id, index)
            onSelectedChanged: {
                if (selected)
                    rootPlacesBlock.detailPane.ensureVisible(this);
            }
            onClicked: rootPlacesBlock.activated(modelData)
        }
    }

    Text {
        visible: rootPlacesBlock.items.length === 0
        width: parent.width
        text: rootPlacesBlock.emptyText()
        color: rootPlacesBlock.pt.secondaryTextColor
        font.pixelSize: rootPlacesBlock.pt.metaPixelSize + 1
        wrapMode: Text.Wrap
    }

    function subtitleText() {
        const count = items.length;

        if (block.type === "apps" || count === 0)
            return "";
        if (block.type === "calendar")
            return "next " + block.days + (block.days === 1 ? " day" : " days");
        if (block.type === "todos")
            return count + " open · Logseq";
        if (block.type === "folder")
            return service.shortPath(block.path) + (count >= block.limit ? " · first " + count : " · " + count);
        return count + (count === 1 ? " item" : " items");
    }

    function emptyText() {
        if (["documents", "folders", "folder", "apps", "calendar", "todos"].indexOf(block.type) < 0)
            return "Unknown block type \"" + block.type + "\" (not built yet, or a typo).";
        if (block.type === "calendar")
            return "Nothing on the calendar for the next " + block.days + (block.days === 1 ? " day." : " days.");
        if (block.type === "todos")
            return "No open todos. Either very productive or very forgetful.";
        if (block.type === "folder")
            return block.path ? "Empty, or not there: " + service.shortPath(block.path) : "A folder block needs \"path\".";
        return "Nothing listed yet: add \"items\" in places.json.";
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
