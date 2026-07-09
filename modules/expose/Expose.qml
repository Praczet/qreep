import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootExpose

    required property QtObject theme
    property bool open: false
    property var pendingActivationClient: null
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: exposeService

    ExposeService {
        id: exposeService

        theme: rootExpose.theme

        onFocusCompleted: rootExpose.hide()
        onOpenReady: rootExpose.open = true
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-expose"

        function toggle() {
            rootExpose.toggle();
        }

        function showMe() {
            rootExpose.show();
        }

        function hideMe() {
            rootExpose.hide();
        }

        function refresh() {
            rootExpose.refresh();
        }
    }

    LazyLoader {
        active: rootExpose.panelLoaded

        ExposePanel {
            theme: rootExpose.theme
            service: exposeService
            panelOpen: rootExpose.open

            onCloseRequested: rootExpose.hide()
            onActivateRequested: client => rootExpose.activateClient(client)
        }
    }

    Timer {
        id: closeTimer

        interval: rootExpose.theme.modules.expose.animationDuration + 40
        repeat: false
    }

    Timer {
        id: activationTimer

        interval: 40
        repeat: false
        onTriggered: {
            const client = rootExpose.pendingActivationClient;

            rootExpose.pendingActivationClient = null;
            exposeService.focusClient(client);
        }
    }

    function show() {
        closeTimer.stop();
        exposeService.refreshForOpen();
    }

    function hide() {
        if (!open)
            return;

        closeTimer.restart();
        open = false;
    }

    function hideImmediate() {
        closeTimer.stop();
        open = false;
    }

    function activateClient(client) {
        if (!client)
            return;

        pendingActivationClient = client;
        hideImmediate();
        activationTimer.restart();
    }

    function toggle() {
        if (open)
            hide();
        else
            show();
    }

    function refresh() {
        exposeService.refresh();
    }
}
