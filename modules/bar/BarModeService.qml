import QtQuick
import Quickshell.Io

QtObject {
    id: rootBarModeService

    property string mode: "reserved"
    readonly property bool reserved: mode === "reserved"
    readonly property bool overlay: mode === "overlay"
    readonly property bool collapsed: mode === "collapsed"
    readonly property var validModes: ["reserved", "overlay", "collapsed"]

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
