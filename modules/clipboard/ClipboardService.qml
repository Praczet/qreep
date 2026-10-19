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
    property var activeTypeFilters: []
    // Pins: copies of the content in pinDir (clipboard-pins), not clipvault
    // ids, so they survive clipvault pruning and renumbering.
    // [{ hash, file, mime, preview, pinnedAt }], newest first.
    property var pins: []
    property var entries: []
    property var filteredEntries: []
    property int selectedIndex: filteredEntries.length > 0 ? 0 : -1
    property bool loading: false
    property string error: ""
    property var imagePreviewQueue: []
    property var imagePreviewSources: ({})
    property int imagePreviewRevision: 0
    property string currentImagePreviewId: ""
    property string currentImagePreviewPath: ""
    property var currentRestoreEntry: null
    property bool refreshAfterPinnedRead: false

    readonly property string pinDir: Quickshell.env("HOME") + "/.local/share/qreep/clipboard-pins"
    readonly property string pinWorker: Quickshell.shellDir + "/modules/clipboard/clipboard-pins"
    // The old id-only pins; migrated into pinDir once, then renamed .migrated.
    readonly property string legacyPinnedFile: Quickshell.env("HOME") + "/.local/share/clipvault/pinned.json"
    readonly property string previewDir: (Quickshell.env("XDG_RUNTIME_DIR").length > 0 ? Quickshell.env("XDG_RUNTIME_DIR") : "/tmp") + "/qreep-clipboard-previews"
    readonly property string restoreNotificationTitle: "Qreep-Clipboard"
    readonly property string restoreNotificationIcon: "edit-paste-symbolic"
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
    onActiveTypeFiltersChanged: applyFilter()

    Component.onCompleted: readPinnedIds(false)

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
            if (exitCode !== 0) {
                rootClipboardService.reportError("Clipboard restore failed:", restoreStderr.text);
                rootClipboardService.currentRestoreEntry = null;
                return;
            }

            rootClipboardService.notifyRestored(rootClipboardService.currentRestoreEntry);
            rootClipboardService.currentRestoreEntry = null;
        }
    }

    readonly property Process restoreNotifier: Process {
        id: restoreNotifier
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
                rootClipboardService.reportError("Clipboard pin failed:", pinnedWriteStderr.text);
                return;
            }

            rootClipboardService.refresh();
        }
    }

    readonly property Process imagePreviewRunner: Process {
        id: imagePreviewRunner

        stderr: StdioCollector {
            id: imagePreviewStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            rootClipboardService.applyImagePreviewOutput(rootClipboardService.currentImagePreviewId, rootClipboardService.currentImagePreviewPath, imagePreviewStderr.text, exitCode);
            rootClipboardService.currentImagePreviewId = "";
            rootClipboardService.currentImagePreviewPath = "";
            rootClipboardService.exportNextImagePreview();
        }
    }

    function refresh() {
        if (listRunner.running)
            return;

        loading = true;
        error = "";
        readPinnedIds(true);
    }

    function readPinnedIds(thenRefresh) {
        if (pinnedReader.running) {
            refreshAfterPinnedRead = refreshAfterPinnedRead || thenRefresh;
            return;
        }

        refreshAfterPinnedRead = thenRefresh;
        pinnedReader.command = ["sh", "-c", "if [ -f " + shellQuote(legacyPinnedFile) + " ]; then " + shellQuote(pinWorker) + " migrate " + shellQuote(pinDir) + " " + shellQuote(legacyPinnedFile) + " >/dev/null; fi; " + shellQuote(pinWorker) + " list " + shellQuote(pinDir)];
        pinnedReader.running = true;
    }

    function applyPinnedOutput(stdout, stderr, exitCode) {
        try {
            const parsed = JSON.parse(stdout.length > 0 ? stdout : "[]");
            pins = Array.isArray(parsed) ? parsed : [];
        } catch (error) {
            reportError("Clipboard pins JSON error:", error, stderr);
            pins = [];
        }

        if (!refreshAfterPinnedRead) {
            entries = pinEntries().concat(entries.filter(entry => !entry.pinHash));
            applyFilter();
            return;
        }

        refreshAfterPinnedRead = false;
        startListRunner();
    }

    function startListRunner() {
        listRunner.command = ["sh", "-c", "clipvault list | head -n " + Math.max(1, Number(theme.modules.clipboard.maxItems))];
        listRunner.running = true;
    }

    // Pin entries for the grid: id "pin:<hash>", always starred, the image
    // straight from the pin file (no clipvault export needed).
    function pinEntries() {
        const sources = Object.assign({}, imagePreviewSources);

        const result = pins.map((pin, index) => {
            const entry = normalizeEntry("pin:" + pin.hash, String(pin.preview || ""), index);

            entry.starred = true;
            entry.pinHash = pin.hash;
            if (entry.type === "image") {
                entry.imagePath = pinDir + "/" + pin.file;
                sources[entry.id] = "file://" + entry.imagePath;
            }
            return entry;
        });

        imagePreviewSources = sources;
        imagePreviewRevision++;
        return result;
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

        // A pinned value copied again lands in clipvault too; the pin shows it.
        const pinnedPreviews = {};
        for (const pin of pins)
            pinnedPreviews[pin.preview] = true;

        const history = parsedEntries.filter(entry => !pinnedPreviews[entry.preview]);

        entries = pinEntries().concat(history);
        applyFilter();
        startImagePreviewExports(parsedEntries);
    }

    function normalizeEntry(id, preview, listIndex) {
        const type = detectType(preview);
        const color = type === "color" ? qmlColorFor(preview.trim()) : "";
        const imageMimeType = type === "image" ? imageMimeTypeFromPreview(preview) : "";
        const imageDimensions = type === "image" ? imageDimensionsFromPreview(preview) : "";
        const imagePath = type === "image" ? imagePreviewPath(id, imageMimeType) : "";

        return {
            id,
            preview,
            type,
            color,
            imageMimeType,
            imageDimensions,
            imagePath,
            imageSource: "",
            imageReady: false,
            starred: false,
            pinHash: "",
            listIndex
        };
    }

    function applyFilter() {
        const needle = searchText.trim().toLowerCase();
        let nextEntries = entries;

        if (starredOnly)
            nextEntries = nextEntries.filter(entry => entry.starred);

        if (activeTypeFilters.length > 0)
            nextEntries = nextEntries.filter(entry => activeTypeFilters.indexOf(typeFilterKey(entry.type)) !== -1);

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

        currentRestoreEntry = cloneEntry(entry);
        restoreRunner.running = false;
        restoreRunner.command = entry.pinHash ? [pinWorker, "restore", pinDir, entry.pinHash] : ["sh", "-c", "printf '%s\\t' " + shellQuote(entry.id) + " | clipvault get | wl-copy"];
        restoreRunner.running = true;
    }

    function deleteEntry(index) {
        const entry = entryAt(index);

        if (!entry)
            return;

        // Deleting a pin unpins it; the clipvault history is not touched.
        if (entry.pinHash) {
            runPinWorker(["unpin", pinDir, entry.pinHash]);
            return;
        }

        deleteRunner.running = false;
        deleteRunner.command = ["sh", "-c", "printf '%s\\n' " + shellQuote(entry.id) + " | clipvault delete"];
        deleteRunner.running = true;
    }

    function toggleStar(index) {
        const entry = entryAt(index);

        if (!entry)
            return;

        // Pinning copies the content out of clipvault; unpinning drops the copy.
        if (entry.pinHash)
            runPinWorker(["unpin", pinDir, entry.pinHash]);
        else
            runPinWorker(["pin", pinDir, entry.id, entry.preview]);
    }

    function runPinWorker(args) {
        pinnedWriter.running = false;
        pinnedWriter.command = [pinWorker].concat(args);
        pinnedWriter.running = true;
    }

    function startImagePreviewExports(nextEntries) {
        imagePreviewQueue = nextEntries.filter(entry => entry.type === "image" && !entry.pinHash && !imagePreviewSources[entry.id] && entry.id !== currentImagePreviewId);

        if (!imagePreviewRunner.running)
            exportNextImagePreview();
    }

    function exportNextImagePreview() {
        if (imagePreviewRunner.running || imagePreviewQueue.length === 0)
            return;

        const nextQueue = imagePreviewQueue.slice();
        const entry = nextQueue.shift();
        imagePreviewQueue = nextQueue;

        if (!entry || entry.imagePath.length === 0) {
            exportNextImagePreview();
            return;
        }

        currentImagePreviewId = entry.id;
        currentImagePreviewPath = entry.imagePath;
        imagePreviewRunner.command = ["sh", "-c", "mkdir -p " + shellQuote(previewDir) + " && clipvault get " + shellQuote(entry.id) + " > " + shellQuote(entry.imagePath + ".tmp") + " && mv -f " + shellQuote(entry.imagePath + ".tmp") + " " + shellQuote(entry.imagePath)];
        imagePreviewRunner.running = true;
    }

    function applyImagePreviewOutput(id, path, stderr, exitCode) {
        if (id.length === 0)
            return;

        if (exitCode !== 0) {
            warn("Clipboard image preview failed:", id, stderr.length > 0 ? stderr : "clipvault returned " + exitCode);
            return;
        }

        const nextSources = Object.assign({}, imagePreviewSources);
        nextSources[id] = "file://" + path;
        imagePreviewSources = nextSources;
        imagePreviewRevision++;
    }

    function imagePreviewSource(id, revision) {
        return imagePreviewSources[id] || "";
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

    function toggleTypeFilter(type) {
        const normalized = typeFilterKey(type);
        const nextFilters = activeTypeFilters.slice();
        const existingIndex = nextFilters.indexOf(normalized);

        if (existingIndex === -1)
            nextFilters.push(normalized);
        else
            nextFilters.splice(existingIndex, 1);

        activeTypeFilters = nextFilters;
    }

    function typeFilterActive(type) {
        return activeTypeFilters.indexOf(typeFilterKey(type)) !== -1;
    }

    function typeFilterKey(type) {
        switch (type) {
        case "image":
            return "image";
        case "code":
            return "code";
        case "color":
        case "color-text":
            return "color";
        default:
            return "text";
        }
    }

    function detectType(preview) {
        const trimmed = preview.trim();
        const lower = trimmed.toLowerCase();

        if (/binary data.*\.(jpg|jpeg|png|gif|bmp|webp)/i.test(trimmed))
            return "image";

        if (/binary data.*image\/(?:jpeg|png|gif|bmp|webp)/i.test(trimmed))
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
            imageMimeType: entry.imageMimeType || "",
            imageDimensions: entry.imageDimensions || "",
            imagePath: entry.imagePath || "",
            imageSource: entry.imageSource || "",
            imageReady: entry.imageReady === true,
            starred: entry.starred,
            pinHash: entry.pinHash || "",
            listIndex: entry.listIndex
        };
    }

    function imageMimeTypeFromPreview(preview) {
        const match = preview.match(/image\/(?:jpeg|png|gif|bmp|webp)/i);
        return match ? match[0].toLowerCase() : "";
    }

    function imageDimensionsFromPreview(preview) {
        const match = preview.match(/\b\d+x\d+\b/);
        return match ? match[0] : "";
    }

    function imagePreviewPath(id, mimeType) {
        return previewDir + "/" + id + "." + imageExtension(mimeType);
    }

    function imageExtension(mimeType) {
        switch (mimeType) {
        case "image/jpeg":
            return "jpg";
        case "image/gif":
            return "gif";
        case "image/bmp":
            return "bmp";
        case "image/webp":
            return "webp";
        default:
            return "png";
        }
    }

    function notifyRestored(entry) {
        if (!entry)
            return;

        restoreNotifier.running = false;
        restoreNotifier.command = [
            "notify-send",
            "--app-name=Qreep",
            "--icon=" + restoreNotificationIcon,
            restoreNotificationTitle,
            restoredNotificationBody(entry)
        ];
        restoreNotifier.running = true;
    }

    function restoredNotificationBody(entry) {
        return entryTypeLabel(entry.type) + (entry.pinHash ? " (pinned)" : " [" + entry.id + "]") + " copied";
    }

    function entryTypeLabel(type) {
        switch (type) {
        case "image":
            return "Image";
        case "code":
            return "Code";
        case "color":
        case "color-text":
            return "Color";
        default:
            return "Text";
        }
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function reportError() {
        error = messageText(arguments);
        (log || fallbackLog).error(error);
    }

    function warn() {
        (log || fallbackLog).warn.apply(log || fallbackLog, arguments);
    }

    function messageText(messages) {
        const parts = [];

        for (let index = 0; index < messages.length; index++)
            parts.push(String(messages[index]).trim());

        return parts.join(" ");
    }
    function classifyClipboardText(text) {
        const trimmed = text.trim();

        if (qmlColorFor(trimmed).length > 0)
            return "color";

        if (isLikelyCssColor(trimmed))
            return "color-text"; // recognized as color-ish, but maybe cannot preview directly

        return "text";
    }

    // Text -> something a Rectangle can draw, or "". Qt reads 8-digit hex as
    // #aarrggbb, so CSS #rrggbbaa and Hyprland rgba(rrggbbaa) / 0xaarrggbb
    // are rewritten into that order.
    function qmlColorFor(value) {
        const trimmed = value.trim();
        let match = /^rgba?\(([0-9a-f]{6}|[0-9a-f]{8})\)$/i.exec(trimmed);

        if (match)
            return match[1].length === 8 ? "#" + match[1].slice(6) + match[1].slice(0, 6) : "#" + match[1];
        match = /^0x([0-9a-f]{8})$/i.exec(trimmed);
        if (match)
            return "#" + match[1];
        match = /^#([0-9a-f]{8})$/i.exec(trimmed);
        if (match)
            return "#" + match[1].slice(6) + match[1].slice(0, 6);
        return isQmlRenderableColor(trimmed) ? trimmed : "";
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
