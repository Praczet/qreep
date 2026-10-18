import QtQuick
import Quickshell
import Quickshell.Io

// /rg: file contents with ripgrep. One rg per search, --json so paths with
// ":" cannot break parsing. The query is one literal string (--fixed-strings),
// smart case, a few matches per file, and KIP stops rg itself at
// rgMaxResults: a common word across ~ is not a reason to read all of ~.
// Hits have the /fd shape plus line/excerpt, so the action menus work and
// nvim lands on the line.
Item {
    id: rootKipGrepService

    required property QtObject theme

    readonly property QtObject kt: theme.modules.kip
    readonly property string home: Quickshell.env("HOME")

    // idle | searching | done | empty | error
    property string status: "idle"
    property string query: ""
    property string root: ""
    property bool hidden: false
    property string fileType: ""
    property var results: []
    property bool truncated: false
    property string errorText: ""
    property string eventKey: ""
    property int requestId: 0

    property var activeProcess: null
    property var pending: []
    property int received: 0

    readonly property bool busy: status === "searching"

    Component {
        id: rgProcessComponent

        Process {
            id: rgProcess

            property int ownerId: -1

            stdout: SplitParser {
                onRead: data => rootKipGrepService.receive(rgProcess.ownerId, data)
            }

            stderr: StdioCollector {
                id: rgStderr

                waitForEnd: true
            }

            onExited: exitCode => rootKipGrepService.finish(rgProcess.ownerId, exitCode, rgStderr.text)
        }
    }

    Timer {
        id: flushTimer

        interval: 60
        repeat: false
        onTriggered: rootKipGrepService.flush()
    }

    function search(text, from, includeHidden, type, keepShown) {
        cancel();

        query = String(text || "").trim();
        root = expand(from && from.length > 0 ? from : kt.rgDefaultRoot);
        hidden = includeHidden === true;
        fileType = String(type || "");
        truncated = false;
        errorText = "";
        pending = [];
        received = 0;
        status = "searching";

        if (!keepShown || results.length === 0) {
            results = [];
            eventKey = "rg.searching";
        }

        if (query.length === 0) {
            status = "idle";
            return;
        }

        activeProcess = rgProcessComponent.createObject(rootKipGrepService, {
            ownerId: requestId,
            command: buildCommand()
        });
        activeProcess.running = true;
    }

    // Plain argv, no shell; "--" ends options so a query starting with "-"
    // stays a query.
    function buildCommand() {
        const command = [kt.rgCommand, "--json", "--fixed-strings", "--smart-case", "--max-count", String(kt.rgMaxPerFile), "--max-columns", String(kt.rgMaxColumns), "--max-columns-preview", "--max-filesize", kt.rgMaxFileSize];

        if (hidden)
            command.push("--hidden");
        if (fileType.length > 0)
            command.push("--type", fileType);
        for (const glob of kt.rgExcludeGlobs)
            command.push("--glob", "!" + glob);

        command.push("--", query, root);
        return command;
    }

    function receive(ownerId, line) {
        if (ownerId !== requestId || received >= kt.rgMaxResults)
            return;

        let event = null;

        try {
            event = JSON.parse(line);
        } catch (error) {
            return;
        }

        // Non-UTF-8 paths arrive as base64 "bytes"; not worth decoding here.
        if (!event || event.type !== "match" || !event.data.path.text)
            return;

        const next = pending;

        next.push(describe(event.data));
        pending = next;
        received++;

        if (received >= kt.rgMaxResults) {
            truncated = true;
            // Enough. finish() still runs from onExited.
            if (activeProcess)
                activeProcess.running = false;
        }

        if (!flushTimer.running)
            flushTimer.start();
    }

    function flush() {
        if (pending.length === 0)
            return;

        // A refresh replaces the old list on its first batch.
        const base = status === "searching" && received === pending.length ? [] : results;
        const merged = base.concat(pending);

        pending = [];
        merged.sort((left, right) => left.absolutePath.localeCompare(right.absolutePath) || left.line - right.line);
        results = merged;
        eventKey = "rg.found";
    }

    function finish(ownerId, exitCode, stderrText) {
        if (ownerId !== requestId)
            return;

        flush();

        if (activeProcess) {
            activeProcess.destroy();
            activeProcess = null;
        }

        // rg: 0 found, 1 nothing found, 2 error (also on unreadable files,
        // even when it found plenty). Results win over complaints.
        if (results.length > 0) {
            status = "done";
            eventKey = "rg.found";
            return;
        }

        if (exitCode >= 2 && !truncated) {
            errorText = String(stderrText).trim().split("\n")[0].replace(/^rg:\s*/, "") || ("rg exited with code " + exitCode);
            status = "error";
            eventKey = "rg.error";
            return;
        }

        status = "empty";
        eventKey = "rg.empty";
    }

    function describe(data) {
        const absolutePath = data.path.text;
        const slash = absolutePath.lastIndexOf("/");
        const graph = kt.logseqGraphDir + "/";
        const inLogseq = absolutePath.startsWith(graph);
        const lineText = data.lines && data.lines.text ? data.lines.text : "";

        return {
            absolutePath: absolutePath,
            path: inLogseq ? kt.logseqGraph + "/" + absolutePath.slice(graph.length) : absolutePath,
            folder: tilde(absolutePath.slice(0, slash + 1)),
            file: absolutePath.slice(slash + 1),
            isDir: false,
            inLogseq: inLogseq,
            origin: "rg",
            line: data.line_number,
            endLine: data.line_number,
            // The action menu puts nvim first: you came here for a line.
            atLine: true,
            excerpt: lineText.replace(/\s+$/, "").replace(/^\s+/, "")
        };
    }

    function cancel() {
        requestId++;
        flushTimer.stop();

        if (activeProcess) {
            activeProcess.running = false;
            activeProcess.destroy();
            activeProcess = null;
        }
    }

    function reset() {
        cancel();
        status = "idle";
        query = "";
        results = [];
        pending = [];
        truncated = false;
        errorText = "";
        eventKey = "";
    }

    function expand(path) {
        if (path === "~")
            return home;
        if (path.startsWith("~/"))
            return home + path.slice(1);
        return path;
    }

    function tilde(path) {
        return path.startsWith(home + "/") ? "~" + path.slice(home.length) : path;
    }
}
