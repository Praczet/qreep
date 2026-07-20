import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootTriage

    required property QtObject theme
    property bool open: false
    property int topReservedHeight: 0
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: triageService

    TriageService {
        id: triageService

        theme: rootTriage.theme
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-triage"

        function toggle() {
            rootTriage.toggle();
        }

        function showMe() {
            rootTriage.show();
        }

        function hideMe() {
            rootTriage.hide();
        }

        function refresh() {
            rootTriage.refresh();
        }
    }

    LazyLoader {
        active: rootTriage.panelLoaded

        TriagePanel {
            theme: rootTriage.theme
            service: triageService
            panelOpen: rootTriage.open
            topReservedHeight: rootTriage.topReservedHeight

            onCloseRequested: rootTriage.hide()
        }
    }

    Timer {
        id: closeTimer

        interval: rootTriage.theme.modules.triage.animationDuration + 40
        repeat: false
    }

    function show() {
        closeTimer.stop();
        triageService.refresh();
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
        triageService.refresh();
    }
}
