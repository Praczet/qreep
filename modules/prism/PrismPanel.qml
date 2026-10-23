import QtQuick
import Quickshell

// Prism window: a normal Hyprland window (move, resize, float), one card.
// Sidebar on the left (Favourites, History, palettes), the selected section
// on the right:
//   Favourites / History  a grid of colour swatches
//   a palette             a grid of combo posters
//   a combo (Enter)       that combo full size: one band per colour,
//                         lettered in the combo colour that reads best
FloatingWindow {
    id: rootPrismPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen
    property string requestedSection: ""
    property string requestedUniverse: ""

    readonly property QtObject pt: theme.modules.prism

    // "favorites" | "history" | "palette:<id>"
    property string section: "history"
    // An open combo inside the palette section; "" shows the combo grid.
    property string comboId: ""
    // The universe (editor) over whatever section is underneath.
    property bool universeOpen: false
    // Ctrl+P / "save as combo" from the universe: a whole harmony at once.
    property var pendingHarmony: null
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
    // The chooser shows "actions" (click on a colour, Ctrl+Enter) or "add"
    // (which combo gets the colour, Ctrl+P).
    property string chooserMode: "add"
    property string lastTarget: ""
    // Things deleted on the second press: "palette:<id>" or "combo:<id>".
    property string confirmDelete: ""

    readonly property var palette: section.indexOf("palette:") === 0 ? service.paletteById(section.slice(8)) : null
    readonly property var combo: palette && comboId.length > 0 ? palette.combos.find(item => item.id === comboId) || null : null
    // "universe" | "colors" | "combos" | "poster"
    readonly property string view: universeOpen ? "universe" : combo ? "poster" : palette ? "combos" : "colors"
    readonly property var sourceItems: view === "universe" ? [] : view === "poster" ? combo.colors : view === "combos" ? palette.combos : section === "favorites" ? service.favoriteEntries() : service.history
    // Filtered; each keeps its index in the section (sourceIndex) for edits.
    readonly property var items: filter(sourceItems.map((item, i) => Object.assign({ sourceIndex: i }, item)), query)
    readonly property var selected: items.length > 0 ? items[Math.max(0, Math.min(index, items.length - 1))] : null
    // The selected colour, wherever it is (not in the combo grid). In the
    // universe it is the colour being edited.
    readonly property var selectedColor: view === "universe" ? ({ hex: universe.hex, name: service.nameOf(universe.hex) }) : view === "combos" ? null : selected
    readonly property var sections: [
        { key: "favorites", label: "Favourites", icon: "󰓎", count: service.favorites.length },
        { key: "history", label: "History", icon: "󰋚", count: service.history.length }
    ].concat(service.palettes.reduce((rows, item) => {
        const expanded = service.isExpanded(item.id);

        rows.push({
            key: "palette:" + item.id,
            kind: "palette",
            paletteId: item.id,
            expanded: expanded,
            label: item.name,
            icon: "󰏘",
            count: item.combos.length,
            colors: item.combos.reduce((all, entry) => all.concat(entry.colors), [])
        });
        // Expanded: the palette's combos as rows under it.
        if (expanded) {
            for (const entry of item.combos)
                rows.push({
                    key: "combo:" + item.id + ":" + entry.id,
                    kind: "combo",
                    paletteId: item.id,
                    comboId: entry.id,
                    label: entry.name,
                    icon: "",
                    count: entry.colors.length,
                    colors: entry.colors
                });
        }
        return rows;
    }, []))
    // The sidebar row that is "here": a combo row when a combo is open.
    readonly property string currentKey: combo ? "combo:" + palette.id + ":" + combo.id : section
    readonly property var chooserOptions: chooserMode === "actions" ? (view === "universe" ? actionOptions.filter(option => option.action !== "universe") : actionOptions) : chooserMode === "harmony" ? harmonyOptions : addOptions
    // Where a saved harmony goes: a new combo in a palette, or a new palette.
    readonly property var harmonyOptions: service.palettes.map(item => ({ kind: "newCombo", paletteId: item.id, comboId: "", label: item.name + "  ›  New combo", colors: [] })).concat([{ kind: "newPalette", paletteId: "", comboId: "", label: "New palette…", colors: [] }])
    readonly property var actionOptions: selectedColor ? [
        { kind: "action", action: "copyClose", label: "Copy " + selectedColor.hex + " and close", hint: "Enter", colors: [] },
        { kind: "action", action: "copy", label: "Copy, stay open", hint: "Shift+Enter", colors: [] },
        { kind: "action", action: "rgb", label: "Copy as " + service.formatColor(selectedColor.hex, "rgb"), hint: "", colors: [] },
        { kind: "action", action: "hsl", label: "Copy as " + service.formatColor(selectedColor.hex, "hsl"), hint: "", colors: [] },
        { kind: "action", action: "qt", label: "Copy as " + service.formatColor(selectedColor.hex, "qt"), hint: "", colors: [] },
        { kind: "action", action: "hypr", label: "Copy as " + service.formatColor(selectedColor.hex, "hypr") + "  (Hyprland)", hint: "", colors: [] },
        { kind: "action", action: "favorite", label: service.isFavorite(selectedColor.hex) ? "󰓎  Unfavourite" : "󰓒  Favourite", hint: "Ctrl+S", colors: [] },
        { kind: "action", action: "add", label: "Add to a combo…", hint: "Ctrl+P", colors: [] },
        // Step 2: wheels, sliders, harmonies.
        { kind: "action", action: "universe", label: "Open the universe", hint: "Ctrl+E", colors: [] }
    ] : []
    readonly property var addOptions: {
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
        { keys: "Ctrl+Enter, click", action: "Actions: copy as rgb / hsl / Qt.rgba, favourite, add…" },
        { keys: "Ctrl+S", action: "Favourite / unfavourite" },
        { keys: "Ctrl+P", action: "Add the colour to a combo" },
        { keys: "drag any colour", action: "Onto a combo: add · palette: new combo · Favourites" },
        { keys: "Shift+Delete", action: "Remove (a combo: press twice)" },
        { keys: "Ctrl+1  Ctrl+2", action: "Favourites, History" },
        { keys: "Ctrl+3", action: "First palette" },
        { keys: "Ctrl+↑ Ctrl+↓", action: "Previous / next in the sidebar (combos too)" },
        { keys: "Ctrl+→ Ctrl+←", action: "Unfold / fold the palette" },
        { keys: "Ctrl+N", action: "New combo (in a palette), else new palette" },
        { keys: "Ctrl+Shift+N", action: "New palette" },
        { keys: "F2", action: "Rename the colour / the combo" },
        { keys: "Shift+F2", action: "Rename the palette" },
        { keys: "Alt+arrows", action: "Move the colour / combo" },
        { keys: "Ctrl+Shift+Delete", action: "Delete the palette (twice)" },
        { keys: "Ctrl+E", action: "Open the universe (editor) on the colour" },
        { keys: "universe: ←→ ↑↓", action: "Hue, value (Alt+↑↓ saturation, Shift ×10)" },
        { keys: "universe: type", action: "Jump to a typed colour" },
        { keys: "F1", action: "This sheet" },
        { keys: "Esc", action: "Back out: menu, prompt, sheet, combo, filter, close" }
    ]

    signal closeRequested

    // The monitor that had focus on open. Only the first size comes from it;
    // after that Hyprland owns size and position, like Triage.
    property var targetScreen: null

    title: "Qreep Prism"
    implicitWidth: rootPrismPanel.pt.panelWidthFor(targetScreen ? targetScreen.width : 1920, targetScreen ? targetScreen.height : 1080)
    implicitHeight: rootPrismPanel.pt.panelHeightFor(targetScreen ? targetScreen.width : 1920, targetScreen ? targetScreen.height : 1080)

    color: "transparent"
    surfaceFormat.opaque: false

    onClosed: rootPrismPanel.closeRequested()

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

    // Moving somewhere else closes the menu: it belongs to the colour that
    // was selected, and a palette view has no colour selected at all.
    onSectionChanged: {
        comboId = "";
        index = 0;
        confirmDelete = "";
        chooserOpen = false;
        universeOpen = false;
    }
    onComboIdChanged: chooserOpen = false
    onSelectedColorChanged: {
        if (!selectedColor)
            chooserOpen = false;
    }

    function opened() {
        if (requestedSection.length > 0)
            selectKey(requestedSection);
        query = "";
        search.text = "";
        index = 0;
        notice = "";
        search.forceActiveFocus();
        if (requestedUniverse.length > 0) {
            universe.open(requestedUniverse);
            universeOpen = true;
        }
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
        const at = Math.max(0, keys.indexOf(currentKey));

        selectKey(keys[Math.max(0, Math.min(keys.length - 1, at + step))]);
    }

    // A sidebar row: a section, or "combo:<palette>:<combo>" (opens it).
    // Choosing a palette unfolds it.
    function selectKey(key) {
        // Going anywhere from the sidebar leaves the universe.
        universeOpen = false;
        if (key.indexOf("combo:") === 0) {
            const parts = key.split(":");
            section = "palette:" + parts[1];
            comboId = parts[2];
            index = 0;
            return;
        }
        if (section === key)
            comboId = "";
        section = key;
        if (key.indexOf("palette:") === 0)
            service.setExpanded(key.slice(8), true);
    }

    // --- dragging a colour (any swatch, band or universe box) -------------------
    // A MouseArea with drag.target: dragGhost calls these three; the ghost
    // carries hex and name to the sidebar's DropAreas.
    function dragPress(area, mouse, hex, name) {
        const at = area.mapToItem(dragGhost.parent, mouse.x, mouse.y);
        dragGhost.wasDragged = false;
        dragGhost.hex = hex;
        dragGhost.name = name;
        dragGhost.x = at.x - dragGhost.width / 2;
        dragGhost.y = at.y - dragGhost.height / 2;
    }

    function dragMove(area) {
        if (area.drag.active && !dragGhost.Drag.active) {
            chooserOpen = false;
            dragGhost.Drag.active = true;
        }
    }

    function dragRelease() {
        if (dragGhost.Drag.active) {
            dragGhost.Drag.drop();
            dragGhost.Drag.active = false;
            dragGhost.wasDragged = true;
        }
    }

    // A click that ends a drag is not a click.
    function consumeDragClick() {
        if (!dragGhost.wasDragged)
            return false;
        dragGhost.wasDragged = false;
        return true;
    }

    // A colour dropped on a sidebar row: a combo gets it, a palette gets a
    // new combo with it, Favourites makes it a favourite.
    function dropColor(row, hex, name) {
        if (row.kind === "combo") {
            service.addToCombo(row.paletteId, row.comboId, hex, name);
            lastTarget = row.paletteId + "/" + row.comboId;
            notice = "Added " + name + " to " + row.label + ".";
        } else if (row.kind === "palette") {
            const id = service.createCombo(row.paletteId, "");
            service.addToCombo(row.paletteId, id, hex, name);
            service.setExpanded(row.paletteId, true);
            lastTarget = row.paletteId + "/" + id;
            notice = "New combo in " + row.label + " with " + name + ".";
        } else if (row.key === "favorites") {
            if (!service.isFavorite(hex))
                service.toggleFavorite(hex);
            notice = name + " is a favourite.";
        }
    }

    // Double click on a combo in the sidebar: rename it from the combo grid.
    function renameComboFromTree(paletteId, id) {
        section = "palette:" + paletteId;
        comboId = "";
        const at = palette ? palette.combos.findIndex(item => item.id === id) : -1;
        if (at < 0)
            return;
        query = "";
        search.text = "";
        index = at;
        startPrompt("renameCombo", palette.combos[at].name);
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

        if (mode === "newPaletteHarmony" && pendingHarmony) {
            storeHarmony(service.createPalette(value));
        } else if (mode === "newPalette" || mode === "newPaletteAdd") {
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
                newPaletteHarmony: "New palette",
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

    function openUniverse() {
        if (!selectedColor || view === "universe")
            return;
        universe.open(selectedColor.hex);
        chooserOpen = false;
        cancelPrompt();
        universeOpen = true;
        search.text = "";
        notice = "";
    }

    function closeUniverse() {
        universeOpen = false;
        chooserOpen = false;
        search.text = query;
    }

    function saveHarmony(colors, label) {
        pendingHarmony = { colors: colors, label: label };
        chooserMode = "harmony";
        chooserIndex = 0;
        chooserOpen = true;
    }

    // A harmony into a combo of its own (named after the harmony).
    function storeHarmony(paletteId) {
        const id = service.createCombo(paletteId, pendingHarmony.label);
        for (const hex of pendingHarmony.colors)
            service.addToCombo(paletteId, id, hex, "");
        service.setExpanded(paletteId, true);
        notice = "Saved " + pendingHarmony.label + " to " + service.paletteById(paletteId).name + ".";
        pendingHarmony = null;
    }

    function openActions() {
        if (!selectedColor)
            return;
        chooserMode = "actions";
        chooserIndex = 0;
        chooserOpen = true;
    }

    function runAction(action) {
        const color = selectedColor;

        chooserOpen = false;
        if (!color)
            return;
        if (action === "copyClose") {
            copySelected(false);
        } else if (action === "copy") {
            copySelected(true);
        } else if (action === "rgb" || action === "hsl" || action === "qt" || action === "hypr") {
            const text = service.formatColor(color.hex, action);
            service.copy(text);
            notice = "Copied " + text + ".";
        } else if (action === "favorite") {
            service.toggleFavorite(color.hex);
            notice = service.isFavorite(color.hex) ? color.name + " is a favourite." : color.name + " is no longer a favourite.";
        } else if (action === "add") {
            openChooser();
        } else if (action === "universe") {
            openUniverse();
        }
    }

    function openChooser() {
        chooserMode = "add";
        const at = addOptions.findIndex(option => option.kind === "combo" && option.paletteId + "/" + option.comboId === lastTarget);

        chooserIndex = Math.max(0, at);
        chooserOpen = true;
    }

    function pickChooser(option) {
        if (option && option.kind === "action") {
            if (!option.disabled)
                runAction(option.action);
            return;
        }
        if (chooserMode === "harmony" && option && pendingHarmony) {
            chooserOpen = false;
            if (option.kind === "newPalette")
                startPrompt("newPaletteHarmony", pendingHarmony.label);
            else
                storeHarmony(option.paletteId);
            return;
        }
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
            else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9 && event.key - Qt.Key_1 < chooserOptions.length)
                pickChooser(chooserOptions[event.key - Qt.Key_1]);
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

        if (ctrl && event.key === Qt.Key_E) {
            event.accepted = true;
            openUniverse();
            return;
        }

        // In the universe: Esc goes back, arrows move through colour space.
        if (view === "universe") {
            const big = shift ? 10 : 1;
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                if (shortcutsOpen)
                    shortcutsOpen = false;
                else
                    closeUniverse();
                return;
            }
            if (!ctrl && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
                event.accepted = true;
                universe.nudge((event.key === Qt.Key_Right ? 1 : -1) * big, 0, 0);
                return;
            }
            if (!ctrl && (event.key === Qt.Key_Up || event.key === Qt.Key_Down)) {
                event.accepted = true;
                const step = (event.key === Qt.Key_Up ? 1 : -1) * big / 100;
                if (alt)
                    universe.nudge(0, step, 0);
                else
                    universe.nudge(0, 0, step);
                return;
            }
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
            if (ctrl && view !== "combos")
                openActions();
            else if (view === "combos")
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
                } else if (ctrl && palette) {
                    // Ctrl+→ unfolds the palette in the sidebar, Ctrl+← folds it.
                    event.accepted = true;
                    service.setExpanded(palette.id, step > 0);
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
        if (view === "universe" && !chooserOpen)
            return "←→ hue · ↑↓ value · Alt+↑↓ saturation (Shift: ×10) · type a colour · Enter copy · Ctrl+Enter more · Ctrl+S favourite · Ctrl+P add to combo · Esc back";
        if (chooserOpen)
            return "↑↓ or 1–9 choose · Enter " + (chooserMode === "actions" ? "do it" : "add") + " · Esc cancel";
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
        id: card

        anchors.fill: parent
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

        Behavior on scale {
            NumberAnimation {
                duration: rootPrismPanel.pt.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        // A click on the card closes an open menu.
        MouseArea {
            anchors.fill: parent
            onClicked: rootPrismPanel.chooserOpen = false
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
                    if (rootPrismPanel.universeOpen) {
                        const typed = rootPrismPanel.service.parseColor(text);
                        if (typed)
                            universe.setHex(typed);
                        return;
                    }
                    rootPrismPanel.query = text;
                    rootPrismPanel.index = 0;
                }
                Keys.onPressed: event => rootPrismPanel.handleKey(event)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text.length === 0
                    text: rootPrismPanel.promptMode.length > 0 ? "a name, Enter to save" : rootPrismPanel.universeOpen ? "type a colour: #hex, rgb(), hsl(), rgba(rrggbbaa)" : "type to filter by name or hex"
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

                visible: !rootPrismPanel.universeOpen

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
                    readonly property bool isCombo: modelData.kind === "combo"
                    readonly property bool active: rootPrismPanel.currentKey === modelData.key

                    width: sidebar.width
                    height: (isCombo ? rootPrismPanel.pt.rowHeight - 8 : rootPrismPanel.pt.rowHeight) + (hasHeading ? 28 : 0)

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
                        anchors.right: parent.right
                        width: sectionItem.isCombo ? sidebar.width - 22 : sidebar.width
                        height: sectionItem.isCombo ? rootPrismPanel.pt.rowHeight - 8 : rootPrismPanel.pt.rowHeight
                        radius: rootPrismPanel.pt.rowRadius
                        readonly property bool dropTarget: rowDrop.containsDrag && sectionItem.modelData.key !== "history"

                        color: dropTarget ? rootPrismPanel.pt.selectedColor : sectionItem.active ? rootPrismPanel.pt.selectedColor : (rowMouse.containsMouse ? rootPrismPanel.pt.hoveredColor : "transparent")
                        border.width: dropTarget ? 2 : sectionItem.active ? 1 : 0
                        border.color: dropTarget ? rootPrismPanel.pt.favoriteColor : rootPrismPanel.pt.selectedBorderColor

                        DropArea {
                            id: rowDrop

                            anchors.fill: parent
                            keys: ["prism-color"]
                            enabled: sectionItem.modelData.key !== "history"
                            onDropped: drop => {
                                rootPrismPanel.dropColor(sectionItem.modelData, drop.source.hex, drop.source.name);
                                drop.accept();
                            }
                        }

                        // Palettes fold: the chevron toggles without opening the palette.
                        Text {
                            id: chevron

                            anchors {
                                left: parent.left
                                leftMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            width: sectionItem.modelData.kind === "palette" ? 14 : 0
                            visible: sectionItem.modelData.kind === "palette"
                            // Above the row's own MouseArea (declared later), or the
                            // row would take the click and only ever unfold.
                            z: 1
                            text: sectionItem.modelData.expanded ? "▾" : "▸"
                            color: rootPrismPanel.pt.secondaryTextColor
                            font.pixelSize: rootPrismPanel.pt.bodyPixelSize

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootPrismPanel.service.setExpanded(sectionItem.modelData.paletteId, !sectionItem.modelData.expanded)
                            }
                        }

                        Text {
                            id: rowIcon

                            anchors {
                                left: chevron.right
                                leftMargin: sectionItem.modelData.kind === "palette" ? 4 : 4
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
                            text: sectionItem.modelData.label + (sectionItem.modelData.kind === "palette" ? "  ·  " + sectionItem.modelData.count : "")
                            color: sectionItem.isCombo && !sectionItem.active ? rootPrismPanel.pt.secondaryTextColor : rootPrismPanel.pt.primaryTextColor
                            font.pixelSize: sectionItem.isCombo ? rootPrismPanel.pt.bodyPixelSize - 1 : rootPrismPanel.pt.bodyPixelSize
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
                                    color: rootPrismPanel.service.display(modelData.hex)
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
                            onClicked: rootPrismPanel.selectKey(sectionItem.modelData.key)
                            onDoubleClicked: {
                                if (sectionItem.isCombo)
                                    rootPrismPanel.renameComboFromTree(sectionItem.modelData.paletteId, sectionItem.modelData.comboId);
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
                height: rootPrismPanel.palette !== null || rootPrismPanel.universeOpen ? rootPrismPanel.pt.titlePixelSize + 16 : 0
                visible: rootPrismPanel.palette !== null || rootPrismPanel.universeOpen

                Text {
                    anchors.top: parent.top
                    width: parent.width
                    text: rootPrismPanel.universeOpen ? "󰐱  Universe" : rootPrismPanel.palette ? rootPrismPanel.palette.name + (rootPrismPanel.combo ? "  ›  " + rootPrismPanel.combo.name : "") : ""
                    font.family: rootPrismPanel.universeOpen ? rootPrismPanel.theme.iconFontFamily : Qt.application.font.family
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

                PrismUniverse {
                    id: universe

                    anchors.fill: parent
                    visible: rootPrismPanel.universeOpen
                    pt: rootPrismPanel.pt
                    service: rootPrismPanel.service
                    iconFont: rootPrismPanel.theme.iconFontFamily
                    dragGhost: dragGhost
                    dragHost: rootPrismPanel

                    onCopyRequested: text => {
                        rootPrismPanel.service.copy(text);
                        rootPrismPanel.notice = "Copied " + text + ".";
                    }
                    onSaveHarmony: (colors, label) => rootPrismPanel.saveHarmony(colors, label)
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
                            color: rootPrismPanel.service.display(swatch.modelData.hex)
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
                            cursorShape: dragGhost.Drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                            // Dragging moves the ghost swatch; drop it on a sidebar row.
                            drag.target: dragGhost
                            drag.threshold: 10
                            // The grid flicks on drag too; the swatch drag wins.
                            preventStealing: true

                            onPressed: mouse => rootPrismPanel.dragPress(swatchMouse, mouse, swatch.modelData.hex, swatch.modelData.name)
                            onPositionChanged: rootPrismPanel.dragMove(swatchMouse)
                            onReleased: rootPrismPanel.dragRelease()
                            // One click: the actions menu; double click: copy and close.
                            onClicked: {
                                if (rootPrismPanel.consumeDragClick())
                                    return;
                                rootPrismPanel.index = swatch.index;
                                rootPrismPanel.openActions();
                            }
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

                        // Inset, so the selection outline around it stays inside the cell.
                        PrismPoster {
                            id: miniPoster

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 4
                            }
                            height: rootPrismPanel.pt.comboHeight - 8
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
                            radius: rootPrismPanel.pt.swatchRadius + 4
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
                        dragGhost: dragGhost
                        dragHost: rootPrismPanel
                        // Round only the poster's outer corners, not where bands meet.
                        topLeftRadius: index === 0 ? rootPrismPanel.pt.swatchRadius : 0
                        topRightRadius: index === 0 ? rootPrismPanel.pt.swatchRadius : 0
                        bottomLeftRadius: index === rootPrismPanel.items.length - 1 ? rootPrismPanel.pt.swatchRadius : 0
                        bottomRightRadius: index === rootPrismPanel.items.length - 1 ? rootPrismPanel.pt.swatchRadius : 0

                        onClicked: {
                            rootPrismPanel.index = index;
                            rootPrismPanel.openActions();
                        }
                        onDoubleClicked: {
                            rootPrismPanel.index = index;
                            rootPrismPanel.copySelected(false);
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width * 0.7
                    visible: rootPrismPanel.items.length === 0 && !rootPrismPanel.universeOpen
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

        // --- drag ghost: the swatch being dragged to a combo -------------------------
        Rectangle {
            id: dragGhost

            property string hex: "#000000"
            property string name: ""
            property bool wasDragged: false

            width: 56
            height: 56
            radius: 12
            visible: Drag.active
            color: rootPrismPanel.service.display(hex)
            border.width: 2
            border.color: rootPrismPanel.pt.selectedBorderColor
            z: 100
            Drag.keys: ["prism-color"]
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2
        }

        // --- Ctrl+P: which combo gets the colour -------------------------------------
        Rectangle {
            anchors.centerIn: parent
            width: 460
            height: Math.min(card.height - 80, chooserColumn.implicitHeight + 28)
            visible: rootPrismPanel.chooserOpen && rootPrismPanel.selectedColor !== null
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

                // Header: the colour, its name, and whether it is a favourite.
                Item {
                    width: chooserColumn.width
                    height: 30

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 5
                            color: rootPrismPanel.selectedColor ? rootPrismPanel.service.display(rootPrismPanel.selectedColor.hex) : "transparent"
                            border.width: 1
                            border.color: rootPrismPanel.pt.borderColor
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (rootPrismPanel.selectedColor ? rootPrismPanel.selectedColor.name : "") + (rootPrismPanel.chooserMode === "actions" ? "" : ": add to")
                            color: rootPrismPanel.pt.sectionColor
                            font.pixelSize: rootPrismPanel.pt.bodyPixelSize
                            font.bold: true
                        }
                    }

                    Rectangle {
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        visible: rootPrismPanel.selectedColor !== null && rootPrismPanel.service.isFavorite(rootPrismPanel.selectedColor.hex)
                        width: favoriteTag.implicitWidth + 16
                        height: 22
                        radius: 11
                        color: rootPrismPanel.pt.chipColor
                        border.width: 1
                        border.color: rootPrismPanel.pt.favoriteColor

                        Text {
                            id: favoriteTag

                            anchors.centerIn: parent
                            text: "󰓎  favourite"
                            color: rootPrismPanel.pt.favoriteColor
                            font.family: rootPrismPanel.theme.iconFontFamily
                            font.pixelSize: rootPrismPanel.pt.metaPixelSize
                        }
                    }
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
                            text: (optionRow.index < 9 ? (optionRow.index + 1) + "   " : "    ") + optionRow.modelData.label
                            color: optionRow.modelData.disabled ? rootPrismPanel.pt.secondaryTextColor : optionRow.modelData.kind === "combo" || optionRow.modelData.kind === "action" ? rootPrismPanel.pt.primaryTextColor : rootPrismPanel.pt.secondaryTextColor
                            opacity: optionRow.modelData.disabled ? 0.55 : 1
                            // The nerd-font star needs the icon font; other rows keep the UI font.
                            font.family: optionRow.modelData.action === "favorite" ? rootPrismPanel.theme.iconFontFamily : Qt.application.font.family
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

                            Text {
                                visible: (optionRow.modelData.hint || "").length > 0
                                text: optionRow.modelData.hint || ""
                                color: rootPrismPanel.pt.secondaryTextColor
                                font.pixelSize: rootPrismPanel.pt.metaPixelSize
                            }

                            Repeater {
                                model: optionRow.modelData.colors.slice(0, 6)

                                Rectangle {
                                    required property var modelData

                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: rootPrismPanel.service.display(modelData.hex)
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
