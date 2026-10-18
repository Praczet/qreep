import QtQuick

// /win as the panel sees it: the selection, grid/list keys, and focusing.
// KipWindowService reads hyprctl and focuses through Expose; view is the
// KipWindowView, which knows the grid geometry. host is KipPanel.
Item {
    id: rootKipWindowsCommand

    required property QtObject host
    required property QtObject windows
    property Item view: null

    readonly property bool active: host.contentState === "windows"
    property int index: 0
    readonly property bool listVisible: active && windows.results.length > 0
    readonly property string eventKey: windows.eventKey

    function reset() {
        windows.reset();
    }

    // "/win " lists windows; typing narrows them.
    function show() {
        if (!active) {
            host.backToCompose();
            host.contentState = "windows";
            index = 0;
            windows.load();
        }
        windows.filter(host.parsed.argument);
        index = Math.min(index, Math.max(0, windows.results.length - 1));
    }

    function focusSelected() {
        const client = windows.results[index];

        if (client && windows.focusClient(client))
            host.closeRequested();
    }

    function submit() {
        focusSelected();
    }

    // Arrows move spatially (Left/Right only in the grid), Ctrl+L grid/list,
    // Ctrl+P icons/previews.
    function handleKey(event) {
        const control = (event.modifiers & Qt.ControlModifier) !== 0;

        if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right) && listVisible && view.gridMode) {
            index = view.neighbor(index, event.key === Qt.Key_Right ? 1 : -1, 0);
            event.accepted = true;
            return true;
        }

        if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && listVisible) {
            index = view.neighbor(index, 0, event.key === Qt.Key_Down ? 1 : -1);
            event.accepted = true;
            return true;
        }

        if (event.key === Qt.Key_P && control) {
            event.accepted = true;
            windows.toggleDisplay();
            return true;
        }

        if (event.key === Qt.Key_L && control) {
            event.accepted = true;
            windows.toggleView();
            return true;
        }

        return false;
    }

    function enterLabel() {
        return listVisible ? "switch" : "";
    }

    function keyHints() {
        return listVisible ? (view.gridMode ? "←→↑↓ choose" : "↑↓ choose") + " · Enter switch · Ctrl+L grid/list · Ctrl+P icons/previews · Esc back" : "Esc back · fewer words?";
    }
}
