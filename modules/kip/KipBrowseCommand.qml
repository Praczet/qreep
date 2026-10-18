import QtQuick

// /browse as the panel sees it. The input is the whole state: it names the
// folder, and what follows the last "/" filters it. KipBrowseService lists
// and previews; this keeps the selection and decides what keys mean.
// host is KipPanel.
Item {
    id: rootKipBrowseCommand

    required property QtObject host
    required property QtObject browser

    readonly property bool active: host.contentState === "browse"
    property int index: 0
    readonly property bool listVisible: active && browser.results.length > 0
    readonly property var hit: listVisible ? browser.results[Math.min(index, browser.results.length - 1)] : null
    readonly property string eventKey: browser.eventKey || "browse.ready"

    // Preview follows the selection after a short pause, not per keypress.
    onHitChanged: {
        if (browser.preview)
            previewTimer.restart();
    }

    Timer {
        id: previewTimer

        interval: 120
        repeat: false
        onTriggered: rootKipBrowseCommand.browser.loadPreview(rootKipBrowseCommand.hit)
    }

    function reset() {
        browser.reset();
        index = 0;
    }

    // Typing a filter puts the best match first.
    function show() {
        if (!active) {
            host.backToCompose();
            host.contentState = "browse";
        }

        const where = browser.split(host.parsed.argument);

        browser.open(where.dir);
        browser.filter(where.filter);
        index = 0;
    }

    // Moving is editing the input, so Backspace and typing keep working.
    function goTo(path) {
        const next = browser.inputFor(path);

        // Same text means no textChanged; list it anyway.
        if (host.inputText() === next) {
            show();
            return;
        }

        host.setInput(next);
    }

    function submit(shifted) {
        if (!hit) {
            if (browser.status === "error")
                browser.reload();
            return;
        }

        if (hit.isDir && !shifted) {
            goTo(hit.absolutePath);
            return;
        }

        host.chooseActionsFor(hit);
    }

    function toggle(key) {
        if (key === Qt.Key_H) {
            browser.hidden = !browser.hidden;
            browser.reload();
        } else if (key === Qt.Key_I) {
            browser.respectIgnore = !browser.respectIgnore;
            browser.reload();
        } else {
            browser.preview = !browser.preview;
            browser.loadPreview(hit);
        }
    }

    // True when the key was /browse's: Alt+Up, Up/Down, Tab into a folder,
    // Alt+H/I/P toggles.
    function handleKey(event) {
        const alt = (event.modifiers & Qt.AltModifier) !== 0;

        if (event.key === Qt.Key_Up && alt) {
            event.accepted = true;
            goTo(browser.parentOf(browser.dir));
            return true;
        }

        if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && listVisible) {
            index = host.clampIndex(index + (event.key === Qt.Key_Down ? 1 : -1), browser.results.length);
            event.accepted = true;
            return true;
        }

        if (event.key === Qt.Key_Tab && hit !== null && hit.isDir) {
            event.accepted = true;
            goTo(hit.absolutePath);
            return true;
        }

        if ((event.key === Qt.Key_H || event.key === Qt.Key_I || event.key === Qt.Key_P) && alt) {
            event.accepted = true;
            toggle(event.key);
            return true;
        }

        return false;
    }

    function status() {
        if (browser.status === "error")
            return browser.errorText;

        const where = browser.tilde(browser.dir);

        if (browser.status === "loading")
            return "reading " + where;

        const count = browser.results.filter(item => !item.isParent).length;
        const flags = (browser.hidden ? " · hidden shown" : "") + (browser.respectIgnore ? " · gitignored hidden" : "");

        return where + " · " + count + (count === 1 ? " item" : " items") + (browser.filterText.length > 0 ? " matching" : "") + flags;
    }

    function enterLabel() {
        return hit === null ? (browser.status === "error" ? "retry" : "") : (hit.isDir ? "open" : "actions");
    }

    function keyHints() {
        return "↑↓ move · Enter open · Shift+Enter actions · Tab in · Alt+↑ up · Alt+H hidden · Alt+I gitignore · Alt+P preview · Esc back";
    }
}
