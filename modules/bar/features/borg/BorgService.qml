import QtQuick
import Quickshell
import Quickshell.Io
import "../../core" as Core

QtObject {
    id: rootBorgService

    property QtObject log
    property var command: ["borg-pulse", "--qreep"]
    property var backupCommand: ["borg-backup-notify"]
    property string backupStatusBackend: "qreep"
    property string quickshellTarget: "--path " + Quickshell.shellDir
    property int refreshInterval: 3600000
    property string text: " ?"
    property string className: "warning"
    property string status: "Borg status unknown"
    property var tooltip: ({ rows: [] })
    property string lastError
    property bool pendingRefresh: false

    signal pulseRequested

    readonly property Core.Log fallbackLog: Core.Log {}

    readonly property Process backupRunner: Process {}

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
            rootBorgService.applyOutput(stdoutCollector.text, stderrCollector.text, exitCode);

            if (rootBorgService.pendingRefresh) {
                rootBorgService.pendingRefresh = false;
                rootBorgService.refresh();
            }
        }
    }

    readonly property Timer refreshTimer: Timer {
        interval: rootBorgService.refreshInterval
        repeat: true
        running: true
        onTriggered: rootBorgService.refresh()
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-borg"

        function refresh() {
            rootBorgService.refreshWithPulse();
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
        statusRunner.command = command;
        statusRunner.running = true;
    }

    function runBackup() {
        info("Borg backup requested");

        backupRunner.running = false;
        backupRunner.command = backupCommand;
        backupRunner.environment = ({
            BORG_STATUS_BACKEND: backupStatusBackend,
            QREEP_QUICKSHELL_TARGET: quickshellTarget
        });
        backupRunner.startDetached();
    }

    function applyOutput(stdoutText, stderrText, exitCode) {
        const output = String(stdoutText || "").trim();

        if (output.length === 0) {
            const errorText = String(stderrText || "").trim();
            applyFailure(errorText.length > 0 ? errorText : "borg-pulse exited without output. Exit code: " + exitCode);
            return;
        }

        try {
            applyPayload(JSON.parse(output));
        } catch (error) {
            applyFailure("Could not parse borg-pulse JSON: " + error);
        }
    }

    function applyPayload(payload) {
        text = String(payload.text || " ?");
        className = String(payload.class || "warning");
        status = String(payload.status || "Borg status unknown");
        tooltip = payload.tooltip || ({ rows: [] });
        lastError = "";

        info("Borg status refreshed:", className, status);
    }

    function applyFailure(message) {
        text = " !";
        className = "error";
        status = message;
        tooltip = ({
            rows: [
                { text: "WE ARE THE BORG", align: "center", bold: true },
                { text: message, align: "center", color: "{{error}}" }
            ]
        });
        lastError = message;

        warn(message);
    }

    function info() {
        (log || fallbackLog).info.apply(log || fallbackLog, arguments);
    }

    function warn() {
        (log || fallbackLog).warn.apply(log || fallbackLog, arguments);
    }

    Component.onCompleted: refresh()
}
