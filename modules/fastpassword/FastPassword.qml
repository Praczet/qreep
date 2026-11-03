import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootFastPassword

    required property QtObject theme
    property bool open: false
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: fastPasswordService

    FastPasswordService {
        id: fastPasswordService

        theme: rootFastPassword.theme

        onOpenAuthorized: {
            rootFastPassword.openAuthorizedPanel();
        }

        // The stamp ran out. The prompt must not sit under an overlay that holds the
        // keyboard, so close, authenticate, and come back to the same note.
        onNoteAuthRequired: entry => {
            rootFastPassword.hide();
            fastPasswordService.pendingNoteEntry = entry;
            fastPasswordService.requestOpen();
        }
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-fast-password"

        function toggle() {
            rootFastPassword.toggle();
        }

        function showMe() {
            rootFastPassword.show();
        }

        function hideMe() {
            rootFastPassword.hide();
        }

        function refresh() {
            rootFastPassword.refresh();
        }

        function copy(entry: string): string {
            return fastPasswordService.copyEntryName(entry);
        }
    }

    LazyLoader {
        active: rootFastPassword.panelLoaded

        FastPasswordPanel {
            theme: rootFastPassword.theme
            service: fastPasswordService
            panelOpen: rootFastPassword.open

            onCloseRequested: rootFastPassword.hide()
            onEntryActivated: index => rootFastPassword.activate(index)
        }
    }

    Timer {
        id: closeTimer

        interval: rootFastPassword.theme.modules.fastPassword.animationDuration + 40
        repeat: false
    }

    function show() {
        closeTimer.stop();
        fastPasswordService.requestOpen();
    }

    function openAuthorizedPanel() {
        closeTimer.stop();
        fastPasswordService.refresh();
        open = true;
        fastPasswordService.resumePendingNote();
    }

    // A note opens in the panel, which stays up. Anything else copies and closes.
    function activate(index) {
        const entry = fastPasswordService.entryAt(index);

        if (entry && entry.kind === "note")
            fastPasswordService.openNote(entry);
        else if (fastPasswordService.copy(index))
            hide();
    }

    function hide() {
        fastPasswordService.clearNote();

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
        fastPasswordService.refresh();
    }
}
