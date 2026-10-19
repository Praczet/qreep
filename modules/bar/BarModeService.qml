import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: rootBarModeService

    property string mode: "reserved"
    readonly property bool reserved: mode === "reserved"
    readonly property bool overlay: mode === "overlay"
    readonly property bool collapsed: mode === "collapsed"
    readonly property var validModes: ["reserved", "overlay", "collapsed"]
    // The screen the bar lives on. Picked from Hyprland's focused monitor, not
    // left to Quickshell's default: closing the lid during login used to
    // leave the bar on eDP while the work happened on the external monitor.
    // Assigned, never bound: a binding would chase focus across monitors.
    property var screen: null
    // False until the focused monitor was known at placement time; Hyprland
    // may not have reported one yet when the bar starts.
    property bool placedOnFocused: false
    readonly property var screens: Quickshell.screens
    readonly property var focusedMonitor: Hyprland.focusedMonitor

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-bar"

        function setMode(mode: string): string {
            return rootBarModeService.setMode(mode);
        }

        function setReserved(): string {
            return rootBarModeService.setMode("reserved");
        }

        function setOverlay(): string {
            return rootBarModeService.setMode("overlay");
        }

        function setCollapsed(): string {
            return rootBarModeService.setMode("collapsed");
        }

        function getMode(): string {
            return rootBarModeService.mode;
        }

        function toggleOverlay(): string {
            return rootBarModeService.setMode(rootBarModeService.reserved ? "overlay" : "reserved");
        }

        function toggleCollapsed(): string {
            return rootBarModeService.setMode(rootBarModeService.collapsed ? "reserved" : "collapsed");
        }

        function moveToFocused(): string {
            return rootBarModeService.moveToFocused();
        }

        function getScreen(): string {
            return rootBarModeService.screen ? rootBarModeService.screen.name : "none";
        }
    }

    Component.onCompleted: moveToFocused()

    // First real focus report after a fallback placement: move once, then stay.
    onFocusedMonitorChanged: {
        if (!placedOnFocused)
            moveToFocused();
    }

    // A screen went away (lid closed, monitor unplugged): follow focus
    // instead of waiting for Quickshell to pick something.
    onScreensChanged: {
        if (!screen || screens.indexOf(screen) < 0)
            moveToFocused();
    }

    function moveToFocused() {
        const next = screenForFocusedMonitor();

        placedOnFocused = Hyprland.focusedMonitor !== null;
        if (next !== screen)
            screen = next;

        return screen ? screen.name : "none";
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

    function setMode(nextMode) {
        const normalized = normalizeMode(nextMode);

        if (normalized.length === 0)
            return mode;

        if (normalized === mode)
            return mode;

        mode = normalized;
        return mode;
    }

    function normalizeMode(value) {
        const normalized = String(value || "").trim().toLowerCase();

        for (let index = 0; index < validModes.length; index++) {
            if (validModes[index] === normalized)
                return normalized;
        }

        return "";
    }
}
