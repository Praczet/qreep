import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootAegis

    required property QtObject theme
    property bool open: false
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: aegisService

    AegisService {
        id: aegisService

        theme: rootAegis.theme
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-aegis"

        function toggle() {
            rootAegis.toggle();
        }

        function showMe() {
            rootAegis.show();
        }

        function hideMe() {
            rootAegis.hide();
        }

        function refresh() {
            rootAegis.refresh();
        }

        function setMode(mode: string): string {
            aegisService.setMode(mode);
            return aegisService.mode;
        }

        function copyText(): string {
            aegisService.copyInfo("text");
            return "copied text";
        }

        function copyJson(): string {
            aegisService.copyInfo("json");
            return "copied json";
        }
    }

    LazyLoader {
        id: panelLoader

        active: rootAegis.panelLoaded

        AegisPanel {
            theme: rootAegis.theme
            service: aegisService
            panelOpen: rootAegis.open

            onCloseRequested: rootAegis.hide()
        }
    }

    Timer {
        id: closeTimer

        interval: rootAegis.theme.modules.aegis.animationDuration + 40
        repeat: false
    }

    function show() {
        closeTimer.stop();
        aegisService.setActive("aegis-panel", true);
        open = true;
    }

    function hide() {
        if (!open)
            return;

        closeTimer.restart();
        open = false;
        aegisService.setActive("aegis-panel", false);
    }

    function toggle() {
        if (open)
            hide();
        else
            show();
    }

    function refresh() {
        aegisService.refresh();
    }
}
