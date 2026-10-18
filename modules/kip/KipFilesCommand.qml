import QtQuick

// /fd as the panel sees it: when to search, flag complaints, the selection,
// and the status line. KipFileSearchService runs fd. host is KipPanel.
Item {
    id: rootKipFilesCommand

    required property QtObject host
    required property QtObject files

    readonly property QtObject kt: host.kt
    readonly property bool active: host.contentState === "files"
    property int index: 0
    readonly property var shown: files.results.slice(0, kt.fdShownResults)
    readonly property bool listVisible: active && shown.length > 0
    readonly property string eventKey: files.eventKey

    // Searches after a pause in typing, not per keystroke.
    Timer {
        id: searchTimer

        interval: rootKipFilesCommand.kt.fdDebounce
        repeat: false
        onTriggered: {
            if (rootKipFilesCommand.wanted())
                rootKipFilesCommand.search();
        }
    }

    function reset() {
        files.reset();
    }

    function wanted() {
        const parsed = host.parsed;

        return parsed.mode === "ready" && parsed.command !== null && parsed.command.kind === "files" && parsed.argument.length > 0 && parsed.unknownFlags.length === 0;
    }

    // "--f" without a value or an unknown flag: say which, instead of searching.
    function flagProblem() {
        const parsed = host.parsed;

        if (parsed.mode !== "ready" || !parsed.command || parsed.command.kind !== "files" || parsed.unknownFlags.length === 0)
            return "";

        const flag = parsed.unknownFlags[0];
        const key = flag.replace(/^--/, "").replace(/=.*$/, "");

        if (key === "f")
            return "--f needs a folder: --f=/ or --f=~/Notes.";
        if (key === "h")
            return "--h takes no value; it just means hidden files too.";
        return "I don't know " + flag + ". /fd knows --f=<dir> and --h.";
    }

    function schedule() {
        searchTimer.restart();
    }

    // Keeps the current list up while a new search runs (refresh in place).
    function search() {
        const fresh = !active;
        const parsed = host.parsed;

        if (fresh)
            index = 0;

        host.contentState = "files";
        host.chooserHit = null;
        files.search(parsed.argument, parsed.flags.from || "", parsed.flags.hidden === true, !fresh);
    }

    function activate() {
        const hit = shown[index];

        if (hit)
            host.chooseActionsFor(hit);
    }

    function submit() {
        if (listVisible)
            activate();
        else if (files.status === "error" && wanted())
            search();
    }

    function handleKey(event) {
        if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && listVisible) {
            index = host.clampIndex(index + (event.key === Qt.Key_Down ? 1 : -1), shown.length);
            event.accepted = true;
            return true;
        }
        return false;
    }

    function status() {
        const where = files.tilde(files.root);
        const hiddenNote = files.hidden ? " · hidden included" : "";

        switch (files.status) {
        case "searching":
            return "searching " + where + hiddenNote;
        case "done":
            return Math.min(files.results.length, kt.fdShownResults) + (files.truncated ? " of " + kt.fdMaxResults + "+" : (files.results.length > kt.fdShownResults ? " of " + files.results.length : "")) + " in " + where + hiddenNote;
        case "empty":
            return "nothing in " + where + hiddenNote;
        case "error":
            return files.errorText;
        }
        return "";
    }

    function enterLabel() {
        return listVisible ? "actions" : (files.status === "error" ? "retry" : "");
    }

    function keyHints() {
        if (files.status === "error")
            return "Enter retry · Esc back · fix --f= to search elsewhere";
        return listVisible ? "↑↓ move · Enter actions · Esc back · keep typing to refine" : "Esc back · keep typing to refine";
    }
}
