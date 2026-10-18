import QtQuick

// /last as the panel sees it: the count, the live refresh, the selection, and
// the actions menu. KipScreenshotService lists the folder. host is KipPanel.
Item {
    id: rootKipShotsCommand

    required property QtObject host
    required property QtObject shots

    readonly property QtObject kt: host.kt
    readonly property bool active: host.contentState === "shots"
    property int index: 0
    readonly property bool listVisible: active && shots.shots.length > 0
    readonly property int columns: Math.max(1, Math.min(kt.screenshotColumns, shots.shots.length))
    readonly property string eventKey: shots.eventKey

    // Typing "/last 12" refreshes once, not once per digit.
    Timer {
        id: refreshTimer

        interval: 120
        repeat: false
        onTriggered: {
            if (rootKipShotsCommand.wanted())
                rootKipShotsCommand.load(rootKipShotsCommand.host.parsed.argument);
        }
    }

    function reset() {
        shots.reset();
    }

    // /last followed by a space (and maybe a count). A bare "/last" waits,
    // so typing "/la" on the way to something else does not run find.
    function wanted() {
        const parsed = host.parsed;

        return parsed.mode === "ready" && parsed.command !== null && parsed.command.kind === "screenshots" && host.inputText().length > parsed.token.length + 1;
    }

    // Live preview while typing: refresh in place, or load the first time.
    function schedule() {
        if (active)
            refreshTimer.restart();
        else
            load(host.parsed.argument);
    }

    // "/last" → 1, "/last 4" → 4, capped at maxScreenshots.
    function load(argument) {
        const text = String(argument || "").trim();

        if (text.length > 0 && !/^\d+$/.test(text)) {
            if (active)
                host.backToCompose();
            host.notice = "/last takes a number, like /last 3.";
            return;
        }

        const asked = text.length > 0 ? Number(text) : 1;
        const count = Math.max(1, Math.min(kt.maxScreenshots, asked));

        host.chooserHit = null;
        host.notice = asked > count ? "Capped at " + count + ". Nobody needs " + asked + " screenshots at once." : "";

        // Already showing shots: refresh in place, keep the selection if it still fits.
        if (active) {
            index = Math.min(index, count - 1);
            shots.refresh(count);
            return;
        }

        host.contentState = "shots";
        index = 0;
        shots.load(count);
    }

    function activate() {
        const shot = shots.shots[index];

        if (shot)
            host.openChooser(shot, shot.file, kt.screenshotActions, "file://" + shot.absolutePath.split("/").map(encodeURIComponent).join("/"));
    }

    function submit() {
        if (shots.status === "error")
            load(String(shots.requested));
        else if (listVisible)
            activate();
    }

    // Left/Right move by one, Up/Down by a row of the grid.
    function handleKey(event) {
        if (!listVisible)
            return false;

        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            index = host.clampIndex(index + (event.key === Qt.Key_Right ? 1 : -1), shots.shots.length);
            event.accepted = true;
            return true;
        }

        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            index = host.clampIndex(index + (event.key === Qt.Key_Down ? 1 : -1) * columns, shots.shots.length);
            event.accepted = true;
            return true;
        }

        return false;
    }

    function status() {
        switch (shots.status) {
        case "loading":
            return "listing " + kt.screenshotDir;
        case "done":
            return shots.shots.length + " newest · " + kt.screenshotDir;
        case "empty":
            return "no images in " + kt.screenshotDir;
        case "error":
            return shots.errorText;
        }
        return "";
    }

    function enterLabel() {
        return shots.status === "error" ? "retry" : (listVisible ? "actions" : "");
    }

    function keyHints() {
        if (shots.status === "error")
            return "Enter retry · Esc back";
        return listVisible ? (columns > 1 ? "←→↑↓ move · " : "") + "Enter actions · Esc back" : "Esc back";
    }
}
