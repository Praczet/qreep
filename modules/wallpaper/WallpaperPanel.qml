import QtQuick
import Quickshell
import Quickshell.Wayland

// Wallpaper overlay: dimmed backdrop, one centered card with search and the
// view switches on top, the wallpapers as a grid (S/M/L/XL) or a list, and a
// preview pane where the tiles are too small to judge (list, S, M).
PanelWindow {
    id: rootWallpaperPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    readonly property QtObject wt: theme.modules.wallpaper
    readonly property var items: service.filtered
    readonly property bool gridView: service.view === "grid"
    readonly property var tile: wt.sizes[service.size] || wt.sizes.m
    readonly property bool showPreview: !gridView || wt.previewSizes.indexOf(service.size) >= 0
    property int index: 0
    readonly property var selected: items.length > 0 ? items[Math.max(0, Math.min(index, items.length - 1))] : null
    property bool presented: false
    // Select the current wallpaper once per open, as soon as both the list
    // and current-wallpaper are in (either can arrive first). Moving,
    // typing or clicking first wins.
    property bool needsInitialSelection: true

    signal closeRequested
    signal applyRequested(var item)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "qreep-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: panelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Component.onCompleted: {
        search.forceActiveFocus();
        if (panelOpen)
            enterTimer.restart();
        selectCurrent();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            needsInitialSelection = true;
            search.forceActiveFocus();
            enterTimer.restart();
            selectCurrent();
            return;
        }
        enterTimer.stop();
        presented = false;
    }

    onItemsChanged: {
        if (needsInitialSelection)
            selectCurrent();
        else
            index = Math.min(index, Math.max(0, items.length - 1));
    }

    onIndexChanged: revealSelected()
    onSelectedChanged: service.selectedName = selected ? selected.name : ""

    onGridViewChanged: revealSelectedLater.restart()

    Connections {
        target: rootWallpaperPanel.service

        function onSizeChanged() {
            revealSelectedLater.restart();
        }

        function onCurrentChanged() {
            if (rootWallpaperPanel.needsInitialSelection)
                rootWallpaperPanel.selectCurrent();
        }
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: rootWallpaperPanel.presented = true
    }

    // After opening or a view / size switch the layout needs a few frames
    // (delegates, cell sizes) before scrolling to the selection lands right.
    Timer {
        id: revealSelectedLater

        interval: 60
        repeat: false
        onTriggered: rootWallpaperPanel.revealSelected()
    }

    function selectCurrent() {
        const found = items.findIndex(item => service.isCurrent(item));

        if (found < 0)
            return;
        index = found;
        needsInitialSelection = false;
        revealSelectedLater.restart();
    }

    function revealSelected() {
        if (gridView)
            grid.positionViewAtIndex(index, GridView.Contain);
        else
            list.positionViewAtIndex(index, ListView.Contain);
    }

    function columns() {
        return Math.max(1, Math.floor(grid.width / grid.cellWidth));
    }

    function move(step) {
        needsInitialSelection = false;
        if (items.length > 0)
            index = Math.max(0, Math.min(items.length - 1, index + step));
    }

    function pageRows() {
        return gridView ? Math.max(1, Math.floor(grid.height / grid.cellHeight)) * columns() : Math.max(1, Math.floor(list.height / wt.listRowHeight));
    }

    function handleKey(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;

        switch (event.key) {
        case Qt.Key_Escape:
            event.accepted = true;
            if (!ctrl && search.text.length > 0) {
                search.text = "";
                service.setQuery("");
                index = 0;
            } else {
                closeRequested();
            }
            return;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            event.accepted = true;
            if (selected)
                applyRequested(selected);
            return;
        case Qt.Key_Up:
            event.accepted = true;
            move(gridView ? -columns() : -1);
            return;
        case Qt.Key_Down:
            event.accepted = true;
            move(gridView ? columns() : 1);
            return;
        case Qt.Key_Left:
        case Qt.Key_Right:
            // Grid only; in the list the cursor keeps them.
            if (gridView) {
                event.accepted = true;
                move(event.key === Qt.Key_Right ? 1 : -1);
            }
            return;
        case Qt.Key_PageUp:
        case Qt.Key_PageDown:
            event.accepted = true;
            move((event.key === Qt.Key_PageDown ? 1 : -1) * pageRows());
            return;
        case Qt.Key_L:
            if (ctrl) {
                event.accepted = true;
                service.setView(gridView ? "list" : "grid");
            }
            return;
        case Qt.Key_Equal:
        case Qt.Key_Plus:
        case Qt.Key_Minus:
            if (ctrl) {
                event.accepted = true;
                service.setView("grid");
                service.stepSize(event.key === Qt.Key_Minus ? -1 : 1);
            }
            return;
        }
    }

    function hints() {
        const keys = gridView ? "↑↓←→ move" : "↑↓ move";

        return keys + " · Enter apply (Unclaimed Bloom) · Ctrl+L " + (gridView ? "list" : "grid") + " · Ctrl+= / Ctrl+− size · type to filter · Esc " + (search.text.length > 0 ? "clear" : "close");
    }

    Rectangle {
        anchors.fill: parent
        color: rootWallpaperPanel.wt.overlayColor
        opacity: rootWallpaperPanel.presented ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: rootWallpaperPanel.wt.animationDuration
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rootWallpaperPanel.closeRequested()
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        anchors.verticalCenterOffset: rootWallpaperPanel.presented ? 0 : 24
        width: rootWallpaperPanel.wt.panelWidthFor(parent.width, parent.height)
        height: rootWallpaperPanel.wt.panelHeightFor(parent.width, parent.height)
        radius: rootWallpaperPanel.wt.panelRadius
        color: rootWallpaperPanel.wt.panelColor
        border.width: 1
        border.color: rootWallpaperPanel.wt.borderColor
        opacity: rootWallpaperPanel.presented ? 1 : 0
        scale: rootWallpaperPanel.presented ? 1 : 0.98
        clip: true

        Behavior on opacity {
            NumberAnimation {
                duration: rootWallpaperPanel.wt.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: rootWallpaperPanel.wt.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: rootWallpaperPanel.wt.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        // Swallow clicks so only the backdrop closes.
        MouseArea {
            anchors.fill: parent
        }

        // --- search + view switches --------------------------------------------
        Rectangle {
            id: searchBox

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: rootWallpaperPanel.wt.panelPadding
            }
            height: rootWallpaperPanel.wt.searchHeight
            radius: height / 2
            color: rootWallpaperPanel.wt.searchColor
            border.width: search.activeFocus ? 1 : 0
            border.color: rootWallpaperPanel.wt.selectedBorderColor

            Text {
                id: searchIcon

                anchors {
                    left: parent.left
                    leftMargin: 18
                    verticalCenter: parent.verticalCenter
                }
                text: "󰸉"
                color: rootWallpaperPanel.wt.accentColor
                font.family: rootWallpaperPanel.theme.iconFontFamily
                font.pixelSize: 20
            }

            Text {
                id: searchLabel

                anchors {
                    left: searchIcon.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                text: "Wallpaper"
                color: rootWallpaperPanel.wt.accentColor
                font.pixelSize: rootWallpaperPanel.wt.searchPixelSize
                font.bold: true
            }

            TextInput {
                id: search

                anchors {
                    left: searchLabel.right
                    leftMargin: 14
                    right: switches.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                color: rootWallpaperPanel.wt.primaryTextColor
                selectionColor: rootWallpaperPanel.wt.selectedColor
                font.pixelSize: rootWallpaperPanel.wt.searchPixelSize
                text: rootWallpaperPanel.service.query
                clip: true

                onTextEdited: {
                    rootWallpaperPanel.needsInitialSelection = false;
                    rootWallpaperPanel.service.setQuery(text);
                    rootWallpaperPanel.index = 0;
                }
                Keys.onPressed: event => rootWallpaperPanel.handleKey(event)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text.length === 0
                    text: "type to filter by name"
                    color: rootWallpaperPanel.wt.secondaryTextColor
                    font.pixelSize: rootWallpaperPanel.wt.searchPixelSize
                }
            }

            Row {
                id: switches

                anchors {
                    right: parent.right
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    rightPadding: 8
                    text: rootWallpaperPanel.items.length === rootWallpaperPanel.service.wallpapers.length ? rootWallpaperPanel.items.length + " wallpapers" : rootWallpaperPanel.items.length + " of " + rootWallpaperPanel.service.wallpapers.length
                    color: rootWallpaperPanel.wt.secondaryTextColor
                    font.pixelSize: rootWallpaperPanel.wt.metaPixelSize
                }

                Repeater {
                    model: [
                        { key: "grid", label: "󰕰 Grid" },
                        { key: "list", label: "󰉹 List" }
                    ]

                    WallpaperChip {
                        required property var modelData

                        wt: rootWallpaperPanel.wt
                        iconFont: rootWallpaperPanel.theme.iconFontFamily
                        label: modelData.label
                        active: rootWallpaperPanel.service.view === modelData.key
                        onClicked: rootWallpaperPanel.service.setView(modelData.key)
                    }
                }

                Item {
                    width: 6
                    height: 1
                }

                Repeater {
                    model: rootWallpaperPanel.wt.sizeOrder

                    WallpaperChip {
                        required property string modelData

                        wt: rootWallpaperPanel.wt
                        iconFont: rootWallpaperPanel.theme.iconFontFamily
                        label: rootWallpaperPanel.wt.sizes[modelData].label
                        active: rootWallpaperPanel.gridView && rootWallpaperPanel.service.size === modelData
                        dimmed: !rootWallpaperPanel.gridView
                        onClicked: {
                            rootWallpaperPanel.service.setView("grid");
                            rootWallpaperPanel.service.size = modelData;
                            rootWallpaperPanel.service.saveState();
                        }
                    }
                }
            }
        }

        // --- browser + preview -------------------------------------------------
        Item {
            id: body

            anchors {
                left: parent.left
                right: parent.right
                top: searchBox.bottom
                bottom: footer.top
                margins: rootWallpaperPanel.wt.panelPadding
            }

            Item {
                id: browser

                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    right: rootWallpaperPanel.showPreview ? preview.left : parent.right
                    rightMargin: rootWallpaperPanel.showPreview ? rootWallpaperPanel.wt.sectionGap : 0
                }

                // Whole columns only, centered: XL on a narrow panel would
                // otherwise leave a gap on the right.
                GridView {
                    id: grid

                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: Math.min(parent.width, Math.max(1, Math.floor(parent.width / cellWidth)) * cellWidth)
                    visible: rootWallpaperPanel.gridView
                    clip: true
                    model: rootWallpaperPanel.gridView ? rootWallpaperPanel.items : []
                    cellWidth: rootWallpaperPanel.tile.width + 2 * rootWallpaperPanel.wt.tilePadding + rootWallpaperPanel.wt.tileGap
                    cellHeight: rootWallpaperPanel.tile.height + rootWallpaperPanel.wt.tileLabelHeight + 2 * rootWallpaperPanel.wt.tilePadding + rootWallpaperPanel.wt.tileGap
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: rootWallpaperPanel.index
                    highlightFollowsCurrentItem: false
                    cacheBuffer: cellHeight * 2

                    delegate: Rectangle {
                        id: tileItem

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === rootWallpaperPanel.index

                        width: grid.cellWidth - rootWallpaperPanel.wt.tileGap
                        height: grid.cellHeight - rootWallpaperPanel.wt.tileGap
                        radius: rootWallpaperPanel.wt.tileRadius
                        color: isSelected ? rootWallpaperPanel.wt.selectedColor : (tileMouse.containsMouse ? rootWallpaperPanel.wt.hoveredColor : "transparent")
                        border.width: isSelected ? 2 : 0
                        border.color: rootWallpaperPanel.wt.selectedBorderColor

                        WallpaperThumb {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: rootWallpaperPanel.wt.tilePadding
                            }
                            height: rootWallpaperPanel.tile.height
                            wt: rootWallpaperPanel.wt
                            service: rootWallpaperPanel.service
                            item: tileItem.modelData
                            thumbSize: rootWallpaperPanel.tile.thumb
                            iconFont: rootWallpaperPanel.theme.iconFontFamily
                        }

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                leftMargin: rootWallpaperPanel.wt.tilePadding + 2
                                rightMargin: rootWallpaperPanel.wt.tilePadding + 2
                                bottomMargin: rootWallpaperPanel.wt.tilePadding
                            }
                            height: rootWallpaperPanel.wt.tileLabelHeight
                            verticalAlignment: Text.AlignVCenter
                            text: tileItem.modelData.name
                            color: tileItem.isSelected ? rootWallpaperPanel.wt.primaryTextColor : rootWallpaperPanel.wt.secondaryTextColor
                            font.pixelSize: rootWallpaperPanel.wt.metaPixelSize
                            elide: Text.ElideMiddle
                        }

                        MouseArea {
                            id: tileMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rootWallpaperPanel.needsInitialSelection = false;
                                rootWallpaperPanel.index = tileItem.index;
                            }
                            onDoubleClicked: rootWallpaperPanel.applyRequested(tileItem.modelData)
                        }
                    }
                }

                ListView {
                    id: list

                    anchors.fill: parent
                    visible: !rootWallpaperPanel.gridView
                    clip: true
                    spacing: 4
                    model: rootWallpaperPanel.gridView ? [] : rootWallpaperPanel.items
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: rootWallpaperPanel.index
                    highlightFollowsCurrentItem: false

                    delegate: Rectangle {
                        id: rowItem

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === rootWallpaperPanel.index

                        width: list.width
                        height: rootWallpaperPanel.wt.listRowHeight
                        radius: rootWallpaperPanel.wt.tileRadius
                        color: isSelected ? rootWallpaperPanel.wt.selectedColor : (rowMouse.containsMouse ? rootWallpaperPanel.wt.hoveredColor : "transparent")
                        border.width: isSelected ? 1 : 0
                        border.color: rootWallpaperPanel.wt.selectedBorderColor

                        WallpaperThumb {
                            id: rowThumb

                            anchors {
                                left: parent.left
                                leftMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            width: rootWallpaperPanel.wt.listThumbWidth
                            height: rootWallpaperPanel.wt.listRowHeight - 12
                            wt: rootWallpaperPanel.wt
                            service: rootWallpaperPanel.service
                            item: rowItem.modelData
                            thumbSize: 400
                            iconFont: rootWallpaperPanel.theme.iconFontFamily
                            showCurrentBadge: false
                        }

                        Column {
                            anchors {
                                left: rowThumb.right
                                leftMargin: 14
                                right: currentTag.left
                                rightMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 3

                            Text {
                                width: parent.width
                                text: rowItem.modelData.name
                                color: rootWallpaperPanel.wt.primaryTextColor
                                font.pixelSize: rootWallpaperPanel.wt.bodyPixelSize
                                font.bold: rowItem.isSelected
                                elide: Text.ElideMiddle
                            }

                            Text {
                                width: parent.width
                                text: rootWallpaperPanel.service.describe(rowItem.modelData)
                                color: rootWallpaperPanel.wt.secondaryTextColor
                                font.pixelSize: rootWallpaperPanel.wt.metaPixelSize
                            }
                        }

                        Text {
                            id: currentTag

                            anchors {
                                right: parent.right
                                rightMargin: 14
                                verticalCenter: parent.verticalCenter
                            }
                            text: rootWallpaperPanel.service.isCurrent(rowItem.modelData) ? "● current" : ""
                            color: rootWallpaperPanel.wt.currentColor
                            font.pixelSize: rootWallpaperPanel.wt.metaPixelSize
                        }

                        MouseArea {
                            id: rowMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rootWallpaperPanel.needsInitialSelection = false;
                                rootWallpaperPanel.index = rowItem.index;
                            }
                            onDoubleClicked: rootWallpaperPanel.applyRequested(rowItem.modelData)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: rootWallpaperPanel.items.length === 0
                    width: parent.width * 0.7
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: rootWallpaperPanel.service.errorText.length > 0 ? rootWallpaperPanel.service.errorText : rootWallpaperPanel.service.wallpapers.length === 0 ? "No wallpapers in " + rootWallpaperPanel.wt.wallpaperDir : "No wallpaper matches."
                    color: rootWallpaperPanel.service.errorText.length > 0 ? rootWallpaperPanel.wt.errorColor : rootWallpaperPanel.wt.secondaryTextColor
                    font.pixelSize: rootWallpaperPanel.wt.bodyPixelSize
                }
            }

            Rectangle {
                id: preview

                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                }
                width: Math.round(parent.width * rootWallpaperPanel.wt.previewWidthRatio)
                visible: rootWallpaperPanel.showPreview
                radius: rootWallpaperPanel.wt.tileRadius
                color: rootWallpaperPanel.wt.cardColor

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }
                    spacing: 10

                    WallpaperThumb {
                        width: parent.width
                        // 800x600 is the most a preview gets; narrower panes scale it down.
                        height: Math.min(600, Math.round(width * 0.75))
                        wt: rootWallpaperPanel.wt
                        service: rootWallpaperPanel.service
                        item: rootWallpaperPanel.selected
                        thumbSize: 800
                        iconFont: rootWallpaperPanel.theme.iconFontFamily
                        showCurrentBadge: false
                    }

                    Text {
                        width: parent.width
                        text: rootWallpaperPanel.selected ? rootWallpaperPanel.selected.name : ""
                        color: rootWallpaperPanel.wt.primaryTextColor
                        font.pixelSize: rootWallpaperPanel.wt.titlePixelSize
                        font.bold: true
                        wrapMode: Text.WrapAnywhere
                    }

                    Text {
                        width: parent.width
                        text: rootWallpaperPanel.service.describe(rootWallpaperPanel.selected)
                        color: rootWallpaperPanel.wt.secondaryTextColor
                        font.pixelSize: rootWallpaperPanel.wt.bodyPixelSize
                    }

                    Text {
                        width: parent.width
                        text: rootWallpaperPanel.service.isCurrent(rootWallpaperPanel.selected) ? "● current wallpaper" : "Enter applies it: Unclaimed Bloom regrows the theme around it."
                        color: rootWallpaperPanel.service.isCurrent(rootWallpaperPanel.selected) ? rootWallpaperPanel.wt.currentColor : rootWallpaperPanel.wt.secondaryTextColor
                        font.pixelSize: rootWallpaperPanel.wt.metaPixelSize + 1
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        // --- footer -------------------------------------------------------------
        Item {
            id: footer

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: rootWallpaperPanel.wt.panelPadding
                rightMargin: rootWallpaperPanel.wt.panelPadding
                bottomMargin: rootWallpaperPanel.wt.panelPadding / 2
            }
            height: rootWallpaperPanel.wt.footerHeight

            Text {
                anchors {
                    left: parent.left
                    right: buildText.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                text: rootWallpaperPanel.hints()
                color: rootWallpaperPanel.wt.secondaryTextColor
                font.pixelSize: rootWallpaperPanel.wt.metaPixelSize
                elide: Text.ElideRight
            }

            Text {
                id: buildText

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: rootWallpaperPanel.service.buildTotal > 0 ? "making thumbnails " + rootWallpaperPanel.service.buildDone + " / " + rootWallpaperPanel.service.buildTotal : ""
                color: rootWallpaperPanel.wt.accentColor
                font.pixelSize: rootWallpaperPanel.wt.metaPixelSize
            }
        }
    }
}
