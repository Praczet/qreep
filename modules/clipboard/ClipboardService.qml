import QtQuick
import Quickshell
import Quickshell.Io
import "../../core" as Core

QtObject {
    id: rootClipboardService

    required property QtObject theme
    property QtObject log
    property string searchText: ""
    property bool starredOnly: false
    property var pinnedIds: []
    property var entries: []
    property var filteredEntries: []
    property int selectedIndex: filteredEntries.length > 0 ? 0 : -1
    property bool loading: false
    property string error: ""

    readonly property string pinnedFile: Quickshell.env("HOME") + "/.local/share/clipvault/pinned.json"
    readonly property Core.Log fallbackLog: Core.Log {}

    readonly property var namedColors: ({
            "transparent": true,
            "black": true,
            "silver": true,
            "gray": true,
            "white": true,
            "maroon": true,
            "red": true,
            "purple": true,
            "fuchsia": true,
            "green": true,
            "lime": true,
            "olive": true,
            "yellow": true,
            "navy": true,
            "blue": true,
            "teal": true,
            "aqua": true,
            "orange": true,
            "aliceblue": true,
            "antiquewhite": true,
            "aquamarine": true,
            "azure": true,
            "beige": true,
            "bisque": true,
            "brown": true,
            "chocolate": true,
            "coral": true,
            "cornflowerblue": true,
            "crimson": true,
            "cyan": true,
            "gold": true,
            "goldenrod": true,
            "hotpink": true,
            "indigo": true,
            "ivory": true,
            "khaki": true,
            "lavender": true,
            "magenta": true,
            "orchid": true,
            "pink": true,
            "plum": true,
            "salmon": true,
            "sienna": true,
            "steelblue": true,
            "tan": true,
            "tomato": true,
            "violet": true
        })

    onSearchTextChanged: applyFilter()
    onStarredOnlyChanged: applyFilter()

    readonly property Process pinnedReader: Process {
        id: pinnedReader

        stdout: StdioCollector {
            id: pinnedStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: pinnedStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootClipboardService.applyPinnedOutput(pinnedStdout.text, pinnedStderr.text, exitCode)
    }

    readonly property Process listRunner: Process {
        id: listRunner

        stdout: StdioCollector {
            id: listStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: listStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootClipboardService.applyListOutput(listStdout.text, listStderr.text, exitCode)
    }

    readonly property Process restoreRunner: Process {
        id: restoreRunner

        stderr: StdioCollector {
            id: restoreStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                rootClipboardService.reportError("Clipboard restore failed:", restoreStderr.text);
        }
    }

    readonly property Process deleteRunner: Process {
        id: deleteRunner

        stderr: StdioCollector {
            id: deleteStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                rootClipboardService.reportError("Clipboard delete failed:", deleteStderr.text);
                return;
            }

            rootClipboardService.refresh();
        }
    }

    readonly property Process pinnedWriter: Process {
        id: pinnedWriter

        stderr: StdioCollector {
            id: pinnedWriteStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                rootClipboardService.reportError("Clipboard pin write failed:", pinnedWriteStderr.text);
                return;
            }

            rootClipboardService.applyFilter();
        }
    }

    function refresh() {
        if (pinnedReader.running || listRunner.running)
            return;

        loading = true;
        error = "";
        pinnedReader.command = ["sh", "-c", "cat " + shellQuote(pinnedFile) + " 2>/dev/null || printf '[]'"];
        pinnedReader.running = true;
    }

    function applyPinnedOutput(stdout, stderr, exitCode) {
        try {
            const parsed = JSON.parse(stdout.length > 0 ? stdout : "[]");
            pinnedIds = Array.isArray(parsed) ? parsed.map(value => String(value)) : [];
        } catch (error) {
            reportError("Clipboard pinned JSON error:", error);
            pinnedIds = [];
        }

        listRunner.command = ["sh", "-c", "clipvault list | head -n " + Math.max(1, Number(theme.modules.clipboard.maxItems))];
        listRunner.running = true;
    }

    function applyListOutput(stdout, stderr, exitCode) {
        loading = false;

        if (exitCode !== 0) {
            entries = [];
            filteredEntries = [];
            selectedIndex = -1;
            reportError("Clipboard list failed:", stderr.length > 0 ? stderr : "clipvault returned " + exitCode);
            return;
        }

        const parsedEntries = [];
        const lines = stdout.split("\n").filter(line => line.length > 0);

        for (let index = 0; index < lines.length; index++) {
            const line = lines[index];
            const tabIndex = line.indexOf("\t");

            if (tabIndex <= 0)
                continue;

            const id = line.slice(0, tabIndex);
            const preview = line.slice(tabIndex + 1);
            parsedEntries.push(normalizeEntry(id, preview, index));
        }

        parsedEntries.sort((left, right) => {
            if (left.starred !== right.starred)
                return left.starred ? -1 : 1;

            return left.listIndex - right.listIndex;
        });

        entries = parsedEntries;
        applyFilter();
    }

    function normalizeEntry(id, preview, listIndex) {
        const type = detectType(preview);
        const color = type === "color" ? preview.trim() : "";

        return {
            id,
            preview,
            type,
            color,
            starred: pinnedIds.indexOf(id) !== -1,
            listIndex
        };
    }

    function applyFilter() {
        const needle = searchText.trim().toLowerCase();
        let nextEntries = entries;

        if (starredOnly)
            nextEntries = nextEntries.filter(entry => entry.starred);

        if (needle.length > 0) {
            nextEntries = nextEntries.filter(entry => entry.preview.toLowerCase().indexOf(needle) !== -1 || entry.type.indexOf(needle) !== -1);
        }

        filteredEntries = nextEntries;
        clampSelection();
    }

    function clampSelection() {
        if (filteredEntries.length === 0) {
            selectedIndex = -1;
            return;
        }

        if (selectedIndex < 0)
            selectedIndex = 0;
        else if (selectedIndex >= filteredEntries.length)
            selectedIndex = filteredEntries.length - 1;
    }

    function restore(index) {
        const entry = entryAt(index);

        if (!entry)
            return;

        restoreRunner.running = false;
        restoreRunner.command = ["sh", "-c", "printf '%s\\t' " + shellQuote(entry.id) + " | clipvault get | wl-copy"];
        restoreRunner.running = true;
    }

    function deleteEntry(index) {
        const entry = entryAt(index);

        if (!entry)
            return;

        deleteRunner.running = false;
        deleteRunner.command = ["sh", "-c", "printf '%s\\n' " + shellQuote(entry.id) + " | clipvault delete"];
        deleteRunner.running = true;
    }

    function toggleStar(index) {
        const entry = entryAt(index);

        if (!entry)
            return;

        const nextPinned = pinnedIds.slice();
        const existingIndex = nextPinned.indexOf(entry.id);

        if (existingIndex === -1)
            nextPinned.unshift(entry.id);
        else
            nextPinned.splice(existingIndex, 1);

        pinnedIds = nextPinned;
        entries = entries.map(current => {
            const copy = cloneEntry(current);
            copy.starred = nextPinned.indexOf(copy.id) !== -1;
            return copy;
        });

        writePinnedIds();
    }

    function writePinnedIds() {
        pinnedWriter.running = false;
        pinnedWriter.command = ["python3", "-c", "import json, os, sys\npath = sys.argv[1]\nos.makedirs(os.path.dirname(path), exist_ok=True)\nwith open(path, 'w', encoding='utf-8') as handle:\n    json.dump(sys.argv[2:], handle, indent=2)\n    handle.write('\\n')", pinnedFile].concat(pinnedIds);
        pinnedWriter.running = true;
    }

    function entryAt(index) {
        if (index < 0 || index >= filteredEntries.length)
            return null;

        return filteredEntries[index];
    }

    function moveSelection(offset, columns) {
        if (filteredEntries.length === 0)
            return;

        const step = columns && columns > 0 ? offset * columns : offset;
        selectedIndex = Math.max(0, Math.min(filteredEntries.length - 1, selectedIndex + step));
    }

    function setSelection(index) {
        selectedIndex = Math.max(0, Math.min(filteredEntries.length - 1, index));
    }

    function detectType(preview) {
        const trimmed = preview.trim();
        const lower = trimmed.toLowerCase();

        if (/binary data.*\.(jpg|jpeg|png|gif|bmp|webp)/i.test(trimmed))
            return "image";

        if (preview.indexOf("\\n") !== -1 || /[{};]/.test(trimmed) || /\b(class|function|const|let|var|import|export|sudo|read)\b/.test(lower) || lower.indexOf("#!") === 0)
            return "code";

        return classifyClipboardText(trimmed);
    }

    function cloneEntry(entry) {
        return {
            id: entry.id,
            preview: entry.preview,
            type: entry.type,
            color: entry.color,
            starred: entry.starred,
            listIndex: entry.listIndex
        };
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function reportError() {
        error = messageText(arguments);
        (log || fallbackLog).error(error);
    }

    function messageText(messages) {
        const parts = [];

        for (let index = 0; index < messages.length; index++)
            parts.push(String(messages[index]).trim());

        return parts.join(" ");
    }
    function classifyClipboardText(text) {
        const trimmed = text.trim();

        if (isQmlRenderableColor(trimmed))
            return "color";

        if (isLikelyCssColor(trimmed))
            return "color-text"; // recognized as color-ish, but maybe cannot preview directly

        return "text";
    }

    function isQmlRenderableColor(value) {
        const trimmed = value.trim();

        if (/^#(?:[0-9a-f]{6}|[0-9a-f]{8})$/i.test(trimmed))
            return true;

        if (isNamedColor(trimmed))
            return true;

        if (/^Qt\.(?:rgba|hsla|hsva)\(/.test(trimmed))
            return true;

        return false;
    }

    function isLikelyCssColor(value) {
        const trimmed = value.trim();

        if (/^#(?:[0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(trimmed))
            return true;

        if (/^(?:rgb|rgba|hsl|hsla|hwb|lab|lch|oklab|oklch|color|color-mix)\(/i.test(trimmed))
            return true;

        if (isNamedColor(trimmed))
            return true;

        return false;
    }

    function isNamedColor(value) {
        return namedColors[value.toLowerCase()] === true;
    }
}
