import QtQuick
import Quickshell
import Quickshell.Io

// /browse: one folder at a time. fd lists the folder (--exact-depth 1) when
// the folder changes; typing after the last "/" filters that listing here,
// without another process. Hits have the same shape as /fd hits, so the
// panel's file/folder action menus work on them unchanged.
Item {
    id: rootKipBrowseService

    required property QtObject theme

    readonly property QtObject kt: theme.modules.kip
    readonly property string home: Quickshell.env("HOME")

    // idle | loading | ready | error
    property string status: "idle"
    // Absolute, with a trailing slash.
    property string dir: ""
    property string filterText: ""
    property var entries: []
    property var results: []
    property string errorText: ""
    property string eventKey: ""
    // Runtime toggles (Alt+H / Alt+I / Alt+P); they outlive the panel.
    property bool hidden: kt.browseShowHidden
    property bool respectIgnore: kt.browseRespectGitignore
    property bool preview: kt.browsePreview

    // Preview of the selected entry. kind: none | loading | image | text | binary | dir | error
    property string previewKind: "none"
    property string previewText: ""
    property string previewPath: ""

    readonly property var imageExtensions: ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg"]

    Process {
        id: listProcess

        stdout: StdioCollector {
            id: listStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: listStderr

            waitForEnd: true
        }

        onExited: exitCode => rootKipBrowseService.finishList(exitCode, listStdout.text, listStderr.text)
    }

    // First bytes only: enough to recognise the file, never the whole thing.
    Process {
        id: previewProcess

        stdout: StdioCollector {
            id: previewStdout

            waitForEnd: true
        }

        onExited: exitCode => rootKipBrowseService.finishPreview(exitCode, previewStdout.text)
    }

    function open(path) {
        const wanted = path.endsWith("/") ? path : path + "/";

        if (wanted === dir && status !== "error" && status !== "idle")
            return;

        dir = wanted;
        reload();
    }

    function reload() {
        if (dir.length === 0)
            return;

        const command = [kt.fdCommand, "--color", "never", "--absolute-path", "--exact-depth", "1"];

        if (hidden)
            command.push("--hidden");
        if (!respectIgnore)
            command.push("--no-ignore");
        command.push(".", dir);

        listProcess.running = false;
        status = "loading";
        errorText = "";
        listProcess.command = command;
        listProcess.running = true;
    }

    function finishList(exitCode, stdoutText, stderrText) {
        if (exitCode !== 0) {
            status = "error";
            errorText = String(stderrText || "").trim() || "fd exited " + exitCode;
            entries = [];
            results = [];
            eventKey = "browse.error";
            return;
        }

        entries = String(stdoutText || "").split("\n").filter(line => line.length > 0).map(describe);
        status = "ready";
        applyFilter();
    }

    function filter(text) {
        filterText = String(text || "");
        if (status === "ready")
            applyFilter();
    }

    // Folders first; names starting with the filter before names merely
    // containing it; then alphabetical. "../" leads while nothing is typed.
    function applyFilter() {
        const needle = filterText.toLowerCase();
        const matched = entries.filter(hit => needle.length === 0 || hit.name.toLowerCase().indexOf(needle) >= 0);

        matched.sort((left, right) => (right.isDir - left.isDir) || (needle.length > 0 ? (left.name.toLowerCase().startsWith(needle) ? 0 : 1) - (right.name.toLowerCase().startsWith(needle) ? 0 : 1) : 0) || left.name.localeCompare(right.name));

        if (needle.length === 0 && dir !== "/")
            matched.unshift(parentHit());

        results = matched;
        eventKey = entries.length === 0 ? "browse.empty" : (matched.length === 0 ? "browse.nomatch" : "browse.ready");
    }

    function parentHit() {
        const parent = parentOf(dir);

        return {
            absolutePath: parent.slice(0, -1) || "/",
            path: parent.slice(0, -1) || "/",
            folder: "",
            file: "../",
            name: "..",
            isDir: true,
            isParent: true,
            origin: "up",
            title: tilde(parent),
            excerpt: ""
        };
    }

    function describe(rawPath) {
        const isDir = rawPath.endsWith("/");
        const absolutePath = isDir ? rawPath.slice(0, -1) : rawPath;
        const name = absolutePath.slice(absolutePath.lastIndexOf("/") + 1);
        const graph = kt.logseqGraphDir + "/";
        const inLogseq = absolutePath.startsWith(graph);

        return {
            absolutePath: absolutePath,
            path: inLogseq ? kt.logseqGraph + "/" + absolutePath.slice(graph.length) : absolutePath,
            // Empty folder: the list shows names only, the folder is in the input.
            folder: "",
            file: name + (isDir ? "/" : ""),
            name: name,
            isDir: isDir,
            inLogseq: inLogseq,
            origin: isDir ? "dir" : "file",
            title: tilde(absolutePath) + (isDir ? "/" : ""),
            excerpt: ""
        };
    }

    function loadPreview(hit) {
        previewProcess.running = false;

        if (!hit) {
            previewKind = "none";
            return;
        }

        previewPath = hit.absolutePath;
        previewText = "";

        if (hit.isDir) {
            previewKind = "dir";
            return;
        }

        const extension = hit.name.indexOf(".") >= 0 ? hit.name.slice(hit.name.lastIndexOf(".") + 1).toLowerCase() : "";

        if (imageExtensions.indexOf(extension) >= 0) {
            previewKind = "image";
            return;
        }

        previewKind = "loading";
        previewProcess.command = ["head", "-c", String(kt.browsePreviewBytes), "--", hit.absolutePath];
        previewProcess.running = true;
    }

    function finishPreview(exitCode, text) {
        if (exitCode !== 0) {
            previewKind = "error";
            previewText = "could not read it";
            return;
        }

        // A NUL in the first bytes: not something to print.
        if (text.indexOf("\u0000") >= 0) {
            previewKind = "binary";
            previewText = "";
            return;
        }

        previewKind = "text";
        previewText = text;
    }

    function reset() {
        listProcess.running = false;
        previewProcess.running = false;
        status = "idle";
        dir = "";
        filterText = "";
        entries = [];
        results = [];
        errorText = "";
        eventKey = "";
        previewKind = "none";
        previewText = "";
        previewPath = "";
    }

    function cancel() {
        listProcess.running = false;
        previewProcess.running = false;
    }

    // "/browse <argument>" → { dir, filter }. The input is the state: what is
    // after the last "/" filters, everything before it is the folder.
    // Relative input starts at ~.
    function split(argument) {
        const text = String(argument || "");
        let path = text.length === 0 ? "~/" : text;

        if (path === "~")
            path = "~/";
        if (path.startsWith("~/"))
            path = home + path.slice(1);
        else if (!path.startsWith("/"))
            path = home + "/" + path;

        const slash = path.lastIndexOf("/");

        return {
            dir: path.slice(0, slash + 1),
            filter: path.slice(slash + 1)
        };
    }

    function parentOf(path) {
        const trimmed = path.replace(/\/+$/, "");
        const slash = trimmed.lastIndexOf("/");

        return slash <= 0 ? "/" : trimmed.slice(0, slash + 1);
    }

    function tilde(path) {
        if (path === home || path === home + "/")
            return "~/";
        return path.startsWith(home + "/") ? "~" + path.slice(home.length) : path;
    }

    function inputFor(path) {
        const withSlash = path.endsWith("/") ? path : path + "/";

        return "/browse " + tilde(withSlash);
    }
}
