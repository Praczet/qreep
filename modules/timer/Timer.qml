import QtQuick as QQ
import QtQml
import Quickshell
import Quickshell.Io

Scope {
    id: rootTimer

    required property QtObject theme
    property var osd: null
    property bool open: false
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: timerService

    TimerService {
        id: timerService

        osd: rootTimer.osd
    }

    Connections {
        target: timerService

        function onStarted() {
            rootTimer.hide();
        }
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-timer"

        function toggle() {
            rootTimer.toggle();
        }

        function showMe() {
            rootTimer.show();
        }

        function hideMe() {
            rootTimer.hide();
        }

        function refresh() {
            timerService.tick();
        }

        function startTimer(label: string) {
            timerService.startTimer(label);
        }

        function startCountdown(duration: string, label: string) {
            timerService.startCountdown(duration, label);
        }

        function startCountdownUntil(finishAt: string, label: string) {
            timerService.startCountdownUntil(finishAt, label);
        }

        function setNotificationMode(mode: string) {
            timerService.setNotificationMode(mode);
        }

        function pause() {
            timerService.pause();
        }

        function resume() {
            timerService.resume();
        }

        function toggleRunning() {
            timerService.toggleRunning();
        }

        function stop() {
            timerService.stop();
        }
    }

    LazyLoader {
        active: rootTimer.panelLoaded

        TimerPanel {
            theme: rootTimer.theme
            service: timerService
            panelOpen: rootTimer.open

            onCloseRequested: rootTimer.hide()
        }
    }

    QQ.Timer {
        id: closeTimer

        interval: rootTimer.theme.modules.timer.animationDuration + 40
        repeat: false
    }

    function show() {
        closeTimer.stop();
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
}
