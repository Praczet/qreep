import QtQuick
import Quickshell
import Quickshell.Io

// Prism's data: picked and copied colours (history), favourites, palettes.
// Colours arrive two ways: pick() runs hyprpicker, and a wl-paste watcher
// adds any clipboard text that is a colour (#hex, rgb(), hsl()). Both land
// in history, one entry per colour, newest first. Everything is one JSON
// file; Qreep is its only writer.
Item {
    id: rootPrismService

    required property QtObject theme

    readonly property QtObject pt: theme.modules.prism

    // [{ hex, name, time, source: "pick" | "clipboard" | "saved" }]
    property var history: []
    // [hex]
    property var favorites: []
    // [{ id, name, combos: [{ id, name, colors: [{ hex, name }] }] }]
    // A palette is a set of combos; a combo is one or more colours that go
    // together (the poster: Timberwolf on American Brown).
    property var palettes: []
    property bool loaded: false
    property string lastError: ""

    signal picked(string hex)

    PrismNames {
        id: names
    }

    // --- colours ---------------------------------------------------------------

    // "#rrggbb" (or "#rrggbbaa" when not opaque), lowercase; "" if text is
    // not a colour. Named colours are left out on purpose: copying the word
    // "red" is not picking a colour. Hyprland's own forms count:
    // rgba(rrggbbaa), rgb(rrggbb) and the legacy 0xaarrggbb.
    function parseColor(text) {
        const value = String(text || "").trim().toLowerCase();
        let match = /^rgba?\(([0-9a-f]{6}|[0-9a-f]{8})\)$/.exec(value);

        if (match)
            return normalizeHex("#" + match[1]);

        match = /^0x([0-9a-f]{8})$/.exec(value);
        if (match)
            return normalizeHex("#" + match[1].slice(2) + match[1].slice(0, 2));

        match = /^#([0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/.exec(value);

        if (match) {
            let digits = match[1];
            if (digits.length <= 4)
                digits = digits.split("").map(digit => digit + digit).join("");
            return normalizeHex("#" + digits);
        }

        match = /^rgba?\(\s*([\d.]+%?)\s*[, ]\s*([\d.]+%?)\s*[, ]\s*([\d.]+%?)\s*(?:[,/]\s*([\d.]+%?)\s*)?\)$/.exec(value);
        if (match) {
            const channel = part => part.endsWith("%") ? parseFloat(part) * 2.55 : parseFloat(part);
            return rgbToHex(channel(match[1]), channel(match[2]), channel(match[3]), match[4] !== undefined ? alphaOf(match[4]) : 1);
        }

        match = /^hsla?\(\s*([\d.]+)(?:deg)?\s*[, ]\s*([\d.]+)%\s*[, ]\s*([\d.]+)%\s*(?:[,/]\s*([\d.]+%?)\s*)?\)$/.exec(value);
        if (match) {
            const rgb = hslToRgb(parseFloat(match[1]), parseFloat(match[2]) / 100, parseFloat(match[3]) / 100);
            return rgbToHex(rgb[0], rgb[1], rgb[2], match[4] !== undefined ? alphaOf(match[4]) : 1);
        }

        return "";
    }

    // Qt reads 8-digit hex as #aarrggbb; Prism stores #rrggbbaa (CSS).
    function display(hex) {
        return hex && hex.length === 9 ? "#" + hex.slice(7, 9) + hex.slice(1, 7) : hex;
    }

    // Hyprland's notation: rgba(rrggbbaa).
    function hyprColor(hex) {
        return "rgba(" + hex.slice(1, 7) + (hex.length === 9 ? hex.slice(7, 9) : "ff") + ")";
    }

    function alphaOf(part) {
        return part.endsWith("%") ? parseFloat(part) / 100 : parseFloat(part);
    }

    function normalizeHex(hex) {
        const value = hex.toLowerCase();
        return value.length === 9 && value.endsWith("ff") ? value.slice(0, 7) : value;
    }

    function rgbToHex(r, g, b, a) {
        const byte = value => Math.max(0, Math.min(255, Math.round(value))).toString(16).padStart(2, "0");
        return normalizeHex("#" + byte(r) + byte(g) + byte(b) + byte((a === undefined ? 1 : a) * 255));
    }

    function hslToRgb(h, s, l) {
        const k = n => (n + h / 30) % 12;
        const a = s * Math.min(l, 1 - l);
        const f = n => l - a * Math.max(-1, Math.min(k(n) - 3, Math.min(9 - k(n), 1)));
        return [f(0) * 255, f(8) * 255, f(4) * 255];
    }

    function rgbOf(hex) {
        return [parseInt(hex.slice(1, 3), 16), parseInt(hex.slice(3, 5), 16), parseInt(hex.slice(5, 7), 16)];
    }

    // WCAG relative luminance, 0..1.
    function luminance(hex) {
        const channel = value => {
            const c = value / 255;
            return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
        };
        const rgb = rgbOf(hex);
        return 0.2126 * channel(rgb[0]) + 0.7152 * channel(rgb[1]) + 0.0722 * channel(rgb[2]);
    }

    function contrast(a, b) {
        const la = luminance(a);
        const lb = luminance(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    // Text on a band: the combo colour that reads best on it (the poster
    // look: Timberwolf in American Brown), or near-black / near-white when
    // nothing in the combo clears 3:1. colors: [{ hex }] or null.
    function textOn(hex, colors) {
        let best = "";
        let bestRatio = 0;

        for (const color of colors || []) {
            const ratio = contrast(hex, color.hex);
            if (ratio > bestRatio) {
                bestRatio = ratio;
                best = color.hex;
            }
        }
        if (bestRatio >= 3)
            return best;
        return luminance(hex) > 0.35 ? "#1a1a1a" : "#f5f5f5";
    }

    // The same colour written for CSS, QML, ... (alpha kept when present).
    function formatColor(hex, format) {
        const rgb = rgbOf(hex);
        const alpha = hex.length === 9 ? parseInt(hex.slice(7, 9), 16) / 255 : 1;
        const a = Math.round(alpha * 100) / 100;

        if (format === "rgb")
            return alpha < 1 ? "rgba(" + rgb.join(", ") + ", " + a + ")" : "rgb(" + rgb.join(", ") + ")";
        if (format === "hsl") {
            const hsl = rgbToHsl(rgb[0], rgb[1], rgb[2]);
            const body = hsl[0] + ", " + hsl[1] + "%, " + hsl[2] + "%";
            return alpha < 1 ? "hsla(" + body + ", " + a + ")" : "hsl(" + body + ")";
        }
        if (format === "hypr")
            return hyprColor(hex);
        if (format === "qt")
            return "Qt.rgba(" + rgb.map(value => Math.round(value / 255 * 1000) / 1000).join(", ") + ", " + a + ")";
        return hex;
    }

    // [h 0-360, s 0-100, l 0-100], rounded.
    function rgbToHsl(r, g, b) {
        r /= 255;
        g /= 255;
        b /= 255;
        const max = Math.max(r, g, b);
        const min = Math.min(r, g, b);
        const l = (max + min) / 2;
        let h = 0;
        let s = 0;

        if (max !== min) {
            const d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            h = max === r ? (g - b) / d + (g < b ? 6 : 0) : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
            h *= 60;
        }
        return [Math.round(h), Math.round(s * 100), Math.round(l * 100)];
    }

    function nameOf(hex) {
        return names.nearest(rgbOf(hex));
    }

    // --- history and favourites ------------------------------------------------

    function addToHistory(hex, source) {
        if (!hex)
            return;

        const old = history.find(item => item.hex === hex);

        history = [{
                hex: hex,
                name: old && old.name ? old.name : nameOf(hex),
                time: Date.now(),
                source: old ? old.source : source
            }].concat(history.filter(item => item.hex !== hex)).slice(0, pt.historyLimit);
        save();
    }

    function removeFromHistory(hex) {
        history = history.filter(item => item.hex !== hex);
        save();
    }

    function isFavorite(hex) {
        return favorites.indexOf(hex) >= 0;
    }

    function toggleFavorite(hex) {
        favorites = isFavorite(hex) ? favorites.filter(item => item !== hex) : [hex].concat(favorites);
        save();
    }

    // Favourites as entries, with the name history knows (or the nearest one).
    function favoriteEntries() {
        return favorites.map(hex => {
            const known = history.find(item => item.hex === hex);
            return {
                hex: hex,
                name: known ? known.name : nameOf(hex)
            };
        });
    }

    // --- palettes and combos -----------------------------------------------------

    function newId(prefix) {
        return prefix + Date.now().toString(36) + Math.floor(Math.random() * 1296).toString(36);
    }

    // Sidebar tree: which palettes show their combos. Kept while Qreep runs.
    property var expandedPalettes: ({})

    function isExpanded(id) {
        return expandedPalettes[id] === true;
    }

    function setExpanded(id, value) {
        const next = Object.assign({}, expandedPalettes);
        next[id] = value;
        expandedPalettes = next;
    }

    function paletteById(id) {
        return palettes.find(palette => palette.id === id) || null;
    }

    function comboById(paletteId, comboId) {
        const palette = paletteById(paletteId);
        return palette ? palette.combos.find(combo => combo.id === comboId) || null : null;
    }

    function createPalette(name) {
        const palette = {
            id: newId("p"),
            name: String(name || "").trim() || "Untitled",
            combos: []
        };

        palettes = palettes.concat([palette]);
        save();
        return palette.id;
    }

    // Deep enough copy of one palette, handed to change(), then saved.
    function updatePalette(id, change) {
        palettes = palettes.map(palette => {
            if (palette.id !== id)
                return palette;
            const copy = {
                id: palette.id,
                name: palette.name,
                combos: palette.combos.map(combo => ({
                            id: combo.id,
                            name: combo.name,
                            colors: combo.colors.slice()
                        }))
            };
            change(copy);
            return copy;
        });
        save();
    }

    function updateCombo(paletteId, comboId, change) {
        updatePalette(paletteId, palette => {
            const combo = palette.combos.find(item => item.id === comboId);
            if (combo)
                change(combo, palette);
        });
    }

    function renamePalette(id, name) {
        updatePalette(id, palette => palette.name = String(name || "").trim() || palette.name);
    }

    function deletePalette(id) {
        palettes = palettes.filter(palette => palette.id !== id);
        save();
    }

    function createCombo(paletteId, name) {
        const id = newId("c");

        updatePalette(paletteId, palette => palette.combos.push({
                id: id,
                name: String(name || "").trim() || "Combo " + (palette.combos.length + 1),
                colors: []
            }));
        return id;
    }

    function renameCombo(paletteId, comboId, name) {
        updateCombo(paletteId, comboId, combo => combo.name = String(name || "").trim() || combo.name);
    }

    function deleteCombo(paletteId, comboId) {
        updatePalette(paletteId, palette => palette.combos = palette.combos.filter(combo => combo.id !== comboId));
    }

    function moveCombo(paletteId, index, step) {
        updatePalette(paletteId, palette => moveIn(palette.combos, index, step));
    }

    function addToCombo(paletteId, comboId, hex, name) {
        updateCombo(paletteId, comboId, combo => combo.colors.push({
                hex: hex,
                name: name || nameOf(hex)
            }));
    }

    function removeFromCombo(paletteId, comboId, index) {
        updateCombo(paletteId, comboId, combo => combo.colors.splice(index, 1));
    }

    function renameColor(paletteId, comboId, index, name) {
        updateCombo(paletteId, comboId, combo => {
            if (combo.colors[index])
                combo.colors[index] = {
                    hex: combo.colors[index].hex,
                    name: String(name || "").trim() || combo.colors[index].name
                };
        });
    }

    function moveColor(paletteId, comboId, index, step) {
        updateCombo(paletteId, comboId, combo => moveIn(combo.colors, index, step));
    }

    function moveIn(list, index, step) {
        const target = index + step;

        if (target < 0 || target >= list.length)
            return;
        list.splice(target, 0, list.splice(index, 1)[0]);
    }

    // Palettes saved before combos had a flat colour list: that list
    // becomes the palette's one combo.
    function upgradePalette(palette) {
        if (Array.isArray(palette.combos))
            return palette;
        return {
            id: palette.id,
            name: palette.name,
            combos: [{
                    id: newId("c"),
                    name: "Combo 1",
                    colors: Array.isArray(palette.colors) ? palette.colors : []
                }]
        };
    }

    // --- actions -------------------------------------------------------------------

    function copy(hex) {
        copier.command = ["wl-copy", hex];
        copier.startDetached();
    }

    function pick() {
        if (picker.running)
            return;
        picker.running = true;
    }

    function save() {
        if (!loaded)
            return;
        storeFile.setText(JSON.stringify({
            version: 1,
            history: history,
            favorites: favorites,
            palettes: palettes
        }, null, 2) + "\n");
    }

    Process {
        id: copier
    }

    // hyprpicker copies by itself (-a); its stdout is the colour, last line.
    Process {
        id: picker

        command: rootPrismService.pt.pickCommand

        stdout: StdioCollector {
            id: pickerStdout

            waitForEnd: true
        }

        onExited: exitCode => {
            const lines = pickerStdout.text.trim().split("\n");
            const hex = rootPrismService.parseColor(lines[lines.length - 1] || "");

            if (exitCode === 0 && hex) {
                rootPrismService.addToHistory(hex, "pick");
                rootPrismService.picked(hex);
            }
        }
    }

    // Every clipboard change: the first 200 bytes on one line. Colours go to
    // history; everything else is ignored. Restarts if wl-paste ever exits.
    Process {
        id: clipboardWatcher

        command: ["wl-paste", "--watch", "sh", "-c", "head -c 200 | tr '\\n\\r' '  '; echo"]
        running: true

        stdout: SplitParser {
            onRead: data => rootPrismService.addToHistory(rootPrismService.parseColor(data), "clipboard")
        }

        onExited: watcherRestart.restart()
    }

    Timer {
        id: watcherRestart

        interval: 5000
        repeat: false
        onTriggered: clipboardWatcher.running = true
    }

    FileView {
        id: storeFile

        path: rootPrismService.pt.storePath
        preload: true
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text() || "{}");

                // Fill in names missing from older saves.
                rootPrismService.history = (Array.isArray(data.history) ? data.history : []).map(item => item.name ? item : Object.assign({}, item, {
                            name: rootPrismService.nameOf(item.hex)
                        }));
                rootPrismService.favorites = Array.isArray(data.favorites) ? data.favorites : [];
                rootPrismService.palettes = (Array.isArray(data.palettes) ? data.palettes : []).map(palette => rootPrismService.upgradePalette(palette));
                rootPrismService.lastError = "";
            } catch (error) {
                rootPrismService.lastError = "prism.json is not valid JSON; not overwriting it.";
                return;
            }
            rootPrismService.loaded = true;
        }

        // First run: no file yet, start empty (and allow saving).
        onLoadFailed: rootPrismService.loaded = true
    }
}
