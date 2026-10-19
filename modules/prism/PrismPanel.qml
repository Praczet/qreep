import QtQuick
import Quickshell
import Quickshell.Wayland

// Prism overlay: dimmed backdrop, one centered card. Sidebar on the left
// (Favourites, History, palettes), the selected section on the right: a
// swatch grid, or for a palette one full-width band per colour, named and
// lettered in another colour of the same palette.
PanelWindow {
    id: rootPrismPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen
    property string requestedSection: ""

    readonly property QtObject pt: theme.modules.prism

    // "favorites" | "history" | "palette:<id>"
    property string section: "history"
    property int index: 0
    property string query: ""
    property bool presented: false
    property bool shortcutsOpen: false
    property string notice: ""

    // Search box doubles as a prompt: "newPalette", "newPaletteAdd" (create,
    // then add pendingHex), "renamePalette", "renameColor". "" = filtering.
    property string promptMode: ""
    property string pendingHex: ""
    // Ctrl+P: which palette gets the selected colour.
    property bool chooserOpen: false
    property int chooserIndex: 0
    // Ctrl+Shift+Delete twice: the palette id waiting for the second press.
    property string confirmDelete: ""

    readonly property var palette: section.indexOf("palette:") === 0 ? service.paletteById(section.slice(8)) : null
    readonly property bool paletteView: palette !== null
    readonly property var sourceItems: section === "favorites" ? service.favoriteEntries() : section === "history" ? service.history : palette ? palette.colors : []
    // Filtered; each keeps its index in the section (sourceIndex) for edits.
    readonly property var items: filter(sourceItems.map((item, i) => Object.assign({ sourceIndex: i }, item)), query)
    readonly property var selected: items.length > 0 ? items[Math.max(0, Math.min(index, items.length - 1))] : null
    readonly property var sections: [
        { key: "favorites", label: "Favourites", icon: "󰓎", count: service.favorites.length },
        { key: "history", label: "History", icon: "󰋚", count: service.history.length }
    ].concat(service.palettes.map(item => ({ key: "palette:" + item.id, label: item.name, icon: "󰏘", count: item.colors.length, colors: item.colors })))
    readonly property var chooserOptions: service.palettes.map(item => ({ id: item.id, label: item.name })).concat([{ id: "", label: "New palette…" }])

    readonly property var shortcuts: [
        { keys: "type", action: "Filter by name or hex" },
        { keys: "↑ ↓ ← →", action: "Move" },
        { keys: "Enter", action: "Copy the hex and close" },
        { keys: "Shift+Enter", action: "Copy, stay open" },
        { keys: "Ctrl+S", action: "Favourite / unfavourite" },
        { keys: "Ctrl+P", action: "Add to a palette" },
        { keys: "Shift+Delete", action: "Remove (from this section)" },
        { keys: "Ctrl+1  Ctrl+2", action: "Favourites, History" },
        { keys: "Ctrl+3", action: "First palette" },
        { keys: "Ctrl+↑ Ctrl+↓", action: "Previous / next section" },
        { keys: "Ctrl+N", action: "New palette" },
        { keys: "F2", action: "Rename the colour (in a palette)" },
        { keys: "Shift+F2", action: "Rename the palette" },
        { keys: "Alt+↑ Alt+↓", action: "Move the colour in its palette" },
        { keys: "Ctrl+Shift+Delete", action: "Delete the palette (twice)" },
        { keys: "F1", action: "This sheet" },
        { keys: "Esc", action: "Back out: menu, prompt, sheet, filter, close" }
    ]

    signal closeRequested

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "qreep-prism"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: panelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Component.onCompleted: opened()

    onPanelOpenChanged: {
        if (panelOpen) {
            opened();
            return;
        }
        enterTimer.stop();
        presented = false;
        shortcutsOpen = false;
        chooserOpen = false;
        cancelPrompt();
    }

    onSectionChanged: {
        index = 0;
        confirmDelete = "";
    }

    function opened() {
        if (requestedSection.length > 0)
            section = requestedSection;
        query = "";
        search.text = "";
        index = 0;
        notice = "";
        search.forceActiveFocus();
        if (panelOpen)
            enterTimer.restart();
    }

    function filter(list, text) {
        const words = String(text || "").toLowerCase().split(/\s+/).filter(word => word.length > 0);

        if (words.length === 0)
            return list;
        return list.filter(item => words.every(word => (item.name + " " + item.hex).toLowerCase().indexOf(word) >= 0));
    }

    function columns() {
        return Math.max(1, Math.floor(grid.width / grid.cellWidth));
    }

    function move(step) {
        if (items.length > 0)
            index = Math.max(0, Math.min(items.length - 1, index + step));
    }

    function stepSection(step) {
        const keys = sections.map(item => item.key);
        const at = Math.max(0, keys.indexOf(section));

        section = keys[Math.max(0, Math.min(keys.length - 1, at + step))];
    }

    // --- prompt (search box as a one-line dialog) ------------------------------

    function startPrompt(mode, value) {
        promptMode = mode;
        search.text = value || "";
        search.selectAll();
        search.forceActiveFocus();
    }

    function cancelPrompt() {
        if (promptMode.length === 0)
            return;
        promptMode = "";
        pendingHex = "";
        search.text = query;
    }

    function applyPrompt() {
        const value = search.text.trim();
        const mode = promptMode;
        const hex = pendingHex;

        promptMode = "";
        pendingHex = "";
        search.text = query;

        if (mode === "newPalette" || mode === "newPaletteAdd") {
            const id = service.createPalette(value);
            if (mode === "newPaletteAdd" && hex)
                service.addToPalette(id, hex, "");
            section = "palette:" + id;
            notice = "Palette created.";
        } else if (mode === "renamePalette" && palette) {
            service.renamePalette(palette.id, value);
        } else if (mode === "renameColor" && palette && selected) {
            service.renameColor(palette.id, selected.sourceIndex, value);
        }
    }

    function promptLabel() {
        return ({
                newPalette: "New palette",
                newPaletteAdd: "New palette",
                renamePalette: "Rename palette",
                renameColor: "Rename colour"
            })[promptMode] || "Prism";
    }

    // --- actions ---------------------------------------------------------------------

    function copySelected(stay) {
        if (!selected)
            return;
        service.copy(selected.hex);
        if (stay)
            notice = "Copied " + selected.hex + ".";
        else
            closeRequested();
    }

    function removeSelected() {
        if (!selected)
            return;
        if (section === "history")
            service.removeFromHistory(selected.hex);
        else if (section === "favorites")
            service.toggleFavorite(selected.hex);
        else if (palette)
            service.removeFromPalette(palette.id, selected.sourceIndex);
    }

    function pickChooser(option) {
        chooserOpen = false;
        if (!selected || !option)
            return;
        if (option.id.length === 0) {
            pendingHex = selected.hex;
            startPrompt("newPaletteAdd", "");
            return;
        }
        service.addToPalette(option.id, selected.hex, selected.name);
        notice = "Added " + selected.name + " to " + option.label + ".";
    }

    function handleKey(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
        const alt = (event.modifiers & Qt.AltModifier) !== 0;

        if (event.key === Qt.Key_F1) {
            event.accepted = true;
            shortcutsOpen = !shortcutsOpen;
            return;
        }

        if (chooserOpen) {
            event.accepted = true;
            if (event.key === Qt.Key_Escape)
                chooserOpen = false;
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down)
                chooserIndex = Math.max(0, Math.min(chooserOptions.length - 1, chooserIndex + (event.key === Qt.Key_Down ? 1 : -1)));
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                pickChooser(chooserOptions[chooserIndex]);
            return;
        }

        if (promptMode.length > 0) {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                cancelPrompt();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true;
                applyPrompt();
            }
            return;
        }

        if (ctrl && event.key >= Qt.Key_1 && event.key <= Qt.Key_3) {
            event.accepted = true;
            const keys = sections.map(item => item.key);
            section = event.key === Qt.Key_1 ? "favorites" : event.key === Qt.Key_2 ? "history" : (keys[2] || "history");
            return;
        }

        switch (event.key) {
        case Qt.Key_Escape:
            event.accepted = true;
            if (shortcutsOpen)
                shortcutsOpen = false;
            else if (search.text.length > 0) {
                search.text = "";
                query = "";
            } else
                closeRequested();
            return;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            event.accepted = true;
            copySelected(shift);
            return;
        case Qt.Key_Up:
        case Qt.Key_Down:
            event.accepted = true;
            {
                const step = event.key === Qt.Key_Down ? 1 : -1;

                if (ctrl)
                    stepSection(step);
                else if (alt && palette && selected) {
                    service.moveColor(palette.id, selected.sourceIndex, step);
                    move(step);
                } else
                    move(paletteView ? step : step * columns());
            }
            return;
        case Qt.Key_Left:
        case Qt.Key_Right:
            if (!paletteView) {
                event.accepted = true;
                move(event.key === Qt.Key_Right ? 1 : -1);
            }
            return;
        case Qt.Key_S:
            if (ctrl && selected) {
                event.accepted = true;
                service.toggleFavorite(selected.hex);
                notice = service.isFavorite(selected.hex) ? selected.name + " is a favourite." : selected.name + " is no longer a favourite.";
            }
            return;
        case Qt.Key_P:
            if (ctrl && selected) {
                event.accepted = true;
                chooserIndex = 0;
                chooserOpen = true;
            }
            return;
        case Qt.Key_N:
            if (ctrl) {
                event.accepted = true;
                startPrompt("newPalette", "");
            }
            return;
        case Qt.Key_F2:
            event.accepted = true;
            if (shift && palette)
                startPrompt("renamePalette", palette.name);
            else if (palette && selected)
                startPrompt("renameColor", selected.name);
            return;
        case Qt.Key_Delete:
            if (ctrl && shift && palette) {
                event.accepted = true;
                if (confirmDelete === palette.id) {
                    const name = palette.name;
                    service.deletePalette(palette.id);
                    section = "history";
                    notice = "Deleted palette " + name + ".";
                } else {
                    confirmDelete = palette.id;
                    notice = "Ctrl+Shift+Delete again deletes " + palette.name + ".";
                }
            } else if (shift) {
                event.accepted = true;
                removeSelected();
            }
            return;
        }
    }

    function hints() {
        if (promptMode.length > 0)
            return "Enter save · Esc cancel";
        if (chooserOpen)
            return "↑↓ choose · Enter add · Esc cancel";
        return "Enter copy · Shift+Enter copy, stay · Ctrl+S favourite · Ctrl+P add to palette · Shift+Del remove · Ctrl+N new palette · F1 shortcuts";
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: rootPrismPanel.presented = true
    }

    onIndexChanged: {
        if (paletteView)
            bands.positionViewAtIndex(index, ListView.Contain);
        else
            grid.positionViewAtIndex(index, GridView.Contain);
    }

    Rectangle {
        anchors.fill: parent
        color: rootPrismPanel.pt.overlayColor
        opacity: rootPrismPanel.presented ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: rootPrismPanel.pt.animationDuration
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rootPrismPanel.closeRequested()
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        anchors.verticalCenterOffset: rootPrismPanel.presented ? 0 : 24
        width: rootPrismPanel.pt.panelWidthFor(parent.width, parent.height)
        height: rootPrismPanel.pt.panelHeightFor(parent.width, parent.height)
        radius: rootPrismPanel.pt.panelRadius
        color: rootPrismPanel.pt.panelColor
        border.width: 1
        border.color: rootPrismPanel.pt.borderColor
        opacity: rootPrismPanel.presented ? 1 : 0
        scale: rootPrismPanel.presented ? 1 : 0.98
        clip: true

        Behavior on opacity {
            NumberAnimation {
                duration: rootPrismPanel.pt.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: rootPrismPanel.pt.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: rootPrismPanel.pt.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        // --- search / prompt -------------------------------------------------------
        Rectangle {
            id: searchBox

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: rootPrismPanel.pt.panelPadding
            }
            height: rootPrismPanel.pt.searchHeight
            radius: height / 2
            color: rootPrismPanel.pt.searchColor
            border.width: 1
            border.color: rootPrismPanel.promptMode.length > 0 ? rootPrismPanel.pt.favoriteColor : rootPrismPanel.pt.selectedBorderColor

            Text {
                id: searchIcon

                anchors {
                    left: parent.left
                    leftMargin: 18
                    verticalCenter: parent.verticalCenter
                }
                text: "󰏘"
                color: rootPrismPanel.pt.accentColor
                font.family: rootPrismPanel.theme.iconFontFamily
                font.pixelSize: 20
            }

            Text {
                id: searchLabel

                anchors {
                    left: searchIcon.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                text: rootPrismPanel.promptLabel()
                color: rootPrismPanel.promptMode.length > 0 ? rootPrismPanel.pt.favoriteColor : rootPrismPanel.pt.accentColor
                font.pixelSize: rootPrismPanel.pt.searchPixelSize
                font.bold: true
            }

            TextInput {
                id: search

                anchors {
                    left: searchLabel.right
                    leftMargin: 14
                    right: countText.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                color: rootPrismPanel.pt.primaryTextColor
                selectionColor: rootPrismPanel.pt.selectedColor
                font.pixelSize: rootPrismPanel.pt.searchPixelSize
                clip: true

                onTextEdited: {
                    if (rootPrismPanel.promptMode.length > 0)
                        return;
                    rootPrismPanel.query = text;
                    rootPrismPanel.index = 0;
                }
                Keys.onPressed: event => rootPrismPanel.handleKey(event)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text.length === 0
                    text: rootPrismPanel.promptMode.length > 0 ? "a name, Enter to save" : "type to filter by name or hex"
                    color: rootPrismPanel.pt.secondaryTextColor
                    font.pixelSize: rootPrismPanel.pt.searchPixelSize
                }
            }

            Text {
                id: countText

                anchors {
                    right: parent.right
                    rightMargin: 18
                    verticalCenter: parent.verticalCenter
                }
                text: rootPrismPanel.items.length === rootPrismPanel.sourceItems.length ? rootPrismPanel.items.length + " colours" : rootPrismPanel.items.length + " of " + rootPrismPanel.sourceItems.length
                color: rootPrismPanel.pt.secondaryTextColor
                font.pixelSize: rootPrismPanel.pt.metaPixelSize
            }
        }

        // --- sidebar ---------------------------------------------------------------
        Column {
            id: sidebar

            anchors {
                left: parent.left
                top: searchBox.bottom
                bottom: footer.top
                margins: rootPrismPanel.pt.panelPadding
            }
            width: rootPrismPanel.pt.sidebarWidth
            spacing: 4

            Repeater {
                model: rootPrismPanel.sections

                // Palettes start after a small heading, in the first palette's row.
                Item {
                    id: sectionItem

                    required property var modelData
                    required property int index

                    readonly property bool hasHeading: index === 2

                    width: sidebar.width
                    height: rootPrismPanel.pt.rowHeight + (hasHeading ? 28 : 0)

                    Text {
                        visible: sectionItem.hasHeading
                        x: 12
                        y: 8
                        text: "PALETTES"
                        color: rootPrismPanel.pt.sectionColor
                        font.pixelSize: rootPrismPanel.pt.metaPixelSize
                        font.bold: true
                        font.letterSpacing: 1
                    }

                Rectangle {
                    id: sectionRow

                    readonly property var modelData: sectionItem.modelData
                    readonly property bool active: rootPrismPanel.section === modelData.key

                    anchors.bottom: parent.bottom
                    width: sidebar.width
                    height: rootPrismPanel.pt.rowHeight
                    radius: rootPrismPanel.pt.rowRadius
                    color: active ? rootPrismPanel.pt.selectedColor : (rowMouse.containsMouse ? rootPrismPanel.pt.hoveredColor : "transparent")
                    border.width: active ? 1 : 0
                    border.color: rootPrismPanel.pt.selectedBorderColor

                    Text {
                        id: rowIcon

                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        text: sectionRow.modelData.icon
                        color: sectionRow.modelData.key === "favorites" ? rootPrismPanel.pt.favoriteColor : rootPrismPanel.pt.accentColor
                        font.family: rootPrismPanel.theme.iconFontFamily
                        font.pixelSize: 16
                    }

                    Text {
                        anchors {
                            left: rowIcon.right
                            leftMargin: 10
                            right: dots.left
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        text: sectionRow.modelData.label
                        color: rootPrismPanel.pt.primaryTextColor
                        font.pixelSize: rootPrismPanel.pt.bodyPixelSize
                        font.bold: sectionRow.active
                        elide: Text.ElideRight
                    }

                    // A palette's first colours as dots; a count otherwise.
                    Row {
                        id: dots

                        anchors {
                            right: parent.right
                            rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: -4

                        Repeater {
                            model: (sectionRow.modelData.colors || []).slice(0, 5)

                            Rectangle {
                                required property var modelData

                                width: 14
                                height: 14
                                radius: 7
                                color: modelData.hex
                                border.width: 1
                                border.color: rootPrismPanel.pt.borderColor
                            }
                        }

                        Text {
                            visible: !sectionRow.modelData.colors
                            text: sectionRow.modelData.count
                            color: rootPrismPanel.pt.secondaryTextColor
                            font.pixelSize: rootPrismPanel.pt.metaPixelSize
                        }
                    }

                    MouseArea {
                        id: rowMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootPrismPanel.section = sectionRow.modelData.key
                    }
                }
                }
            }

            Item {
                width: 1
                height: 6
            }

            Rectangle {
                width: sidebar.width
                height: rootPrismPanel.pt.rowHeight
                radius: rootPrismPanel.pt.rowRadius
                color: newMouse.containsMouse ? rootPrismPanel.pt.hoveredColor : "transparent"

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text: "󰐕  New palette  (Ctrl+N)"
                    color: rootPrismPanel.pt.secondaryTextColor
                    font.family: rootPrismPanel.theme.iconFontFamily
                    font.pixelSize: rootPrismPanel.pt.bodyPixelSize
                }

                MouseArea {
                    id: newMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootPrismPanel.startPrompt("newPalette", "")
                }
            }
        }

        // --- main area -------------------------------------------------------------
        Item {
            id: main

            anchors {
                left: sidebar.right
                right: parent.right
                top: searchBox.bottom
                bottom: footer.top
                margins: rootPrismPanel.pt.panelPadding
            }

            GridView {
                id: grid

                anchors.fill: parent
                visible: !rootPrismPanel.paletteView
                clip: true
                model: rootPrismPanel.paletteView ? [] : rootPrismPanel.items
                cellWidth: rootPrismPanel.pt.swatchWidth + rootPrismPanel.pt.swatchGap
                cellHeight: rootPrismPanel.pt.swatchHeight + rootPrismPanel.pt.swatchLabelHeight + rootPrismPanel.pt.swatchGap
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: Math.max(0, rootPrismPanel.index)
                highlightFollowsCurrentItem: false

                delegate: Rectangle {
                    id: swatch

                    required property var modelData
                    required property int index

                    readonly property bool isSelected: index === rootPrismPanel.index

                    width: grid.cellWidth - rootPrismPanel.pt.swatchGap
                    height: grid.cellHeight - rootPrismPanel.pt.swatchGap
                    radius: rootPrismPanel.pt.swatchRadius
                    color: isSelected ? rootPrismPanel.pt.selectedColor : (swatchMouse.containsMouse ? rootPrismPanel.pt.hoveredColor : "transparent")
                    border.width: isSelected ? 2 : 0
                    border.color: rootPrismPanel.pt.selectedBorderColor

                    Rectangle {
                        id: chip

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 5
                        }
                        height: rootPrismPanel.pt.swatchHeight - 10
                        radius: rootPrismPanel.pt.swatchRadius - 3
                        color: swatch.modelData.hex
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)

                        Text {
                            anchors {
                                right: parent.right
                                top: parent.top
                                margins: 6
                            }
                            visible: rootPrismPanel.service.isFavorite(swatch.modelData.hex)
                            text: "󰓎"
                            color: rootPrismPanel.service.textOn(swatch.modelData.hex, null)
                            font.family: rootPrismPanel.theme.iconFontFamily
                            font.pixelSize: 14
                        }
                    }

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: chip.bottom
                            topMargin: 4
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: 1

                        Text {
                            width: parent.width
                            text: swatch.modelData.name
                            color: rootPrismPanel.pt.primaryTextColor
                            font.pixelSize: rootPrismPanel.pt.metaPixelSize + 1
                            font.bold: swatch.isSelected
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: swatch.modelData.hex
                            color: rootPrismPanel.pt.secondaryTextColor
                            font.family: rootPrismPanel.theme.iconFontFamily
                            font.pixelSize: rootPrismPanel.pt.metaPixelSize
                        }
                    }

                    MouseArea {
                        id: swatchMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootPrismPanel.index = swatch.index
                        onDoubleClicked: {
                            rootPrismPanel.index = swatch.index;
                            rootPrismPanel.copySelected(false);
                        }
                    }
                }
            }

            // Palette poster: one band per colour (the Timberwolf / American
            // Brown look), lettered in the palette colour that reads best.
            ListView {
                id: bands

                anchors.fill: parent
                visible: rootPrismPanel.paletteView
                clip: true
                model: rootPrismPanel.paletteView ? rootPrismPanel.items : []
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: Math.max(0, rootPrismPanel.index)
                highlightFollowsCurrentItem: false

                delegate: Rectangle {
                    id: band

                    required property var modelData
                    required property int index

                    readonly property bool isSelected: index === rootPrismPanel.index
                    readonly property color ink: rootPrismPanel.service.textOn(modelData.hex, rootPrismPanel.palette)

                    width: bands.width
                    height: Math.max(rootPrismPanel.pt.bandMinHeight, Math.floor(bands.height / Math.max(1, rootPrismPanel.items.length)))
                    color: modelData.hex
                    radius: index === 0 || index === rootPrismPanel.items.length - 1 ? rootPrismPanel.pt.swatchRadius : 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: band.modelData.name
                            color: band.ink
                            font.family: rootPrismPanel.pt.bandFontFamily
                            font.pixelSize: Math.min(rootPrismPanel.pt.bandTitlePixelSize, band.height * 0.42)
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: hexText.implicitWidth + 12
                            height: hexText.implicitHeight + 4
                            color: "transparent"
                            border.width: 1
                            border.color: band.ink

                            Text {
                                id: hexText

                                anchors.centerIn: parent
                                text: band.modelData.hex.toUpperCase()
                                color: band.ink
                                font.pixelSize: rootPrismPanel.pt.bodyPixelSize
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        visible: band.isSelected
                        color: "transparent"
                        radius: 8
                        border.width: 2
                        border.color: band.ink
                    }

                    Text {
                        anchors {
                            right: parent.right
                            top: parent.top
                            margins: 14
                        }
                        visible: rootPrismPanel.service.isFavorite(band.modelData.hex)
                        text: "󰓎"
                        color: band.ink
                        font.family: rootPrismPanel.theme.iconFontFamily
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootPrismPanel.index = band.index
                        onDoubleClicked: {
                            rootPrismPanel.index = band.index;
                            rootPrismPanel.copySelected(false);
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                width: parent.width * 0.7
                visible: rootPrismPanel.items.length === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: rootPrismPanel.service.lastError.length > 0 ? rootPrismPanel.service.lastError
                    : rootPrismPanel.sourceItems.length > 0 ? "No colour matches."
                    : rootPrismPanel.section === "favorites" ? "No favourites yet. Ctrl+S on a colour makes it one."
                    : rootPrismPanel.section === "history" ? "No colours yet. Pick one with Super+P, or copy one (#hex, rgb(), hsl()); both land here."
                    : "An empty palette. Ctrl+P on a colour in History or Favourites adds it here."
                color: rootPrismPanel.service.lastError.length > 0 ? rootPrismPanel.pt.errorColor : rootPrismPanel.pt.secondaryTextColor
                font.pixelSize: rootPrismPanel.pt.bodyPixelSize + 1
            }
        }

        // --- footer -----------------------------------------------------------------
        Item {
            id: footer

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: rootPrismPanel.pt.panelPadding
                rightMargin: rootPrismPanel.pt.panelPadding
                bottomMargin: rootPrismPanel.pt.panelPadding / 2
            }
            height: rootPrismPanel.pt.footerHeight

            Text {
                anchors {
                    left: parent.left
                    right: noticeText.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                text: rootPrismPanel.hints()
                color: rootPrismPanel.pt.secondaryTextColor
                font.pixelSize: rootPrismPanel.pt.metaPixelSize
                elide: Text.ElideRight
            }

            Text {
                id: noticeText

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: rootPrismPanel.notice
                color: rootPrismPanel.pt.accentColor
                font.pixelSize: rootPrismPanel.pt.metaPixelSize
            }
        }

        // --- Ctrl+P: add to which palette ------------------------------------------
        Rectangle {
            anchors.centerIn: parent
            width: 360
            height: chooserColumn.implicitHeight + 28
            visible: rootPrismPanel.chooserOpen
            radius: rootPrismPanel.pt.swatchRadius
            color: rootPrismPanel.pt.sheetColor
            border.width: 1
            border.color: rootPrismPanel.pt.selectedBorderColor

            Column {
                id: chooserColumn

                anchors {
                    fill: parent
                    margins: 14
                }
                spacing: 4

                Text {
                    bottomPadding: 6
                    text: "Add " + (rootPrismPanel.selected ? rootPrismPanel.selected.name : "") + " to"
                    color: rootPrismPanel.pt.sectionColor
                    font.pixelSize: rootPrismPanel.pt.bodyPixelSize
                    font.bold: true
                }

                Repeater {
                    model: rootPrismPanel.chooserOptions

                    Rectangle {
                        id: optionRow

                        required property var modelData
                        required property int index

                        width: chooserColumn.width
                        height: 32
                        radius: 8
                        color: index === rootPrismPanel.chooserIndex ? rootPrismPanel.pt.selectedColor : (optionMouse.containsMouse ? rootPrismPanel.pt.hoveredColor : "transparent")

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            text: optionRow.modelData.label
                            color: optionRow.modelData.id.length > 0 ? rootPrismPanel.pt.primaryTextColor : rootPrismPanel.pt.secondaryTextColor
                            font.pixelSize: rootPrismPanel.pt.bodyPixelSize
                        }

                        MouseArea {
                            id: optionMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: rootPrismPanel.pickChooser(optionRow.modelData)
                        }
                    }
                }
            }
        }

        // --- F1 shortcuts sheet ---------------------------------------------------------
        Rectangle {
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: rootPrismPanel.shortcutsOpen ? 1 : 0
            color: rootPrismPanel.pt.overlayColor
            radius: card.radius

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: rootPrismPanel.shortcutsOpen = false
            }

            Rectangle {
                anchors.centerIn: parent
                width: 560
                height: sheet.implicitHeight + 2 * rootPrismPanel.pt.panelPadding
                radius: rootPrismPanel.pt.swatchRadius
                color: rootPrismPanel.pt.sheetColor
                border.width: 1
                border.color: rootPrismPanel.pt.selectedBorderColor

                Column {
                    id: sheet

                    anchors {
                        fill: parent
                        margins: rootPrismPanel.pt.panelPadding
                    }
                    spacing: 7

                    Text {
                        bottomPadding: 6
                        text: "Shortcuts"
                        color: rootPrismPanel.pt.sectionColor
                        font.pixelSize: rootPrismPanel.pt.metaPixelSize + 1
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                    }

                    Repeater {
                        model: rootPrismPanel.shortcuts

                        Row {
                            required property var modelData

                            spacing: 16

                            Rectangle {
                                width: 170
                                height: 24
                                radius: 6
                                color: rootPrismPanel.pt.chipColor

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.keys
                                    color: rootPrismPanel.pt.accentColor
                                    font.family: rootPrismPanel.theme.iconFontFamily
                                    font.pixelSize: rootPrismPanel.pt.metaPixelSize + 1
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.action
                                color: rootPrismPanel.pt.primaryTextColor
                                font.pixelSize: rootPrismPanel.pt.bodyPixelSize
                            }
                        }
                    }
                }
            }
        }
    }
}
