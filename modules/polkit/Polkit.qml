import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootPolkit

    required property QtObject theme
    property bool open: false
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: polkitService

    PolkitService {
        id: polkitService
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-polkit"

        function toggle() {
            rootPolkit.toggle("ipc:toggle");
        }

        function showMe() {
            rootPolkit.show("ipc:showMe");
        }

        function hideMe() {
            rootPolkit.hide("ipc:hideMe");
        }

        function demo() {
            rootPolkit.show("ipc:demo");
        }
    }

    LazyLoader {
        id: panelLoader

        active: rootPolkit.panelLoaded

        PolkitPanel {
            theme: rootPolkit.theme
            service: polkitService
            panelOpen: rootPolkit.open

            onCloseRequested: reason => rootPolkit.hide(reason)
            onAuthenticated: rootPolkit.hide("success")
        }
    }

    Timer {
        id: closeTimer

        interval: rootPolkit.theme.modules.polkit.animationDuration + 40
        repeat: false
    }

    function show(caller) {
        closeTimer.stop();
        polkitService.loadDemo(caller || "internal");
        open = true;
    }

    function hide(reason) {
        if (!open)
            return;

        const outcomeReason = String(reason || "cancel");
        if (outcomeReason !== "success")
            polkitService.cancel(outcomeReason);

        closeTimer.restart();
        open = false;
    }

    function toggle(caller) {
        if (open)
            hide("toggle");
        else
            show(caller || "internal:toggle");
    }
}
