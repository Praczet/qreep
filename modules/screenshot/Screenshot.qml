import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: rootScreenshot

    required property QtObject theme
    property bool open: false
    property int delaySeconds: 3
    property string backend: "flameshot"
    property int pendingDelaySeconds: 3
    property string pendingBackend: "flameshot"
    readonly property alias workflowRunning: screenshotBackend.running

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-screenshot"

        function toggle() {
            rootScreenshot.toggle();
        }

        function showMe() {
            rootScreenshot.show();
        }

        function hideMe() {
            rootScreenshot.hide();
        }

        function state(): string {
            const targetScreen = rootScreenshot.screenForFocusedMonitor();
            return "open=" + rootScreenshot.open
                + " running=" + screenshotBackend.running
                + " screen=" + (targetScreen ? targetScreen.name : "none");
        }
    }

    ScreenshotBackend {
        id: screenshotBackend
    }

    LazyLoader {
        active: rootScreenshot.open

        DelayedScreenshotDialog {
            screen: rootScreenshot.screenForFocusedMonitor()
            theme: rootScreenshot.theme
            initialDelaySeconds: rootScreenshot.delaySeconds
            initialBackend: rootScreenshot.backend

            onAccepted: (delay, selectedBackend) => rootScreenshot.accept(delay, selectedBackend)
            onCancelled: rootScreenshot.hide()
        }
    }

    Timer {
        id: launchTimer

        interval: rootScreenshot.theme.modules.screenshot.launchDelay
        repeat: false
        onTriggered: screenshotBackend.start(rootScreenshot.pendingDelaySeconds, rootScreenshot.pendingBackend)
    }

    function screenForFocusedMonitor() {
        const monitor = Hyprland.focusedMonitor;

        if (monitor) {
            for (let index = 0; index < Quickshell.screens.length; index++) {
                const candidate = Quickshell.screens[index];

                if (candidate && candidate.name === monitor.name)
                    return candidate;
            }
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function show() {
        if (screenshotBackend.running)
            return;

        open = true;
    }

    function hide() {
        open = false;
    }

    function toggle() {
        if (screenshotBackend.running) {
            screenshotBackend.cancel();
        } else if (open) {
            hide();
        } else {
            show();
        }
    }

    function accept(delay, selectedBackend) {
        delaySeconds = Math.max(0, Math.min(30, Number(delay)));
        backend = String(selectedBackend || "flameshot").toLowerCase() === "grim" ? "grim" : "flameshot";
        pendingDelaySeconds = delaySeconds;
        pendingBackend = backend;

        // Unmap the keyboard-grabbing layer before either selector is launched.
        open = false;
        launchTimer.restart();
    }
}
