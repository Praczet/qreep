import QtQuick
import Quickshell
import Quickshell.Wayland

// Prism overlay: dimmed backdrop, one centered card. Sidebar on the left
// (Favourites, History, palettes), the selected section on the right:
//   Favourites / History  a grid of colour swatches
//   a palette             a grid of combo posters
//   a combo (Enter)       that combo full size: one band per colour,
//                         lettered in the combo colour that reads best
PanelWindow {
    id: rootPrismPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen
    property string requestedSection: ""

    readonly property QtObject pt: theme.modules.prism

    // "favorites" | "history" | "palette:<id>"
    property string section: "history"
    // An open combo inside the palette section; "" shows the combo grid.
    property string comboId: ""
    property int index: 0
    property string query: ""
    property bool presented: false
    property bool shortcutsOpen: false
    property string notice: ""

    // Search box doubles as a prompt: "newPalette", "newPaletteAdd" (palette
    // + combo for pendingHex), "renamePalette", "renameCombo", "renameColor".
    property string promptMode: ""
    property string pendingHex: ""
    // Ctrl+P: where the selected colour goes. lastTarget is the default.
    property bool chooserOpen: false
    property int chooserIndex: 0
    property string lastTarget: ""
    // Things deleted on the second press: "palette:<id>" or "combo:<id>".
    property string confirmDelete: ""

    readonly property var palette: section.indexOf("palette:") === 0 ? service.paletteById(section.slice(8)) : null
    readonly property var combo: palette && comboId.length > 0 ? palette.combos.find(item => item.id === comboId) || null : null
    // "colors" | "combos" | "poster"
    readonly property string view: combo ? "poster" : palette ? "combos" : "colors"
    readonly property var sourceItems: view === "poster" ? combo.colors : view === "combos" ? palette.combos : section === "favorites" ? service.favoriteEntries() : service.history
    // Filtered; each keeps its index in the section (sourceIndex) for edits.
    readonly property var items: filter(sourceItems.map((item, i) => Object.assign({ sourceIndex: i }, item)), query)
    readonly property var selected: items.length > 0 ? items[Math.max(0, Math.min(index, items.length - 1))] : null
    // The selected colour, wherever it is (not in the combo grid).
    readonly property var selectedColor: view === "combos" ? null : selected
    readonly property var sections: [
        { key: "favorites", label: "Favourites", icon: "󰓎", count: service.favorites.length },
        { key: "history", label: "History", icon: "󰋚", count: service.history.length }
    ].concat(service.palettes.map(item => ({
        key: "palette:" + item.id,
        label: item.name,
        icon: "󰏘",
        count: item.combos.length,
        colors: item.combos.reduce((all, entry) => all.concat(entry.colors), [])
    })))
    readonly property var chooserOptions: {
        const options = [];

        for (const item of service.palettes) {
            for (const entry of item.combos)
                options.push({ kind: "combo", paletteId: item.id, comboId: entry.id, label: item.name + "  ›  " + entry.name, colors: entry.colors });
            options.push({ kind: "newCombo", paletteId: item.id, comboId: "", label: item.name + "  ›  New combo", colors: [] });
        }
        options.push({ kind: "newPalette", paletteId: "", comboId: "", label: "New palette…", colors: [] });
        return options;
    }

    readonly property var shortcuts: [
        { keys: "type", action: "Filter by name or hex" },
        { keys: "↑ ↓ ← →", action: "Move" },
        { keys: "Enter", action: "Copy the hex and close (a palette: open the combo)" },
        { keys: "Shift+Enter", action: "Copy, stay open" },
        { keys: "Ctrl+S", action: "Favourite / unfavourite" },
        { keys: "Ctrl+P", action: "Add the colour to a combo" },
        { keys: "Shift+Delete", action: "Remove (a combo: press twice)" },
        { keys: "Ctrl+1  Ctrl+2", action: "Favourites, History" },
        { keys: "Ctrl+3", action: "First palette" },
        { keys: "Ctrl+↑ Ctrl+↓", action: "Previous / next section" },
        { keys: "Ctrl+N", action: "New combo (in a palette), else new palette" },
        { keys: "Ctrl+Shift+N", action: "New palette" },
        { keys: "F2", action: "Rename the colour / the combo" },
        { keys: "Shift+F2", action: "Rename the palette" },
        { keys: "Alt+arrows", action: "Move the colour / combo" },
        { keys: "Ctrl+Shift+Delete", action: "Delete the palette (twice)" },
        { keys: "F1", action: "This sheet" },
        { keys: "Esc", action: "Back out: menu, prompt, sheet, combo, filter, close" }
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
        comboId = "";
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

    // Colours match on name and hex; combos on their name and their colours'.
    function filter(list, text) {
        const words = String(text || "").toLowerCase().split(/\s+/).filter(word => word.length > 0);

        if (words.length === 0)
            return list;
        return list.filter(item => {
            const haystack = (item.colors ? item.name + " " + item.colors.map(color => color.name + " " + color.hex).join(" ") : item.name + " " + item.hex).toLowerCase();
            return words.every(word => haystack.indexOf(word) >= 0);
        });
    }

    function activeGrid() {
        return view === "combos" ? comboGrid : grid;
    }

    function columns() {
        const target = activeGrid();
        return Math.max(1, Math.floor(target.width / target.cellWidth));
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

    function openCombo() {
        if (view !== "combos" || !selected)
            return;
        comboId = selected.id;
        index = 0;
        confirmDelete = "";
    }

    function closeCombo() {
        const at = palette ? palette.combos.findIndex(item => item.id === comboId) : 0;

        comboId = "";
        index = Math.max(0, at);
        confirmDelete = "";
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
        const target = selected;

        promptMode = "";
        pendingHex = "";
        search.text = query;

        if (mode === "newPalette" || mode === "newPaletteAdd") {
            const paletteId = service.createPalette(value);
            if (mode === "newPaletteAdd" && hex) {
                const newCombo = service.createCombo(paletteId, "");
                service.addToCombo(paletteId, newCombo, hex, "");
                lastTarget = paletteId + "/" + newCombo;
            }
            section = "palette:" + paletteId;
            notice = "Palette created.";
        } else if (mode === "renamePalette" && palette) {
            service.renamePalette(palette.id, value);
        } else if (mode === "renameCombo" && palette && target && view === "combos") {
            service.renameCombo(palette.id, target.id, value);
        } else if (mode === "renameColor" && combo && target) {
            service.renameColor(palette.id, combo.id, target.sourceIndex, value);
        }
    }

    function promptLabel() {
        return ({
                newPalette: "New palette",
                newPaletteAdd: "New palette",
                renamePalette: "Rename palette",
                renameCombo: "Rename combo",
                renameColor: "Rename colour"
            })[promptMode] || "Prism";
    }

    // --- actions ---------------------------------------------------------------------

    function copySelected(stay) {
        if (!selectedColor)
            return;
        service.copy(selectedColor.hex);
        if (stay)
            notice = "Copied " + selectedColor.hex + ".";
        else
            closeRequested();
    }

    // Combos hold work, so they go on the second press; colours at once.
    function removeSelected() {
        if (!selected)
            return;
        if (view === "combos") {
            if (confirmDelete === "combo:" + selected.id) {
                service.deleteCombo(palette.id, selected.id);
                notice = "Deleted " + selected.name + ".";
                confirmDelete = "";
            } else {
                confirmDelete = "combo:" + selected.id;
                notice = "Shift+Delete again deletes " + selected.name + ".";
            }
        } else if (view === "poster") {
            service.removeFromCombo(palette.id, combo.id, selected.sourceIndex);
        } else if (section === "history") {
            service.removeFromHistory(selected.hex);
        } else {
            service.toggleFavorite(selected.hex);
        }
    }

    function newCombo() {
        const id = service.createCombo(palette.id, "");

        comboId = id;
        index = 0;
        lastTarget = palette.id + "/" + id;
        notice = "New combo. Ctrl+P on colours in History or Favourites fills it.";
    }

    function openChooser() {
        const at = chooserOptions.findIndex(option => option.kind === "combo" && option.paletteId + "/" + option.comboId === lastTarget);

        chooserIndex = Math.max(0, at);
        chooserOpen = true;
    }

    function pickChooser(option) {
        chooserOpen = false;
        if (!selectedColor || !option)
            return;
        if (option.kind === "newPalette") {
            pendingHex = selectedColor.hex;
            startPrompt("newPaletteAdd", "");
            return;
        }

        const targetCombo = option.kind === "newCombo" ? service.createCombo(option.paletteId, "") : option.comboId;
        const targetPalette = service.paletteById(option.paletteId);

        service.addToCombo(option.paletteId, targetCombo, selectedColor.hex, selectedColor.name);
        lastTarget = option.paletteId + "/" + targetCombo;
        notice = "Added " + selectedColor.name + " to " + targetPalette.name + " › " + service.comboById(option.paletteId, targetCombo).name + ".";
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
            else if (combo)
                closeCombo();
            else if (search.text.length > 0) {
                search.text = "";
                query = "";
            } else
                closeRequested();
            return;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            event.accepted = true;
            if (view === "combos")
                openCombo();
            else
                copySelected(shift);
            return;
        case Qt.Key_Up:
        case Qt.Key_Down:
        case Qt.Key_Left:
        case Qt.Key_Right:
            {
                const vertical = event.key === Qt.Key_Up || event.key === Qt.Key_Down;
                const step = event.key === Qt.Key_Down || event.key === Qt.Key_Right ? 1 : -1;

                if (ctrl && vertical) {
                    event.accepted = true;
                    stepSection(step);
                } else if (alt && selected && view === "poster") {
                    event.accepted = true;
                    service.moveColor(palette.id, combo.id, selected.sourceIndex, step);
                    move(step);
                } else if (alt && selected && view === "combos") {
                    event.accepted = true;
                    service.moveCombo(palette.id, selected.sourceIndex, step);
                    move(step);
                } else if (view === "poster") {
                    // Bands stack: only ↑↓; ←→ stay with the cursor.
                    if (vertical) {
                        event.accepted = true;
                        move(step);
                    }
                } else {
                    event.accepted = true;
                    move(vertical ? step * columns() : step);
                }
            }
            return;
        case Qt.Key_S:
            if (ctrl && selectedColor) {
                event.accepted = true;
                service.toggleFavorite(selectedColor.hex);
                notice = service.isFavorite(selectedColor.hex) ? selectedColor.name + " is a favourite." : selectedColor.name + " is no longer a favourite.";
            }
            return;
        case Qt.Key_P:
            if (ctrl && selectedColor) {
                event.accepted = true;
                openChooser();
            }
            return;
        case Qt.Key_N:
            if (ctrl) {
                event.accepted = true;
                if (palette && !shift)
                    newCombo();
                else
                    startPrompt("newPalette", "");
            }
            return;
        case Qt.Key_F2:
            event.accepted = true;
            if (shift && palette)
                startPrompt("renamePalette", palette.name);
            else if (view === "combos" && selected)
                startPrompt("renameCombo", selected.name);
            else if (view === "poster" && selected)
                startPrompt("renameColor", selected.name);
            return;
        case Qt.Key_Delete:
            if (ctrl && shift && palette) {
                event.accepted = true;
                if (confirmDelete === "palette:" + palette.id) {
                    const name = palette.name;
                    service.deletePalette(palette.id);
                    section = "history";
                    notice = "Deleted palette " + name + ".";
                } else {
                    confirmDelete = "palette:" + palette.id;
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
        if (view === "combos")
            return "Enter open combo · Ctrl+N new combo · F2 rename · Alt+arrows move · Shift+Del delete combo · F1 shortcuts";
        if (view === "poster")
            return "Enter copy · Shift+Enter copy, stay · F2 rename colour · Alt+↑↓ move · Shift+Del remove · Esc back to " + palette.name + " · F1 shortcuts";
        return "Enter copy · Shift+Enter copy, stay · Ctrl+S favourite · Ctrl+P add to a combo · Shift+Del remove · Ctrl+N new palette · F1 shortcuts";
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: rootPrismPanel.presented = true
    }

    onIndexChanged: {
        if (view === "poster")
            bands.positionViewAtIndex(index, ListView.Contain);
        else
            activeGrid().positionViewAtIndex(index, GridView.Contain);
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
                readonly property string noun: rootPrismPanel.view === "combos" ? " combos" : " colours"

                text: rootPrismPanel.items.length === rootPrismPanel.sourceItems.length ? rootPrismPanel.items.length + noun : rootPrismPanel.items.length + " of " + rootPrismPanel.sourceItems.length + noun
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
                    readonly property bool active: rootPrismPanel.section === modelData.key

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
                        anchors.bottom: parent.bottom
                        width: sidebar.width
                        height: rootPrismPanel.pt.rowHeight
                        radius: rootPrismPanel.pt.rowRadius
                        color: sectionItem.active ? rootPrismPanel.pt.selectedColor : (rowMouse.containsMouse ? rootPrismPanel.pt.hoveredColor : "transparent")
                        border.width: sectionItem.active ? 1 : 0
                        border.color: rootPrismPanel.pt.selectedBorderColor

                        Text {
                            id: rowIcon

                            anchors {
                                left: parent.left
                                leftMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: sectionItem.modelData.icon
                            color: sectionItem.modelData.key === "favorites" ? rootPrismPanel.pt.favoriteColor : rootPrismPanel.pt.accentColor
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
                            text: sectionItem.modelData.label + (sectionItem.modelData.colors ? "  ·  " + sectionItem.modelData.count : "")
                            color: rootPrismPanel.pt.primaryTextColor
                            font.pixelSize: rootPrismPanel.pt.bodyPixelSize
                            font.bold: sectionItem.active
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
                                model: (sectionItem.modelData.colors || []).slice(0, 6)

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
                                visible: !sectionItem.modelData.colors
                                text: sectionItem.modelData.count
                                color: rootPrismPanel.pt.secondaryTextColor
                                font.pixelSize: rootPrismPanel.pt.metaPixelSize
                            }
                        }

                        MouseArea {
                            id: rowMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (rootPrismPanel.section === sectionItem.modelData.key)
                                    rootPrismPanel.comboId = "";
                                rootPrismPanel.section = sectionItem.modelData.key;
                            }
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
                    text: "󰐕  New palette  (Ctrl+Shift+N)"
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

            // Where you are inside a palette.
            Item {
                id: crumb

                width: parent.width
                height: rootPrismPanel.palette !== null ? rootPrismPanel.pt.titlePixelSize + 16 : 0
                visible: rootPrismPanel.palette !== null

                Text {
                    anchors.top: parent.top
                    width: parent.width
                    text: rootPrismPanel.palette ? rootPrismPanel.palette.name + (rootPrismPanel.combo ? "  ›  " + rootPrismPanel.combo.name : "") : ""
                    color: rootPrismPanel.pt.primaryTextColor
                    font.pixelSize: rootPrismPanel.pt.titlePixelSize
                    font.bold: true
                    elide: Text.ElideRight
                }
            }

            Item {
                id: content

                anchors {
                    left: parent.left
                    right: parent.right
                    top: crumb.bottom
                    bottom: parent.bottom
                }

                // Favourites / History: colour swatches.
                GridView {
                    id: grid

                    anchors.fill: parent
                    visible: rootPrismPanel.view === "colors"
                    clip: true
                    model: rootPrismPanel.view === "colors" ? rootPrismPanel.items : []
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

                // A palette: its combos as small posters.
                GridView {
                    id: comboGrid

                    anchors.fill: parent
                    visible: rootPrismPanel.view === "combos"
                    clip: true
                    model: rootPrismPanel.view === "combos" ? rootPrismPanel.items : []
                    cellWidth: rootPrismPanel.pt.comboWidth + rootPrismPanel.pt.swatchGap
                    cellHeight: rootPrismPanel.pt.comboHeight + rootPrismPanel.pt.swatchLabelHeight + rootPrismPanel.pt.swatchGap
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: Math.max(0, rootPrismPanel.index)
                    highlightFollowsCurrentItem: false

                    delegate: Item {
                        id: comboCard

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === rootPrismPanel.index

                        width: comboGrid.cellWidth - rootPrismPanel.pt.swatchGap
                        height: comboGrid.cellHeight - rootPrismPanel.pt.swatchGap

                        PrismPoster {
                            id: miniPoster

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            height: rootPrismPanel.pt.comboHeight
                            pt: rootPrismPanel.pt
                            service: rootPrismPanel.service
                            colors: comboCard.modelData.colors
                            compact: true
                            radius: rootPrismPanel.pt.swatchRadius
                        }

                        Rectangle {
                            anchors.fill: miniPoster
                            anchors.margins: -4
                            visible: comboCard.isSelected || cardMouse.containsMouse
                            color: "transparent"
                            radius: rootPrismPanel.pt.swatchRadius + 3
                            border.width: comboCard.isSelected ? 2 : 1
                            border.color: comboCard.isSelected ? rootPrismPanel.pt.selectedBorderColor : rootPrismPanel.pt.borderColor
                        }

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: miniPoster.bottom
                                topMargin: 8
                            }
                            text: comboCard.modelData.name + "  ·  " + comboCard.modelData.colors.length + (comboCard.modelData.colors.length === 1 ? " colour" : " colours")
                            color: comboCard.isSelected ? rootPrismPanel.pt.primaryTextColor : rootPrismPanel.pt.secondaryTextColor
                            font.pixelSize: rootPrismPanel.pt.bodyPixelSize
                            font.bold: comboCard.isSelected
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: cardMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootPrismPanel.index = comboCard.index
                            onDoubleClicked: {
                                rootPrismPanel.index = comboCard.index;
                                rootPrismPanel.openCombo();
                            }
                        }
                    }
                }

                // One combo, full size: bands you can move through.
                ListView {
                    id: bands

                    anchors.fill: parent
                    visible: rootPrismPanel.view === "poster"
                    clip: true
                    model: rootPrismPanel.view === "poster" ? rootPrismPanel.items : []
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: Math.max(0, rootPrismPanel.index)
                    highlightFollowsCurrentItem: false

                    delegate: PrismBand {
                        required property var modelData
                        required property int index

                        width: bands.width
                        height: Math.max(rootPrismPanel.pt.bandMinHeight, Math.floor(bands.height / Math.max(1, rootPrismPanel.items.length)))
                        pt: rootPrismPanel.pt
                        hex: modelData.hex
                        name: modelData.name
                        ink: rootPrismPanel.service.textOn(modelData.hex, rootPrismPanel.combo ? rootPrismPanel.combo.colors : null)
                        titlePixelSize: rootPrismPanel.pt.bandTitlePixelSize
                        selected: index === rootPrismPanel.index
                        favorite: rootPrismPanel.service.isFavorite(modelData.hex)
                        iconFont: rootPrismPanel.theme.iconFontFamily
                        radius: index === 0 || index === rootPrismPanel.items.length - 1 ? rootPrismPanel.pt.swatchRadius : 0

                        onClicked: rootPrismPanel.index = index
                        onDoubleClicked: {
                            rootPrismPanel.index = index;
                            rootPrismPanel.copySelected(false);
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
                        : rootPrismPanel.sourceItems.length > 0 ? "Nothing matches."
                        : rootPrismPanel.view === "poster" ? "An empty combo. Ctrl+P on a colour in History or Favourites adds it here."
                        : rootPrismPanel.view === "combos" ? "No combos yet. Ctrl+N makes one, or Ctrl+P on any colour."
                        : rootPrismPanel.section === "favorites" ? "No favourites yet. Ctrl+S on a colour makes it one."
                        : "No colours yet. Pick one with Super+P, or copy one (#hex, rgb(), hsl()); both land here."
                    color: rootPrismPanel.service.lastError.length > 0 ? rootPrismPanel.pt.errorColor : rootPrismPanel.pt.secondaryTextColor
                    font.pixelSize: rootPrismPanel.pt.bodyPixelSize + 1
                }
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

        // --- Ctrl+P: which combo gets the colour -------------------------------------
        Rectangle {
            anchors.centerIn: parent
            width: 460
            height: Math.min(card.height - 80, chooserColumn.implicitHeight + 28)
            visible: rootPrismPanel.chooserOpen
            radius: rootPrismPanel.pt.swatchRadius
            color: rootPrismPanel.pt.sheetColor
            border.width: 1
            border.color: rootPrismPanel.pt.selectedBorderColor
            clip: true

            Column {
                id: chooserColumn

                anchors {
                    fill: parent
                    margins: 14
                }
                spacing: 4

                Text {
                    bottomPadding: 6
                    text: "Add " + (rootPrismPanel.selectedColor ? rootPrismPanel.selectedColor.name : "") + " to"
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
                                right: optionDots.left
                                rightMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            text: optionRow.modelData.label
                            color: optionRow.modelData.kind === "combo" ? rootPrismPanel.pt.primaryTextColor : rootPrismPanel.pt.secondaryTextColor
                            font.pixelSize: rootPrismPanel.pt.bodyPixelSize
                            elide: Text.ElideRight
                        }

                        Row {
                            id: optionDots

                            anchors {
                                right: parent.right
                                rightMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: -4

                            Repeater {
                                model: optionRow.modelData.colors.slice(0, 6)

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
                width: 600
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
