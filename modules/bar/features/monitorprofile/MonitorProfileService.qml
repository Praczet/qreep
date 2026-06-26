import QtQuick
import Quickshell
import Quickshell.Io
import "../../core" as Core

QtObject {
    id: rootMonitorProfileService

    property QtObject log

    property var monitorProfile: null

    readonly property Core.Log fallbackLog: Core.Log {}
    readonly property string runtimeDir: String(Quickshell.env("XDG_RUNTIME_DIR") || "/tmp")
    readonly property string profilePath: runtimeDir + "/hypr-monitor-profile-qreep.json"
    readonly property int connectedMonitorCount: connectedMonitors().length
    readonly property string connectedMonitorsText: monitorIcons().join(" ") || "󰍹"
    readonly property string connectedMonitorNames: monitorNames().join(", ") || "Unknown"
    readonly property string tooltipContent: tooltipLines().join("\n")

    readonly property FileView profileFile: FileView {
        path: rootMonitorProfileService.profilePath
        preload: true
        watchChanges: true

        onLoaded: rootMonitorProfileService.loadProfile()
        onTextChanged: rootMonitorProfileService.loadProfile()
        onLoadFailed: error => {
            rootMonitorProfileService.monitorProfile = null;

            if (error !== FileViewError.FileNotFound) {
                rootMonitorProfileService.reportError("Monitor profile read error:", FileViewError.toString(error), path);
            }
        }
    }

    signal pulseRequested
    signal updateRequested

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-monitor-profile"

        function refresh() {
            rootMonitorProfileService.refreshWithPulse();
        }

        function update() {
            rootMonitorProfileService.update();
        }
    }

    function refreshWithPulse() {
        refresh();
        pulseRequested();
    }

    function refresh() {
        profileFile.reload();
    }

    function update() {
        refresh();
        updateRequested();
    }

    function loadProfile() {
        const contents = profileFile.text();

        if (contents.length === 0) {
            monitorProfile = null;
            return;
        }

        try {
            const payload = JSON.parse(contents);
            monitorProfile = payload && typeof payload === "object" ? payload : null;
        } catch (error) {
            reportError("Monitor profile JSON error:", error);
            monitorProfile = null;
        }
    }

    function connectedMonitors() {
        if (!monitorProfile || !Array.isArray(monitorProfile.layout))
            return [];

        return monitorProfile.layout.filter(screen => screen).slice().sort((left, right) => {
            const leftPosition = screenPosition(left);
            const rightPosition = screenPosition(right);

            if (leftPosition.x !== rightPosition.x)
                return leftPosition.x - rightPosition.x;

            return leftPosition.y - rightPosition.y;
        });
    }

    function monitorIcons() {
        return connectedMonitors().map(screen => screen.external ? "󰍹" : "󰌢");
    }

    function screenPosition(screen) {
        const match = String(screen.position || "").match(/^(-?\d+)x(-?\d+)$/);

        if (!match)
            return {
                "x": 0,
                "y": 0
            };

        return {
            "x": Number(match[1]),
            "y": Number(match[2])
        };
    }

    function monitorNames() {
        return connectedMonitors().map(screen => {
            return monitorLabel(screen);
        }).filter(name => name);
    }

    function tooltipLines() {
        if (!monitorProfile)
            return ["No monitor profile loaded"];

        const lines = ["Profile: " + valueOrUnknown(monitorProfile.profile), "Reason : " + valueOrUnknown(monitorProfile.reason), "Detail : " + valueOrUnknown(monitorProfile.detail)];
        const monitors = monitorTooltipLines();

        if (monitors.length > 0) {
            lines.push("");
            lines.push("Monitors:");

            for (let index = 0; index < monitors.length; index++)
                lines.push(monitors[index]);
        }

        return lines;
    }

    function monitorTooltipLines() {
        return connectedMonitors().map(screen => {
            const icon = screen.external ? "󰍹" : "󰌢";
            const label = monitorLabel(screen);
            const mode = screen.display && screen.display.mode ? screen.display.mode : "";
            const scale = screen.display && screen.display.scale ? "scale " + screen.display.scale : "";
            const details = [mode, scale].filter(value => value).join(", ");

            return details.length > 0 ? icon + "  " + label + " - " + details : icon + "  " + label;
        });
    }

    function monitorLabel(screen) {
        if (screen.display_name)
            return screen.display_name;

        if (screen.display && screen.display.label)
            return screen.display.label;

        if (screen.display && screen.display.match)
            return screen.display.match;

        return "Unknown display";
    }

    function valueOrUnknown(value) {
        const text = String(value || "");
        return text.length > 0 ? text : "Unknown";
    }

    function reportError() {
        (log || fallbackLog).error(messageText(arguments));
    }

    function messageText(messages) {
        const parts = [];

        for (let index = 0; index < messages.length; index++)
            parts.push(String(messages[index]));

        return parts.join(" ");
    }

    Component.onCompleted: refresh()
}
