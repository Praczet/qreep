import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootBloom

    required property QtObject theme
    property bool open: false
    readonly property alias service: bloomService

    BloomStatusService {
        id: bloomService

        onRunningChanged: {
            if (running)
                rootBloom.show();
        }

        onTerminalStateReached: {
            rootBloom.show();
            hideTimer.restart();
        }
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-bloom"

        function showBloom(profile: string, wallpaper: string): string {
            rootBloom.showBloom(profile, wallpaper);
            return "ok";
        }

        function doneBloom(): string {
            rootBloom.doneBloom();
            return "ok";
        }

        function hideBloom(): string {
            rootBloom.hide();
            return "ok";
        }

        function pickupBloom(): string {
            rootBloom.recover();
            return "ok";
        }

        function showMe(): string {
            rootBloom.show();
            return "ok";
        }

        function hideMe(): string {
            rootBloom.hide();
            return "ok";
        }
    }

    LazyLoader {
        active: rootBloom.open

        BloomPanel {
            theme: rootBloom.theme
            service: bloomService
            panelOpen: rootBloom.open
        }
    }

    Timer {
        id: hideTimer

        interval: rootBloom.theme.modules.bloom.autoDismissDelay
        repeat: false
        onTriggered: {
            if (!bloomService.running)
                rootBloom.hide();
        }
    }

    function showBloom(profile, wallpaper) {
        hideTimer.stop();
        bloomService.show(profile, wallpaper);
        open = true;
    }

    function doneBloom() {
        bloomService.done();
    }

    function recover() {
        bloomService.recover();

        if (bloomService.visibleRequested)
            show();
    }

    function show() {
        hideTimer.stop();
        bloomService.visibleRequested = true;
        open = true;
    }

    function hide() {
        bloomService.hide();
        open = false;
    }
}
