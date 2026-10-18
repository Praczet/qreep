import QtQuick

// /rg as the panel sees it: when to search, flag complaints, the selection,
// and the status line. KipGrepService runs ripgrep. host is KipPanel.
Item {
    id: rootKipGrepCommand

    required property QtObject host
    required property QtObject grep

    readonly property QtObject kt: host.kt
    readonly property bool active: host.contentState === "grep"
    property int index: 0
    readonly property bool listVisible: active && grep.results.length > 0
    readonly property string eventKey: grep.eventKey || "rg.searching"

    // Searches after a short pause in typing, from rgMinChars.
    Timer {
        id: searchTimer

        interval: rootKipGrepCommand.kt.rgDebounce
        repeat: false
        onTriggered: {
            if (rootKipGrepCommand.wanted())
                rootKipGrepCommand.search();
        }
    }

    function reset() {
        grep.reset();
        index = 0;
    }

    function wanted() {
        const parsed = host.parsed;

        return parsed.mode === "ready" && parsed.command !== null && parsed.command.kind === "grep" && parsed.argument.trim().length >= kt.rgMinChars && parsed.unknownFlags.length === 0;
    }

    function flagProblem() {
        const parsed = host.parsed;

        if (parsed.mode !== "ready" || !parsed.command || parsed.command.kind !== "grep" || parsed.unknownFlags.length === 0)
            return "";

        const flag = parsed.unknownFlags[0];
        const key = flag.replace(/^--/, "").replace(/=.*$/, "");

        if (key === "f")
            return "--f needs a folder: --f=~/.config.";
        if (key === "t")
            return "--t needs a type: --t=py, --t=rust, --t=md.";
        if (key === "h")
            return "--h takes no value; it just means hidden files too.";
        return "I don't know " + flag + ". /rg knows --f=<dir>, --h and --t=<type>.";
    }

    function schedule() {
        searchTimer.restart();
    }

    // Enter beat the debounce: search now.
    function searchNow() {
        searchTimer.stop();
        if (flagProblem().length === 0)
            search();
    }

    // Keeps the current list up while a new search runs (refresh in place).
    function search() {
        const fresh = !active;
        const parsed = host.parsed;

        if (fresh) {
            host.backToCompose();
            host.contentState = "grep";
        }
        index = 0;
        host.chooserHit = null;
        grep.search(parsed.argument, parsed.flags.from || "", parsed.flags.hidden === true, parsed.flags.type || "", !fresh);
    }

    function activate() {
        const hit = grep.results[index];

        if (hit)
            host.chooseActionsFor(hit);
    }

    function submit() {
        if (listVisible)
            activate();
        else if (grep.status === "error" && host.parsed.argument.length > 0)
            search();
    }

    function handleKey(event) {
        if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && listVisible) {
            index = host.clampIndex(index + (event.key === Qt.Key_Down ? 1 : -1), grep.results.length);
            event.accepted = true;
            return true;
        }
        return false;
    }

    function status() {
        const where = grep.tilde(grep.root || grep.expand(kt.rgDefaultRoot));
        const scope = where + (grep.hidden ? " · hidden included" : "") + (grep.fileType.length > 0 ? " · " + grep.fileType + " only" : "");

        if (grep.status === "error")
            return grep.errorText;
        if (grep.status === "searching" && grep.results.length === 0)
            return "rg in " + scope;
        if (grep.status === "empty")
            return "nothing in " + scope;

        const files = {};

        for (const hit of grep.results)
            files[hit.absolutePath] = true;
        return grep.results.length + (grep.truncated ? "+" : "") + " lines in " + Object.keys(files).length + " files · " + scope + (grep.truncated ? " · capped at " + kt.rgMaxResults : "") + (grep.busy ? " · still searching" : "");
    }

    function enterLabel() {
        return listVisible ? "actions" : (grep.status === "error" ? "retry" : "");
    }

    function keyHints() {
        return listVisible ? "↑↓ move · Enter actions (nvim at the line first) · Esc back · keep typing to refine" : "Esc back · keep typing to refine";
    }
}
