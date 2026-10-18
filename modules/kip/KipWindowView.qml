import QtQuick
import Quickshell.Wayland

// /win body: toolbar (icons/previews, grid/list) over one GridView. List mode
// is the same GridView with one column, so navigation has one shape.
// Previews are live ScreencopyView captures of the matched Toplevel, fitted
// to the window's own aspect; an unmatched window gets its icon, not a guess.
Column {
    id: rootKipWindowView

    required property QtObject kipTheme
    required property QtObject windows
    property int selectedIndex: 0
    property real maxHeight: 400

    signal activated(int index)

    readonly property bool gridMode: windows.view === "grid"
    readonly property bool previewMode: windows.display === "preview"
    readonly property int columns: gridMode ? kipTheme.windowGridColumns : 1
    readonly property real cellHeight: gridMode ? (previewMode ? kipTheme.windowGridPreviewCellHeight : kipTheme.windowGridIconCellHeight) : (previewMode ? kipTheme.windowListPreviewRowHeight : kipTheme.windowListIconRowHeight)

    spacing: 6

    // Grid: Left/Right walk, Up/Down jump a row. List: Up/Down only.
    function neighbor(index, dx, dy) {
        const count = windows.results.length;

        if (count === 0)
            return 0;

        const next = index + dx + dy * columns;

        return next < 0 || next >= count ? index : next;
    }

    Item {
        width: parent.width
        height: 24

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - switches.width - 12
            text: rootKipWindowView.windows.status === "loading" ? "reading hyprctl clients" : rootKipWindowView.windows.status === "error" ? rootKipWindowView.windows.errorText : rootKipWindowView.windows.results.length + " of " + rootKipWindowView.windows.clients.length + " windows"
            color: rootKipWindowView.windows.status === "error" ? rootKipWindowView.kipTheme.errorColor : rootKipWindowView.kipTheme.tertiaryAccentColor
            font.pixelSize: rootKipWindowView.kipTheme.metaPixelSize
            elide: Text.ElideRight
        }

        Row {
            id: switches

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            SwitchChip {
                group: "display"
                value: "icon"
                label: "Icons"
            }

            SwitchChip {
                group: "display"
                value: "preview"
                label: "Previews"
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 14
                color: rootKipWindowView.kipTheme.borderColor
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

    // Same chip as the app view toolbar; group is the KipWindowService property it sets.
    component SwitchChip: Rectangle {
        id: chip

        required property string group
        required property string value
        required property string label

        readonly property bool active: rootKipWindowView.windows[group] === value

        width: chipLabel.implicitWidth + 16
        height: 22
        radius: 11
        color: active ? rootKipWindowView.kipTheme.commandHighlightColor : (chipMouse.containsMouse ? rootKipWindowView.kipTheme.hoveredRowColor : "transparent")
        border.width: active ? 1 : 0
        border.color: rootKipWindowView.kipTheme.focusBorderColor

        Text {
            id: chipLabel

            anchors.centerIn: parent
            text: chip.label
            color: chip.active ? rootKipWindowView.kipTheme.primaryTextColor : rootKipWindowView.kipTheme.secondaryTextColor
            font.pixelSize: rootKipWindowView.kipTheme.metaPixelSize + 1
        }

        MouseArea {
            id: chipMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: rootKipWindowView.windows[chip.group] = chip.value
        }
    }

    GridView {
        id: windowGrid

        width: parent.width
        height: Math.min(contentHeight, rootKipWindowView.maxHeight - 30)
        model: rootKipWindowView.windows.results
        cellWidth: width / rootKipWindowView.columns
        cellHeight: rootKipWindowView.cellHeight
        currentIndex: rootKipWindowView.selectedIndex
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        highlightFollowsCurrentItem: false

        onCurrentIndexChanged: {
            if (currentIndex >= 0)
                positionViewAtIndex(currentIndex, GridView.Contain);
        }

        delegate: Item {
            id: cell

            required property var modelData
            required property int index

            readonly property bool selected: index === rootKipWindowView.selectedIndex
            readonly property bool showPreview: rootKipWindowView.previewMode && modelData.previewSource !== null && modelData.previewSource !== undefined

            width: windowGrid.cellWidth
            height: windowGrid.cellHeight

            Rectangle {
                id: card

                anchors.fill: parent
                anchors.margins: 3
                radius: rootKipWindowView.kipTheme.rowRadius
                color: cell.selected ? rootKipWindowView.kipTheme.selectedRowColor : (cellMouse.containsMouse ? rootKipWindowView.kipTheme.hoveredRowColor : "transparent")
                border.width: cell.selected ? 1 : 0
                border.color: rootKipWindowView.kipTheme.focusBorderColor

                // Picture area: above the caption in grid, left of it in list.
                Rectangle {
                    id: visual

                    readonly property bool boxed: rootKipWindowView.previewMode

                    x: 8
                    y: rootKipWindowView.gridMode ? 8 : (parent.height - height) / 2
                    width: rootKipWindowView.gridMode ? parent.width - 16 : (boxed ? rootKipWindowView.kipTheme.windowListPreviewWidth : rootKipWindowView.kipTheme.windowListIconSize)
                    height: rootKipWindowView.gridMode ? parent.height - rootKipWindowView.kipTheme.windowCaptionHeight - 8 : (boxed ? parent.height - 12 : width)
                    radius: rootKipWindowView.kipTheme.chipRadius
                    color: boxed ? rootKipWindowView.kipTheme.chipColor : "transparent"
                    clip: true

                    ScreencopyView {
                        // Fit the window's own aspect inside the box instead of stretching it.
                        readonly property real fit: Math.min(visual.width / Math.max(1, cell.modelData.width), visual.height / Math.max(1, cell.modelData.height))

                        anchors.centerIn: parent
                        width: cell.modelData.width > 0 ? cell.modelData.width * fit : visual.width
                        height: cell.modelData.height > 0 ? cell.modelData.height * fit : visual.height
                        visible: cell.showPreview
                        captureSource: cell.showPreview ? cell.modelData.previewSource : null
                        live: cell.showPreview && rootKipWindowView.visible
                        paintCursor: false
                        constraintSize: Qt.size(width, height)
                    }

                    Image {
                        readonly property int size: rootKipWindowView.gridMode ? rootKipWindowView.kipTheme.windowGridIconSize : rootKipWindowView.kipTheme.windowListIconSize

                        anchors.centerIn: parent
                        visible: !cell.showPreview
                        width: Math.min(size, visual.height - 8)
                        height: width
                        source: cell.modelData.iconSource
                        sourceSize.width: width * 2
                        sourceSize.height: height * 2
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                    }
                }

                Column {
                    anchors {
                        left: rootKipWindowView.gridMode ? parent.left : visual.right
                        right: parent.right
                        top: rootKipWindowView.gridMode ? visual.bottom : undefined
                        verticalCenter: rootKipWindowView.gridMode ? undefined : parent.verticalCenter
                        leftMargin: rootKipWindowView.gridMode ? 10 : 12
                        rightMargin: 10
                        topMargin: 6
                    }
                    spacing: 2

                    Row {
                        width: parent.width
                        spacing: 6

                        // Small app icon next to the title when the picture is a preview.
                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: cell.showPreview
                            width: visible ? 16 : 0
                            height: 16
                            source: cell.modelData.iconSource
                            sourceSize.width: 32
                            sourceSize.height: 32
                            asynchronous: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - x
                            text: cell.modelData.title.length > 0 ? cell.modelData.title : "(untitled)"
                            color: rootKipWindowView.kipTheme.primaryTextColor
                            font.pixelSize: rootKipWindowView.kipTheme.bodyPixelSize
                            font.bold: cell.selected
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        width: parent.width
                        text: cell.modelData.appLabel + " · ws " + cell.modelData.workspaceName + (cell.modelData.focused ? " · focused" : "")
                        color: rootKipWindowView.kipTheme.secondaryTextColor
                        font.pixelSize: rootKipWindowView.kipTheme.metaPixelSize
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: cellMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: rootKipWindowView.activated(cell.index)
                }
            }
        }
    }
}
