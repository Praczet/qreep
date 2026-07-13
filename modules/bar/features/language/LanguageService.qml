import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "../../../../core" as Core

QtObject {
    id: rootLanguageService

    property QtObject log
    property int refreshInterval: 5000
    property string keyboardName: ""
    property string activeKeymap: "Unknown"
    property string layoutName: ""
    property bool available: false
    property bool pendingRefresh: false
    property string lastError: ""

    readonly property Core.Log fallbackLog: Core.Log {}
    readonly property string displayText: available ? keymapCode(activeKeymap) : "--"
    readonly property string tooltipTitle: "Keyboard Layout"
    readonly property string tooltipContent: tooltipLines().join("\n")

    signal pulseRequested

    readonly property Process devicesRunner: Process {
        id: devicesRunner

        stdout: StdioCollector {
            id: devicesStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: devicesStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            rootLanguageService.applyDevicesOutput(devicesStdout.text, devicesStderr.text, exitCode);

            if (rootLanguageService.pendingRefresh) {
                rootLanguageService.pendingRefresh = false;
                rootLanguageService.refresh();
            }
        }
    }

    readonly property Process switchRunner: Process {
        id: switchRunner

        stderr: StdioCollector {
            id: switchStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootLanguageService.applySwitchOutput(switchStderr.text, exitCode)
    }

    readonly property Timer refreshTimer: Timer {
        interval: rootLanguageService.refreshInterval
        repeat: true
        running: true
        onTriggered: rootLanguageService.refresh()
    }

    readonly property Timer eventRefreshTimer: Timer {
        interval: 60
        repeat: false
        onTriggered: rootLanguageService.refresh()
    }

    readonly property Connections hyprlandEvents: Connections {
        target: Hyprland

        function onRawEvent(event) {
            rootLanguageService.handleHyprlandEvent(event);
        }
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-language"

        function refresh(): string {
            rootLanguageService.refreshWithPulse();
            return rootLanguageService.stateText();
        }

        function next(): string {
            rootLanguageService.switchToNext();
            return rootLanguageService.stateText();
        }

        function state(): string {
            return rootLanguageService.stateText();
        }
    }

    function refreshWithPulse() {
        pulseRequested();
        refresh();
    }

    function refresh() {
        if (devicesRunner.running) {
            pendingRefresh = true;
            return;
        }

        devicesRunner.running = false;
        devicesRunner.command = ["hyprctl", "devices", "-j"];
        devicesRunner.running = true;
    }

    function switchToNext() {
        if (switchRunner.running)
            return;

        pulseRequested();
        switchRunner.running = false;
        switchRunner.command = ["hyprctl", "switchxkblayout", "all", "next"];
        switchRunner.running = true;
    }

    function applySwitchOutput(stderrText, exitCode) {
        if (exitCode !== 0) {
            applyError("Could not switch keyboard layout: " + failureText(stderrText, exitCode));
            return;
        }

        eventRefreshTimer.restart();
    }

    function handleHyprlandEvent(event) {
        if (!event || String(event.name || "") !== "activelayout")
            return;

        const parts = String(event.data || "").split(",");

        if (parts.length >= 2) {
            keyboardName = parts[0].trim();
            activeKeymap = parts.slice(1).join(",").trim() || "Unknown";
            available = true;
            lastError = "";
        }

        eventRefreshTimer.restart();
    }

    function applyDevicesOutput(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0) {
            applyError("Could not read Hyprland keyboards: " + failureText(stderrText, exitCode));
            return;
        }

        try {
            applyDevicesPayload(JSON.parse(String(stdoutText || "{}")));
        } catch (error) {
            applyError("Could not parse Hyprland keyboard JSON: " + error);
        }
    }

    function applyDevicesPayload(payload) {
        const keyboards = payload && Array.isArray(payload.keyboards) ? payload.keyboards : [];
        const keyboard = selectedKeyboard(keyboards);

        if (!keyboard) {
            available = false;
            keyboardName = "";
            activeKeymap = "Unknown";
            layoutName = "";
            lastError = "No Hyprland keyboard found";
            return;
        }

        available = true;
        keyboardName = stringValue(keyboard.name, "Unknown keyboard");
        activeKeymap = stringValue(keyboard.active_keymap, "Unknown");
        layoutName = stringValue(keyboard.layout, "");
        lastError = "";
    }

    function selectedKeyboard(keyboards) {
        for (let index = 0; index < keyboards.length; index++) {
            const keyboard = keyboards[index];

            if (keyboard && keyboard.main)
                return keyboard;
        }

        for (let index = 0; index < keyboards.length; index++) {
            const keyboard = keyboards[index];

            if (keyboard && keyboard.active_keymap)
                return keyboard;
        }

        return keyboards.length > 0 ? keyboards[0] : null;
    }

    function keymapCode(value) {
        const text = String(value || "").trim();
        const lower = text.toLowerCase();
        const parenthesized = text.match(/\(([a-zA-Z]{2,3})\)/);

        if (parenthesized)
            return parenthesized[1].toUpperCase();

        if (lower.indexOf("polish") >= 0 || lower === "pl")
            return "PL";

        if (lower.indexOf("english") >= 0 || lower.indexOf("us") >= 0)
            return "US";

        if (lower.indexOf("german") >= 0 || lower === "de")
            return "DE";

        if (lower.indexOf("french") >= 0 || lower === "fr")
            return "FR";

        if (lower.length === 0 || lower === "unknown")
            return "--";

        if (lower.length >= 2)
            return lower.slice(0, 2).toUpperCase();

        return "--";
    }

    function tooltipLines() {
        if (!available) {
            return [
                "Keyboard layout unavailable",
                lastError.length > 0 ? lastError : "Hyprland has not reported a keyboard yet"
            ];
        }

        const lines = [
            "Active: " + activeKeymap,
            "Keyboard: " + keyboardName,
            "Click: switch to next layout"
        ];

        if (layoutName.length > 0)
            lines.splice(1, 0, "Configured: " + layoutName);

        return lines;
    }

    function stateText() {
        return "language available=" + available + " keymap=" + activeKeymap + " label=" + displayText;
    }

    function applyError(text) {
        available = false;
        lastError = text;
        warn(text);
    }

    function failureText(stderrText, exitCode) {
        const text = String(stderrText || "").trim();

        return text.length > 0 ? text : "exit " + exitCode;
    }

    function stringValue(value, fallback) {
        const text = String(value || "").trim();

        return text.length > 0 ? text : fallback;
    }

    function warn() {
        (log || fallbackLog).warn.apply(log || fallbackLog, arguments);
    }

    Component.onCompleted: refresh()
}
