import QtQuick
import Quickshell
import Quickshell.Io

// /fd: file and folder search with fd(1). Every word must match (--and),
// literally (--fixed-strings), smart case. Two fd passes run side by side:
//   name pass  — words in the file/folder name; few, good hits
//   path pass  — words anywhere in the absolute path (--full-path)
// Both stop at fdMaxResults. Without the name pass, a broad search of / fills
// the cap with path-only matches and the file you meant never arrives.
// fd only prints paths; ranking happens here.
Item {
    id: rootKipFileSearchService

    required property QtObject theme

    readonly property QtObject kt: theme.modules.kip
    readonly property string home: Quickshell.env("HOME")

    // idle | searching | done | empty | error
    property string status: "idle"
    property var words: []
    property string root: ""
    property bool hidden: false
    property var results: []
    // fd stopped at fdMaxResults; there may be more.
    property bool truncated: false
    property string errorText: ""
    property string eventKey: ""
    property int requestId: 0

    property var activeProcesses: []
    property int runningPasses: 0
    property string firstError: ""
    property var seen: ({})
    property var pending: []
    property int received: 0

    readonly property bool busy: status === "searching"

    Component {
        id: fdProcessComponent

        Process {
            id: fdProcess

            property int ownerId: -1

            stdout: SplitParser {
                onRead: data => rootKipFileSearchService.receive(fdProcess.ownerId, data)
            }

            stderr: StdioCollector {
                id: fdStderr

                waitForEnd: true
            }

            onExited: exitCode => rootKipFileSearchService.finishPass(fdProcess.ownerId, exitCode, fdStderr.text)
        }
    }

    // Lines arrive one by one; re-rank in batches, not per path.
    Timer {
        id: flushTimer

        interval: 60
        repeat: false
        onTriggered: rootKipFileSearchService.flush()
    }

    // keepShown: leave the current list up until new results land, so live
    // typing refreshes in place instead of blinking.
    function search(text, from, includeHidden, keepShown) {
        const nextWords = String(text).trim().split(/\s+/).filter(word => word.length > 0);

        cancel();

        words = nextWords;
        root = expand(from && from.length > 0 ? from : kt.fdDefaultRoot);
        hidden = includeHidden === true;
        truncated = false;
        errorText = "";
        pending = [];
        received = 0;
        seen = {};
        firstError = "";
        status = "searching";

        if (!keepShown || results.length === 0) {
            results = [];
            eventKey = root === "/" ? "fd.root" : "fd.searching";
        }

        if (nextWords.length === 0) {
            status = "idle";
            return;
        }

        const processes = [false, true].map(fullPath => fdProcessComponent.createObject(rootKipFileSearchService, {
            ownerId: requestId,
            command: buildCommand(nextWords, root, hidden, fullPath)
        }));

        activeProcesses = processes;
        runningPasses = processes.length;
        processes.forEach(process => process.running = true);
    }

    // fd --and=<w> keeps a word starting with "-" a value, and "--" ends
    // options before the first pattern. Plain argv, no shell.
    function buildCommand(searchWords, searchRoot, includeHidden, fullPath) {
        const command = [kt.fdCommand, "--color", "never", "--absolute-path", "--fixed-strings", "--max-results", String(kt.fdMaxResults)];

        if (fullPath)
            command.push("--full-path");

        if (includeHidden)
            command.push("--hidden");

        for (const pattern of kt.fdExcludes)
            command.push("--exclude", pattern);

        for (const word of searchWords.slice(1))
            command.push("--and=" + word);

        command.push("--", searchWords[0], searchRoot);
        return command;
    }

    function cancel() {
        requestId++;
        flushTimer.stop();

        const processes = activeProcesses;

        activeProcesses = [];
        runningPasses = 0;

        for (const process of processes) {
            process.running = false;
            process.destroy();
        }
    }

    function reset() {
        cancel();
        status = "idle";
        words = [];
        results = [];
        pending = [];
        truncated = false;
        errorText = "";
        eventKey = "";
    }

    function receive(ownerId, line) {
        if (ownerId !== requestId)
            return;

        const path = String(line);

        // Both passes can find the same path; keep the first.
        if (path.length === 0 || seen[path])
            return;

        const marks = seen;

        marks[path] = true;
        seen = marks;

        const next = pending;

        next.push(path);
        pending = next;
        received++;

        if (!flushTimer.running)
            flushTimer.start();
    }

    function flush() {
        if (pending.length === 0)
            return;

        // A refresh replaces the old list on its first batch.
        const base = status === "searching" && received === pending.length ? [] : results;
        const merged = base.concat(pending.map(path => describe(path)));

        pending = [];
        merged.sort((left, right) => left.rank - right.rank || left.depth - right.depth || left.absolutePath.length - right.absolutePath.length);
        results = merged;

        if (eventKey !== "fd.found")
            eventKey = "fd.found";
    }

    function finishPass(ownerId, exitCode, stderrText) {
        if (ownerId !== requestId)
            return;

        if (exitCode !== 0 && firstError.length === 0)
            firstError = String(stderrText);

        runningPasses--;
        if (runningPasses > 0)
            return;

        const processes = activeProcesses;

        activeProcesses = [];
        processes.forEach(process => process.destroy());
        finish(firstError.length > 0 ? 1 : 0, firstError);
    }

    function finish(exitCode, stderrText) {
        flush();

        // Either pass may have hit the cap; close enough to say "there's more".
        truncated = received >= kt.fdMaxResults;

        // fd exits 1 on permission errors even with good results; only a
        // search with nothing to show is a failure.
        if (results.length > 0 && received > 0) {
            status = "done";
            eventKey = "fd.found";
            return;
        }

        if (exitCode !== 0) {
            results = [];
            // fd's first line is the specific one ("Search path '/x' is not a directory").
            // Text before status, so anything reacting to status sees the message.
            errorText = String(stderrText).trim().split("\n")[0].replace(/^\[fd error\]:\s*/, "") || ("fd exited with code " + exitCode);
            status = "error";
            eventKey = "fd.error";
            return;
        }

        results = [];
        status = "empty";
        eventKey = "fd.empty";
    }

    function describe(rawPath) {
        const isDir = rawPath.endsWith("/");
        const absolutePath = isDir ? rawPath.slice(0, -1) : rawPath;
        const slash = absolutePath.lastIndexOf("/");
        const name = absolutePath.slice(slash + 1);
        const folder = absolutePath.slice(0, slash + 1);
        const graph = kt.logseqGraphDir + "/";
        const inLogseq = absolutePath.startsWith(graph);

        return {
            absolutePath: absolutePath,
            // Logseq page naming wants "Logseq/pages/x.md"-style paths.
            path: inLogseq ? kt.logseqGraph + "/" + absolutePath.slice(graph.length) : absolutePath,
            folder: tilde(folder),
            file: name + (isDir ? "/" : ""),
            isDir: isDir,
            inLogseq: inLogseq,
            origin: isDir ? "dir" : "file",
            rank: rank(name, absolutePath),
            depth: absolutePath.split("/").length,
            excerpt: ""
        };
    }

    // Lower is better:
    //   0 exact name (with or without extension)
    //   1 every word in the name, name starts with the first word
    //   2 every word in the name
    //   3 name starts with the first word, other words only in the folder path
    //   4 matched only through the folder path
    function rank(name, absolutePath) {
        const lowerName = name.toLowerCase();
        const lowered = words.map(word => word.toLowerCase());
        const allInName = lowered.every(word => lowerName.indexOf(word) >= 0);
        const startsWithFirst = lowerName.startsWith(lowered[0]);

        if (lowerName === lowered.join(" ") || (lowered.length === 1 && lowerName.replace(/\.[^.]*$/, "") === lowered[0]))
            return 0;
        if (allInName && startsWithFirst)
            return 1;
        if (allInName)
            return 2;
        if (startsWithFirst)
            return 3;
        return 4;
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
