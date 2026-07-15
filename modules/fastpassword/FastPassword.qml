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
            onCopyRequested: index => {
                if (fastPasswordService.copy(index))
                    rootFastPassword.hide();
            }
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
        fastPasswordService.refresh();
    }
}
