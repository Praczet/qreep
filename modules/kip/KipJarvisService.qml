import QtQuick
import Quickshell
import Quickshell.Io

// Jarvis adapter. Same surface as KipMockService, real backend:
//   search  → jarvis --json -search-notes=<q>   one JSON object
//   ask     → jarvis --json -ask-notes=<q>      NDJSON stream
//   general → jarvis --json -- <q>              NDJSON stream
// The "=" / "--" forms keep a question that starts with "-" from being read
// as a Jarvis flag. No shell is involved anywhere.
//
// Each request gets its own Process object. Cancelling destroys it, and every
// handler checks its request id, so a late reply cannot overwrite newer state.
Item {
    id: rootKipJarvisService

    required property QtObject theme

    readonly property bool mock: false
    readonly property QtObject kt: theme.modules.kip

    // idle | searching | generating | done | empty | error
    property string status: "idle"
    // search | ask | general
    property string kind: ""
    property string query: ""
    property var results: []
    // Ungrouped sources in Jarvis order; SOURCE n in the answer indexes this.
    property var rawSources: []
    property string answer: ""
    property string errorText: ""
    // ollama | index | malformed | process | missing | backend
    property string errorKind: ""
    property string eventKey: ""
    property string model: ""
    property int requestId: 0
    property bool backendAvailable: true

    readonly property bool busy: status === "searching" || status === "generating"

    property var activeProcess: null
    property int malformedLines: 0

    Component {
        id: searchProcessComponent

        Process {
            id: searchProcess

            property int ownerId: -1

            stdout: StdioCollector {
                id: searchStdout

                waitForEnd: true
            }

            stderr: StdioCollector {
                id: searchStderr

                waitForEnd: true
            }

            onExited: exitCode => rootKipJarvisService.finishSearch(searchProcess.ownerId, exitCode, searchStdout.text, searchStderr.text)
        }
    }

    Component {
        id: streamProcessComponent

        Process {
            id: streamProcess

            property int ownerId: -1

            stdout: SplitParser {
                onRead: data => rootKipJarvisService.handleStreamLine(streamProcess.ownerId, data)
            }

            stderr: StdioCollector {
                id: streamStderr

                waitForEnd: true
            }

            onExited: exitCode => rootKipJarvisService.finishStream(streamProcess.ownerId, exitCode, streamStderr.text)
        }
    }

    // Is the backend even installed? Checked once; a failed request rechecks.
    Process {
        id: availabilityProcess

        command: ["/usr/bin/which", rootKipJarvisService.kt.backendCommand]
        running: true

        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: exitCode => rootKipJarvisService.backendAvailable = exitCode === 0
    }

    function search(text) {
        begin("search", text);
        status = "searching";
        eventKey = "notes.searching";
        launch(searchProcessComponent, ["--json", "-search-notes=" + text]);
    }

    function ask(text) {
        begin("ask", text);
        status = "searching";
        eventKey = "ask.submitted";
        launch(streamProcessComponent, ["--json", "-ask-notes=" + text]);
    }

    function general(text) {
        begin("general", text);
        status = "generating";
        eventKey = "general.generating";
        launch(streamProcessComponent, ["--json", "--", text]);
    }

    function cancel() {
        requestId++;

        if (activeProcess) {
            const process = activeProcess;

            activeProcess = null;
            process.running = false;
            process.destroy();
        }
    }

    function reset() {
        cancel();
        status = "idle";
        kind = "";
        query = "";
        results = [];
        rawSources = [];
        answer = "";
        errorText = "";
        errorKind = "";
        eventKey = "";
        malformedLines = 0;
    }

    function begin(nextKind, text) {
        reset();
        kind = nextKind;
        query = text;
    }

    function launch(component, args) {
        if (!backendAvailable) {
            fail("missing", "'" + kt.backendCommand + "' is not on PATH for Quickshell. Install it, or set backendCommand in KipTheme.qml.");
            availabilityProcess.running = true;
            return;
        }

        const process = component.createObject(rootKipJarvisService, {
            ownerId: requestId,
            command: [kt.backendCommand].concat(args)
        });

        activeProcess = process;
        process.running = true;
    }

    function finishSearch(ownerId, exitCode, stdoutText, stderrText) {
        if (ownerId !== requestId)
            return;

        releaseProcess();

        const payload = parseJson(stdoutText.trim());

        if (payload && payload.type === "response.error") {
            failFromMessage(payload.message);
            return;
        }

        if (payload && payload.type === "notes.search.results" && Array.isArray(payload.results)) {
            const grouped = groupResults(payload.results);

            results = grouped;

            if (grouped.length === 0) {
                status = "empty";
                eventKey = "notes.empty";
            } else {
                status = "done";
                eventKey = grouped.some(hit => !hit.weak) ? "notes.found" : "notes.weak";
            }
            return;
        }

        failFromProcess(exitCode, stderrText, payload === null && stdoutText.trim().length > 0);
    }

    function handleStreamLine(ownerId, line) {
        if (ownerId !== requestId)
            return;

        const trimmed = String(line).trim();

        if (trimmed.length === 0)
            return;

        const event = parseJson(trimmed);

        if (!event || typeof event.type !== "string") {
            malformedLines++;
            return;
        }

        switch (event.type) {
        case "response.start":
            model = event.model || "";
            if (kind === "general") {
                status = "generating";
                eventKey = "general.generating";
            }
            return;
        case "response.sources":
            rawSources = Array.isArray(event.sources) ? event.sources : [];
            results = groupResults(rawSources);
            status = "generating";
            eventKey = "ask.generating";
            return;
        case "response.delta":
            if (typeof event.text === "string")
                answer += event.text;
            return;
        case "response.done":
            model = event.model || model;
            status = "done";
            eventKey = kind === "ask" ? "ask.completed" : "general.completed";
            return;
        case "response.error":
            failFromMessage(event.message);
            return;
        }
        // Unknown event types are ignored on purpose: newer Jarvis, older KIP.
    }

    function finishStream(ownerId, exitCode, stderrText) {
        if (ownerId !== requestId)
            return;

        releaseProcess();

        // done/error already arrived; the exit is just the process leaving.
        if (!busy)
            return;

        failFromProcess(exitCode, stderrText, malformedLines > 0);
    }

    function releaseProcess() {
        if (!activeProcess)
            return;

        const process = activeProcess;

        activeProcess = null;
        process.destroy();
    }

    function failFromProcess(exitCode, stderrText, sawMalformed) {
        const detail = lastLine(stderrText);

        if (sawMalformed) {
            fail("malformed", "Jarvis printed something that is not JSON." + (detail ? " stderr: " + detail : ""));
            return;
        }

        if (exitCode !== 0) {
            fail("process", "Jarvis exited with code " + exitCode + "." + (detail ? " " + detail : ""));
            return;
        }

        fail("malformed", "Jarvis finished without a result.");
    }

    function failFromMessage(message) {
        const text = String(message || "Unknown error").replace(/^Jarvis:\s*/, "");

        if (/Cannot reach Ollama|Ollama HTTP/i.test(text))
            fail("ollama", text);
        else if (/No index yet|index-notes|Vector dimensions|Embedding model changed/i.test(text))
            fail("index", text);
        else
            fail("backend", text);
    }

    function fail(nextKind, message) {
        status = "error";
        errorKind = nextKind;
        errorText = message;
        eventKey = ({
                ollama: "error.ollama",
                index: "error.index",
                malformed: "error.malformed",
                missing: "error.backend"
            })[nextKind] || "error.backend";
    }

    // Jarvis already caps chunks per file; KIP folds them into one row per
    // file, keeping rank order and every line range.
    function groupResults(items) {
        const groups = [];
        const byPath = {};

        for (let index = 0; index < items.length; index++) {
            const item = items[index];
            const path = String(item.path || "");

            if (path.length === 0)
                continue;

            const range = {
                start: Number(item.start_line) || 1,
                end: Number(item.end_line) || Number(item.start_line) || 1
            };

            if (byPath[path] !== undefined) {
                groups[byPath[path]].ranges.push(range);
                continue;
            }

            const slash = path.lastIndexOf("/");
            const similarity = typeof item.similarity === "number" ? item.similarity : null;

            byPath[path] = groups.length;
            groups.push({
                path: path,
                absolutePath: String(item.absolute_path || ""),
                folder: "~/Notes/" + (slash >= 0 ? path.slice(0, slash + 1) : ""),
                file: slash >= 0 ? path.slice(slash + 1) : path,
                origin: path.startsWith("Logseq/") ? "logseq" : "legacy",
                line: range.start,
                endLine: range.end,
                ranges: [range],
                score: typeof item.score === "number" ? item.score : null,
                similarity: similarity,
                weak: similarity !== null && similarity < kt.weakSimilarity,
                excerpt: flatten(item.excerpt !== undefined ? item.excerpt : stripHeader(item.content)),
                snippet: stripHeader(item.content)
            });
        }

        return groups;
    }

    // "[SOURCE 3: path:1-4]" or a bare "SOURCE 3" becomes "[3 · file:1–4]",
    // so the answer never cites a number without a real place behind it.
    function citedAnswer(text) {
        if (rawSources.length === 0)
            return text;

        return String(text).replace(/\[?SOURCE\s+(\d+)(?::[^\]\n]*)?\]?/g, (match, number) => {
            const source = rawSources[Number(number) - 1];

            if (!source)
                return match;

            const path = String(source.path || "");
            const file = path.slice(path.lastIndexOf("/") + 1);

            return "[" + number + " · " + file + ":" + source.start_line + "–" + source.end_line + "]";
        });
    }

    // Jarvis chunks start with "File: …" and "Title: …" lines; drop those.
    function stripHeader(content) {
        const lines = String(content || "").split("\n");
        let start = 0;

        while (start < lines.length && start < 2 && /^(File|Title):/.test(lines[start]))
            start++;

        return lines.slice(start).join("\n").trim();
    }

    function flatten(text) {
        return String(text || "").replace(/\s+/g, " ").trim();
    }

    function lastLine(text) {
        const lines = String(text || "").trim().split("\n");
        return lines.length > 0 ? lines[lines.length - 1].slice(0, 300) : "";
    }

    function parseJson(text) {
        try {
            return JSON.parse(text);
        } catch (error) {
            return null;
        }
    }
}
