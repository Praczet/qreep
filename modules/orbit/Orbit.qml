import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Orbit controller: IPC, open state, the service, and a lazy overlay on
// whichever monitor has focus when it opens.
Scope {
    id: rootOrbit

    required property QtObject theme
    property bool open: false
    property var targetScreen: null
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: orbitService

    OrbitService {
        id: orbitService

        theme: rootOrbit.theme

        onCloseRequested: rootOrbit.hide()
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-orbit"

        // name: "mox" for ~/.config/qreep/orbit/mox.json, or an absolute path.
        // Not called show: the quickshell CLI reads that word as `ipc show`.
        function showWith(name: string) {
            rootOrbit.show(name);
        }

        // Closes only when this same file is showing; another name switches.
        function toggleWith(name: string) {
            if (rootOrbit.open && orbitService.fileName === name)
                rootOrbit.hide();
            else
                rootOrbit.show(name);
        }

        function hideMe() {
            rootOrbit.hide();
        }

        function state(): string {
            const current = orbitService.current;
            const selected = orbitService.selectedNode;

            return "open=" + rootOrbit.open
                + " file=" + (orbitService.fileName || "-")
                + " current=" + (current ? current.name : "-")
                + " depth=" + orbitService.trail.length
                + " selected=" + (selected ? selected.name : "-")
                + " typed=" + (orbitService.typed || "-")
                + " error=" + (orbitService.error || "-");
        }
    }

    LazyLoader {
        active: rootOrbit.panelLoaded

        OrbitPanel {
            screen: rootOrbit.targetScreen
            theme: rootOrbit.theme
            service: orbitService
            panelOpen: rootOrbit.open

            onCloseRequested: rootOrbit.hide()
        }
    }

    Timer {
        id: closeTimer

        interval: rootOrbit.theme.modules.orbit.shrinkDuration + 40
        repeat: false
    }

    function show(name) {
        if (!panelLoaded)
            targetScreen = screenForFocusedMonitor();

        closeTimer.stop();
        orbitService.load(name);
        open = true;
    }

    function hide() {
        if (!open)
            return;

        closeTimer.restart();
        open = false;
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
}
