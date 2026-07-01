import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootClipboard

    required property QtObject theme
    property bool open: false
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: clipboardService

    ClipboardService {
        id: clipboardService

        theme: rootClipboard.theme
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-clipboard"

        function toggle() {
            rootClipboard.toggle();
        }

        function show() {
            rootClipboard.show();
        }

        function hide() {
            rootClipboard.hide();
        }

        function refresh() {
            rootClipboard.refresh();
        }
    }

    LazyLoader {
        id: panelLoader

        active: rootClipboard.panelLoaded

        ClipboardPanel {
            theme: rootClipboard.theme
            service: clipboardService
            panelOpen: rootClipboard.open

            onCloseRequested: rootClipboard.hide()
            onRestoreRequested: index => {
                clipboardService.restore(index);
                rootClipboard.hide();
            }
        }
    }

    Timer {
        id: closeTimer

        interval: rootClipboard.theme.modules.clipboard.animationDuration + 40
        repeat: false
    }

    function show() {
        closeTimer.stop();
        clipboardService.refresh();
        open = true;
    }

    function hide() {
        if (!open)
            return;

        closeTimer.restart();
        open = false;
    }

    function toggle() {
        if (open)
            hide();
        else
            show();
    }

    function refresh() {
        clipboardService.refresh();
    }
}
