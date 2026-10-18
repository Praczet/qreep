import QtQuick

// /keys as the panel sees it: the filtered Hyprland binds, the selection, and
// Enter copying the key combo. KipBindsService reads hyprctl. host is KipPanel.
Item {
    id: rootKipKeysCommand

    required property QtObject host
    required property QtObject binds

    readonly property bool active: host.contentState === "keys"
    property int index: 0
    readonly property bool listVisible: active && binds.results.length > 0
    readonly property string eventKey: binds.eventKey || "keys.ready"

    function reset() {
        binds.reset();
    }

    // "/keys " lists every bind; typing narrows them.
    function show() {
        if (!active) {
            host.backToCompose();
            host.contentState = "keys";
            index = 0;
            binds.load();
        }
        binds.filter(host.parsed.argument);
        index = 0;
    }

    function submit() {
        const bind = binds.results[index];

        if (!bind)
            return;

        host.copyRequested(bind.combo);
        host.notice = "Copied " + bind.combo + ".";
    }

    function handleKey(event) {
        if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && listVisible) {
            index = host.clampIndex(index + (event.key === Qt.Key_Down ? 1 : -1), binds.results.length);
            event.accepted = true;
            return true;
        }
        return false;
    }

    function status() {
        if (binds.status === "error")
            return binds.errorText;
        if (binds.status === "loading")
            return "reading hyprctl binds";
        if (binds.status !== "ready")
            return "";
        return (binds.results.length === binds.binds.length ? binds.binds.length + " binds" : binds.results.length + " of " + binds.binds.length + " binds") + " · hyprctl binds";
    }

    function enterLabel() {
        return listVisible ? "copy keys" : "";
    }

    function keyHints() {
        return listVisible ? "↑↓ move · Enter copies the keys · Esc back · keep typing to filter" : "Esc back · fewer words?";
    }
}
