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
    // F1 sheet. Esc closes it before it clears the filter or closes.
    property bool shortcutsOpen: false
    // Bloom profile dropdown under the profile chip. Esc closes it first.
    property bool profileMenuOpen: false
    readonly property bool profileChanged: service.chosenProfile.length > 0 && service.chosenProfile !== service.currentProfile
    readonly property var shortcuts: [
        { keys: "type", action: "Filter by name" },
        { keys: "↑ ↓ ← →", action: "Move (← → in the grid only)" },
        { keys: "PgUp  PgDn", action: "A page at a time" },
        { keys: "Enter", action: "Apply (Unclaimed Bloom regrows the theme)" },
        { keys: "Ctrl+B  Ctrl+⇧B", action: "Next / previous Bloom profile (used on apply)" },
        { keys: "double click", action: "Apply" },
        { keys: "Ctrl+P", action: "Grid ↔ list" },
        { keys: "Ctrl+1 … Ctrl+4", action: "Tile size S / M / L / XL" },
        { keys: "Ctrl++  Ctrl+=", action: "Bigger tiles" },
        { keys: "Ctrl+-  Ctrl+_", action: "Smaller tiles" },
        { keys: "F1", action: "This sheet" },
        { keys: "Esc", action: "Close sheet, clear filter, close" },
        { keys: "Ctrl+Esc", action: "Close" }
    ]

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
        shortcutsOpen = false;
        profileMenuOpen = false;
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

        if (event.key === Qt.Key_F1) {
            event.accepted = true;
            shortcutsOpen = !shortcutsOpen;
            return;
        }

        // Ctrl+1 … Ctrl+4: S / M / L / XL, straight to the grid.
        if (ctrl && event.key >= Qt.Key_1 && event.key < Qt.Key_1 + wt.sizeOrder.length) {
            event.accepted = true;
            service.setView("grid");
            service.setSize(wt.sizeOrder[event.key - Qt.Key_1]);
            return;
        }

        switch (event.key) {
        case Qt.Key_Escape:
            event.accepted = true;
            if (!ctrl && profileMenuOpen) {
                profileMenuOpen = false;
            } else if (!ctrl && shortcutsOpen) {
                shortcutsOpen = false;
            } else if (!ctrl && search.text.length > 0) {
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
        case Qt.Key_P:
            if (ctrl) {
                event.accepted = true;
                service.setView(gridView ? "list" : "grid");
            }
            return;
        case Qt.Key_B:
            if (ctrl) {
                event.accepted = true;
                service.stepProfile((event.modifiers & Qt.ShiftModifier) !== 0 ? -1 : 1);
            }
            return;
        // + and = share a key, as do - and _: with or without Shift.
        case Qt.Key_Equal:
        case Qt.Key_Plus:
        case Qt.Key_Minus:
        case Qt.Key_Underscore:
            if (ctrl) {
                event.accepted = true;
                service.setView("grid");
                service.stepSize(event.key === Qt.Key_Minus || event.key === Qt.Key_Underscore ? -1 : 1);
            }
            return;
        }
    }

    function hints() {
        const keys = gridView ? "↑↓←→ move" : "↑↓ move";

        return keys + " · Enter apply (Unclaimed Bloom) · Ctrl+B profile · Ctrl+P " + (gridView ? "list" : "grid") + " · Ctrl+1–4 / Ctrl+± size · F1 shortcuts · Esc " + (search.text.length > 0 ? "clear" : "close");
    }

    // Under the preview: what Enter will do with the chosen profile.
    // Swatch click: search for that colour, like typing it.
    function searchColor(hex) {
        needsInitialSelection = false;
        search.text = hex;
        service.setQuery(hex);
        index = 0;
    }

    function previewNote() {
        const current = service.isCurrent(selected);

        if (profileChanged)
            return (current ? "● current wallpaper · " : "") + "Enter applies it with " + service.chosenProfile + ".";
        return current ? "● current wallpaper" : "Enter applies it: Unclaimed Bloom regrows the theme around it.";
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

            // Bloom profile used on apply. Highlighted while it differs from
            // the active one, so a pending switch is hard to miss.
            WallpaperChip {
                id: profileChip

                anchors {
                    left: searchLabel.right
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                wt: rootWallpaperPanel.wt
                iconFont: rootWallpaperPanel.theme.iconFontFamily
                label: "󰉼 " + (rootWallpaperPanel.service.chosenProfile || "no profile") + "  ▾"
                active: rootWallpaperPanel.profileChanged || rootWallpaperPanel.profileMenuOpen
                onClicked: rootWallpaperPanel.profileMenuOpen = !rootWallpaperPanel.profileMenuOpen
            }

            TextInput {
                id: search

                anchors {
                    left: profileChip.right
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
                        showPalette: false
                    }

                    // Click a colour to find wallpapers that share it.
                    WallpaperPalette {
                        width: parent.width
                        height: 18
                        clickable: true
                        swatchRadius: 3
                        colors: rootWallpaperPanel.selected ? (rootWallpaperPanel.selected.colors || []) : []
                        onColorClicked: hex => rootWallpaperPanel.searchColor(hex)
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
                        text: rootWallpaperPanel.previewNote()
                        color: rootWallpaperPanel.profileChanged ? rootWallpaperPanel.wt.accentColor : (rootWallpaperPanel.service.isCurrent(rootWallpaperPanel.selected) ? rootWallpaperPanel.wt.currentColor : rootWallpaperPanel.wt.secondaryTextColor)
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

        // --- Bloom profile dropdown --------------------------------------------
        // Under the profile chip, above the browser. Picking only chooses;
        // nothing changes until a wallpaper is applied.
        Rectangle {
            id: profileMenu

            x: searchBox.x + profileChip.x
            y: searchBox.y + searchBox.height + 6
            width: rootWallpaperPanel.wt.profileMenuWidth
            height: profileColumn.implicitHeight + 12
            visible: rootWallpaperPanel.profileMenuOpen
            radius: rootWallpaperPanel.wt.tileRadius
            color: rootWallpaperPanel.wt.sheetColor
            border.width: 1
            border.color: rootWallpaperPanel.wt.selectedBorderColor

            Column {
                id: profileColumn

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 6
                }

                Text {
                    visible: rootWallpaperPanel.service.profiles.length === 0
                    leftPadding: 10
                    topPadding: 6
                    bottomPadding: 6
                    text: "No Unclaimed Bloom compositions found."
                    color: rootWallpaperPanel.wt.secondaryTextColor
                    font.pixelSize: rootWallpaperPanel.wt.bodyPixelSize
                }

                Repeater {
                    model: rootWallpaperPanel.service.profiles

                    Rectangle {
                        required property string modelData

                        width: profileColumn.width
                        height: rootWallpaperPanel.wt.profileRowHeight
                        radius: 6
                        color: modelData === rootWallpaperPanel.service.chosenProfile ? rootWallpaperPanel.wt.selectedColor : (profileRowMouse.containsMouse ? rootWallpaperPanel.wt.hoveredColor : "transparent")

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 10
                                right: activeTag.left
                                rightMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData
                            color: rootWallpaperPanel.wt.primaryTextColor
                            font.pixelSize: rootWallpaperPanel.wt.bodyPixelSize
                            font.bold: modelData === rootWallpaperPanel.service.chosenProfile
                            elide: Text.ElideRight
                        }

                        Text {
                            id: activeTag

                            anchors {
                                right: parent.right
                                rightMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            visible: modelData === rootWallpaperPanel.service.currentProfile
                            text: "● active"
                            color: rootWallpaperPanel.wt.currentColor
                            font.pixelSize: rootWallpaperPanel.wt.metaPixelSize
                        }

                        MouseArea {
                            id: profileRowMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rootWallpaperPanel.service.chooseProfile(modelData);
                                rootWallpaperPanel.profileMenuOpen = false;
                                search.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        // --- F1 shortcuts sheet (same look as Places) -----------------------------
        Rectangle {
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: rootWallpaperPanel.shortcutsOpen ? 1 : 0
            color: rootWallpaperPanel.wt.overlayColor
            radius: card.radius

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: rootWallpaperPanel.shortcutsOpen = false
            }

            Rectangle {
                anchors.centerIn: parent
                width: 520
                height: sheet.implicitHeight + 2 * rootWallpaperPanel.wt.panelPadding
                radius: rootWallpaperPanel.wt.tileRadius
                color: rootWallpaperPanel.wt.sheetColor
                border.width: 1
                border.color: rootWallpaperPanel.wt.selectedBorderColor

                Column {
                    id: sheet

                    anchors {
                        fill: parent
                        margins: rootWallpaperPanel.wt.panelPadding
                    }
                    spacing: 8

                    Text {
                        bottomPadding: 6
                        text: "Shortcuts"
                        color: rootWallpaperPanel.wt.accentColor
                        font.pixelSize: rootWallpaperPanel.wt.metaPixelSize + 1
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                    }

                    Repeater {
                        model: rootWallpaperPanel.shortcuts

                        Row {
                            required property var modelData

                            spacing: 16

                            Rectangle {
                                width: 150
                                height: 24
                                radius: 6
                                color: rootWallpaperPanel.wt.chipColor

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.keys
                                    color: rootWallpaperPanel.wt.accentColor
                                    font.family: rootWallpaperPanel.theme.iconFontFamily
                                    font.pixelSize: rootWallpaperPanel.wt.metaPixelSize + 1
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.action
                                color: rootWallpaperPanel.wt.primaryTextColor
                                font.pixelSize: rootWallpaperPanel.wt.bodyPixelSize
                            }
                        }
                    }
                }
            }
        }
    }
}
