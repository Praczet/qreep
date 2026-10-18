import QtQuick

// App launcher body: a toolbar (group by / view) over sectioned tiles.
// Tiles are positioned by hand from one layout pass, so section headers,
// arrow keys and scroll-into-view all read the same geometry instead of
// asking nested GridViews where things ended up.
Column {
    id: rootKipAppView

    required property QtObject kipTheme
    required property QtObject apps
    required property string iconFontFamily
    // [{ title, apps }] from KipAppService.sections()
    required property var sections
    required property bool searching
    property int selectedIndex: 0
    property real maxHeight: 400

    signal activated(int index)

    readonly property bool gridMode: apps.view === "grid"
    readonly property int columns: gridMode ? kipTheme.appGridColumns : kipTheme.appListColumns
    readonly property real cellWidth: width / columns
    readonly property real cellHeight: gridMode ? kipTheme.appGridCellHeight : kipTheme.appListRowHeight
    readonly property real headerHeight: kipTheme.appSectionHeaderHeight

    // { headers: [{ title, y }], tiles: [{ entry, x, y, row, col }], height }
    readonly property var layout: {
        const headers = [];
        const tiles = [];
        let y = 0;
        let row = 0;

        for (const section of sections) {
            headers.push({
                title: section.title,
                y: y
            });
            y += headerHeight;

            for (let index = 0; index < section.apps.length; index++) {
                const col = index % columns;

                if (index > 0 && col === 0) {
                    y += cellHeight;
                    row++;
                }
                tiles.push({
                    entry: section.apps[index],
                    x: col * cellWidth,
                    y: y,
                    row: row,
                    col: col
                });
            }
            y += cellHeight;
            row++;
        }

        return {
            headers: headers,
            tiles: tiles,
            height: y
        };
    }
    readonly property int count: layout.tiles.length
    readonly property var selectedEntry: count > 0 ? layout.tiles[Math.min(selectedIndex, count - 1)].entry : null

    spacing: 6

    onSelectedIndexChanged: ensureVisible()

    // Spatial move: Left/Right walk the flat order, Up/Down jump to the row
    // above or below and keep the column, or the nearest one that exists.
    function neighbor(index, dx, dy) {
        const tiles = layout.tiles;

        if (tiles.length === 0)
            return 0;

        const current = tiles[Math.max(0, Math.min(index, tiles.length - 1))];

        if (dx !== 0)
            return Math.max(0, Math.min(tiles.length - 1, index + dx));

        const wantedRow = current.row + dy;
        let best = -1;

        for (let candidate = 0; candidate < tiles.length; candidate++) {
            if (tiles[candidate].row !== wantedRow)
                continue;
            if (best < 0 || Math.abs(tiles[candidate].col - current.col) < Math.abs(tiles[best].col - current.col))
                best = candidate;
        }
        return best < 0 ? index : best;
    }

    function ensureVisible() {
        if (count === 0)
            return;

        const tile = layout.tiles[Math.min(selectedIndex, count - 1)];
        // Keep the section header in view when its first row is selected.
        const top = tile.y - (tile.col === 0 && tile.y - headerHeight >= 0 ? headerHeight : 0);

        if (top < tileFlick.contentY)
            tileFlick.contentY = Math.max(0, top);
        else if (tile.y + cellHeight > tileFlick.contentY + tileFlick.height)
            tileFlick.contentY = tile.y + cellHeight - tileFlick.height;
    }

    // Toolbar: what you are looking at, and the two switches.
    Item {
        width: parent.width
        height: 24

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: rootKipAppView.searching ? "searching all " + rootKipAppView.apps.apps.length + " apps" : rootKipAppView.apps.apps.length + " apps" + (rootKipAppView.apps.errorText.length > 0 ? " · launch log: " + rootKipAppView.apps.errorText : "")
            color: rootKipAppView.apps.errorText.length > 0 ? rootKipAppView.kipTheme.warningColor : rootKipAppView.kipTheme.tertiaryAccentColor
            font.pixelSize: rootKipAppView.kipTheme.metaPixelSize
            elide: Text.ElideRight
            width: parent.width - switches.width - 12
        }

        Row {
            id: switches

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            SwitchChip {
                group: "grouping"
                value: "category"
                label: "Category"
            }

            SwitchChip {
                group: "grouping"
                value: "name"
                label: "Name"
            }

            SwitchChip {
                group: "grouping"
                value: "letter"
                label: "A–Z"
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 14
                color: rootKipAppView.kipTheme.borderColor
            }

            SwitchChip {
                group: "view"
                value: "grid"
                label: "Grid"
            }

            SwitchChip {
                group: "view"
                value: "list"
                label: "List"
            }
        }
    }

    // One toolbar switch. group is the KipAppService property it sets.
    component SwitchChip: Rectangle {
        id: chip

        required property string group
        required property string value
        required property string label

        readonly property bool active: rootKipAppView.apps[group] === value
        // Grouping means nothing while a query ranks everything.
        readonly property bool muted: group === "grouping" && rootKipAppView.searching

        width: chipLabel.implicitWidth + 16
        height: 22
        radius: 11
        color: active ? rootKipAppView.kipTheme.commandHighlightColor : (chipMouse.containsMouse ? rootKipAppView.kipTheme.hoveredRowColor : "transparent")
        border.width: active ? 1 : 0
        border.color: rootKipAppView.kipTheme.focusBorderColor
        opacity: muted ? 0.45 : 1

        Text {
            id: chipLabel

            anchors.centerIn: parent
            text: chip.label
            color: chip.active ? rootKipAppView.kipTheme.primaryTextColor : rootKipAppView.kipTheme.secondaryTextColor
            font.pixelSize: rootKipAppView.kipTheme.metaPixelSize + 1
        }

        MouseArea {
            id: chipMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: rootKipAppView.apps[chip.group] = chip.value
        }
    }

    Flickable {
        id: tileFlick

        width: parent.width
        height: Math.min(rootKipAppView.layout.height, rootKipAppView.maxHeight - 30)
        contentHeight: rootKipAppView.layout.height
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Repeater {
            model: rootKipAppView.layout.headers

            Text {
                required property var modelData

                x: 6
                y: modelData.y
                height: rootKipAppView.headerHeight
                verticalAlignment: Text.AlignVCenter
                text: modelData.title
                color: rootKipAppView.kipTheme.tertiaryAccentColor
                font.pixelSize: rootKipAppView.kipTheme.metaPixelSize + 1
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 0.6
            }
        }

        Repeater {
            model: rootKipAppView.layout.tiles

            Rectangle {
                id: tile

                required property var modelData
                required property int index

                readonly property bool selected: index === rootKipAppView.selectedIndex

                x: modelData.x + 3
                y: modelData.y + 3
                width: rootKipAppView.cellWidth - 6
                height: rootKipAppView.cellHeight - 6
                radius: rootKipAppView.kipTheme.rowRadius
                color: selected ? rootKipAppView.kipTheme.selectedRowColor : (tileMouse.containsMouse ? rootKipAppView.kipTheme.hoveredRowColor : "transparent")
                border.width: selected ? 1 : 0
                border.color: rootKipAppView.kipTheme.focusBorderColor

                Image {
                    id: tileIcon

                    x: rootKipAppView.gridMode ? (parent.width - width) / 2 : 10
                    y: rootKipAppView.gridMode ? 10 : (parent.height - height) / 2
                    width: rootKipAppView.gridMode ? rootKipAppView.kipTheme.appGridIconSize : rootKipAppView.kipTheme.appListIconSize
                    height: width
                    source: rootKipAppView.apps.iconSource(tile.modelData.entry)
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                }

                Text {
                    visible: rootKipAppView.gridMode
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: tileIcon.bottom
                        topMargin: 6
                        leftMargin: 6
                        rightMargin: 6
                    }
                    text: tile.modelData.entry.name
                    color: rootKipAppView.kipTheme.primaryTextColor
                    font.pixelSize: rootKipAppView.kipTheme.bodyPixelSize - 1
                    font.bold: tile.selected
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Column {
                    visible: !rootKipAppView.gridMode
                    anchors {
                        left: tileIcon.right
                        leftMargin: 10
                        right: parent.right
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }

                    Text {
                        width: parent.width
                        text: tile.modelData.entry.name
                        color: rootKipAppView.kipTheme.primaryTextColor
                        font.pixelSize: rootKipAppView.kipTheme.bodyPixelSize
                        font.bold: tile.selected
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: text.length > 0
                        text: tile.modelData.entry.genericName || tile.modelData.entry.comment || ""
                        color: rootKipAppView.kipTheme.secondaryTextColor
                        font.pixelSize: rootKipAppView.kipTheme.metaPixelSize
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: tileMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: rootKipAppView.activated(tile.index)
                }
            }
        }
    }
}
