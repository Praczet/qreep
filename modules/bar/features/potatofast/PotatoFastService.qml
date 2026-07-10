import QtQuick
import Quickshell.Io
import "../../../../core" as Core

QtObject {
    id: rootPotatoFastService

    property QtObject log
    property string statusCommand: "potato-fast"
    property int refreshInterval: 60000
    property string state: "unknown"
    property string className: "no-data"
    property string timeText: ""
    property string remainingText: ""
    property string message: ""
    property string tooltipContent: "Potato fast status unknown"
    property real hours: 0
    property real goalHours: 0
    property int percentage: 0
    property bool success: false
    property bool pendingRefresh: false

    signal pulseRequested

    readonly property Core.Log fallbackLog: Core.Log {}

    readonly property Process statusRunner: Process {
        id: statusRunner

        stdout: StdioCollector {
            id: stdoutCollector

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: stderrCollector

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            rootPotatoFastService.applyOutput(stdoutCollector.text, stderrCollector.text, exitCode);

            if (rootPotatoFastService.pendingRefresh) {
                rootPotatoFastService.pendingRefresh = false;
                rootPotatoFastService.refresh();
            }
        }
    }

    readonly property Timer refreshTimer: Timer {
        interval: rootPotatoFastService.refreshInterval
        repeat: true
        running: true
        onTriggered: rootPotatoFastService.refresh()
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-potato-fast"

        function refresh() {
            rootPotatoFastService.refreshWithPulse();
        }
    }

    function refreshWithPulse() {
        pulseRequested();
        refresh();
    }

    function refresh() {
        if (statusRunner.running) {
            pendingRefresh = true;
            return;
        }

        statusRunner.running = false;
        statusRunner.command = [statusCommand, "--json"];
        statusRunner.running = true;
    }

    function applyOutput(stdoutText, stderrText, exitCode) {
        const output = String(stdoutText || "").trim();

        if (exitCode !== 0) {
            applyError(statusCommand + " failed: " + failureText(stderrText, exitCode));
            return;
        }

        if (output.length === 0) {
            applyError(statusCommand + " returned no JSON. Very minimalist. Not useful.");
            return;
        }

        try {
            applyPayload(JSON.parse(output));
        } catch (error) {
            applyError("Could not parse " + statusCommand + " JSON: " + error);
        }
    }

    function applyPayload(payload) {
        if (!payload || typeof payload !== "object") {
            applyError(statusCommand + " returned a non-object payload.");
            return;
        }

        success = boolValue(payload.success, true);
        state = stringValue(payload.state, stringValue(payload.alt, "unknown"));
        className = stringValue(payload.class, state.length > 0 ? state : "unknown");
        percentage = boundedPercent(payload.percentage);
        hours = numberValue(payload.time, 0);
        goalHours = numberValue(payload.goal, 0);
        timeText = stringValue(payload.timeStr, "");
        remainingText = stringValue(payload.remainingStr, "");
        message = stringValue(payload.message, "");
        tooltipContent = stringValue(payload.tooltip, fallbackTooltip());
    }

    function applyError(text) {
        success = false;
        state = "error";
        className = "error";
        percentage = 0;
        hours = 0;
        goalHours = 0;
        timeText = "";
        remainingText = "";
        message = text;
        tooltipContent = text;
        warn(text);
    }

    function fallbackTooltip() {
        const lines = [];

        if (message.length > 0)
            lines.push(message);

        if (timeText.length > 0)
            lines.push("Elapsed: " + timeText);

        if (remainingText.length > 0)
            lines.push("Remaining: " + remainingText);

        if (goalHours > 0)
            lines.push("Goal: " + goalHours + "h");

        return lines.length > 0 ? lines.join("\n") : "Potato fast status unknown";
    }

    function boundedPercent(value) {
        const parsed = numberValue(value, 0);
        return Math.max(0, Math.min(100, Math.round(parsed)));
    }

    function stringValue(value, fallback) {
        return typeof value === "string" ? value : fallback;
    }

    function numberValue(value, fallback) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function boolValue(value, fallback) {
        return typeof value === "boolean" ? value : fallback;
    }

    function failureText(stderrText, exitCode) {
        const detail = String(stderrText || "").trim();
        return detail.length > 0 ? detail : "exit " + exitCode;
    }

    function warn() {
        (log || fallbackLog).warn(messageText(arguments));
    }

    function messageText(messages) {
        const parts = [];

        for (let index = 0; index < messages.length; index++)
            parts.push(String(messages[index]));

        return parts.join(" ");
    }

    Component.onCompleted: refresh()
}
