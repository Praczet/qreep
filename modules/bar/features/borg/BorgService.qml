import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../core" as Core

QtObject {
    id: rootBorgService

    property QtObject log
    property var command: ["borg-pulse", "--qreep"]
    property var backupCommand: ["borg-backup-notify"]
    property string backupStatusBackend: "qreep"
    property string backupStatePath: ""
    property string backupFinalPath: ""
    property string quickshellTarget: "--path " + Quickshell.shellDir
    property int refreshInterval: 3600000
    property int backupPanelHideDelay: 2000
    property int backupStatePollInterval: 1000
    property string text: " ?"
    property string className: "warning"
    property string status: "Borg status unknown"
    property var tooltip: ({ rows: [] })
    property string lastError
    property bool pendingRefresh: false
    property bool backupStateInitialized: false
    property bool backupPanelOpen: false
    property bool backupWasRunning: false
    property string backupState: "idle"
    property string backupProfile: ""
    property string backupArchive: ""
    property string backupMessage: ""
    property string backupStartedAt: ""
    property string backupUpdatedAt: ""
    property string backupFinishedAt: ""
    property string backupCurrentPath: ""
    property string backupLastFileStatus: ""
    property string backupLastFilePath: ""
    property int backupFiles: 0
    property int backupRc: -1
    property double backupOriginalSize: 0
    property double backupCompressedSize: 0
    property double backupDeduplicatedSize: 0
    property string handledBackupTerminalKey: ""

    signal pulseRequested
    signal shakeRequested

    readonly property Core.Log fallbackLog: Core.Log {}

    readonly property Process backupRunner: Process {}

    readonly property Timer backupPanelHideTimer: Timer {
        interval: rootBorgService.backupPanelHideDelay
        repeat: false
        onTriggered: rootBorgService.backupPanelOpen = false
    }

    readonly property Timer backupStatePollTimer: Timer {
        interval: rootBorgService.backupStatePollInterval
        repeat: true
        running: rootBorgService.backupStatePath.length > 0
        onTriggered: rootBorgService.requestBackupState()
    }

    readonly property Process backupStateReader: Process {
        id: backupStateReader

        stdout: StdioCollector {
            id: backupStateStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: backupStateStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootBorgService.applyBackupStateOutput(backupStateStdout.text, backupStateStderr.text, exitCode)
    }

    readonly property Process backupFinalReader: Process {
        id: backupFinalReader

        stdout: StdioCollector {
            id: backupFinalStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: backupFinalStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootBorgService.applyBackupFinalOutput(backupFinalStdout.text, exitCode)
    }

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

        function showProgress() {
            rootBorgService.showProgress();
        }

        function hideProgress() {
            rootBorgService.hideProgress();
        }

        function toggleProgress() {
            rootBorgService.toggleProgress();
        }
    }

    function refreshWithPulse() {
        pulseRequested();

        if (backupIsRunning()) {
            showProgress();
            applyBackupRunningStatus("");
            return;
        }

        refresh();
    }

    function refresh() {
        if (backupIsRunning()) {
            requestBackupState();
            applyBackupRunningStatus("");
            return;
        }

        if (statusRunner.running) {
            pendingRefresh = true;
            return;
        }

        statusRunner.running = false;
        statusRunner.command = command;
        statusRunner.running = true;
    }

    function showProgress() {
        backupPanelHideTimer.stop();
        requestBackupState();
        backupPanelOpen = true;
    }

    function hideProgress() {
        backupPanelHideTimer.stop();
        backupPanelOpen = false;
    }

    function toggleProgress() {
        if (backupPanelOpen)
            hideProgress();
        else
            showProgress();
    }

    function runBackup() {
        info("Borg backup requested");
        backupPanelHideTimer.stop();
        handledBackupTerminalKey = "";
        backupState = "running";
        backupMessage = "Starting Borg backup";
        backupCurrentPath = "";
        backupLastFilePath = "";
        backupRc = -1;
        backupPanelOpen = true;

        backupRunner.running = false;
        backupRunner.command = backupCommand;
        backupRunner.environment = ({
            BORG_STATUS_BACKEND: backupStatusBackend,
            QREEP_QUICKSHELL_TARGET: quickshellTarget
        });
        backupRunner.startDetached();
    }

    function requestBackupState() {
        if (backupStatePath.length === 0 || backupStateReader.running)
            return;

        backupStateReader.command = ["cat", backupStatePath];
        backupStateReader.running = true;
    }

    function applyBackupStateOutput(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0) {
            if (backupStateInitialized)
                warn("Borg state load failed:", String(stderrText || "").trim());

            backupStateInitialized = true;
            return;
        }

        const contents = String(stdoutText || "").trim();

        if (contents.length === 0)
            return;

        try {
            applyBackupState(JSON.parse(contents));
        } catch (error) {
            warn("Could not parse Borg state JSON:", error);
        }
    }

    function applyBackupState(payload) {
        const wasInitialized = backupStateInitialized;
        const previousState = backupState;
        const previousArchive = backupArchive;
        const nextState = String(payload.state || "idle");
        const nextArchive = String(payload.archive || "");
        const archiveChanged = previousArchive.length > 0 && nextArchive.length > 0 && previousArchive !== nextArchive;

        if (isTerminalBackupState(nextState)) {
            const nextFinishedAt = String(payload.finishedAt || "");
            const nextRc = numberValue(payload.rc, -1);
            const terminalKey = backupTerminalKey(nextState, nextArchive, nextFinishedAt, nextRc);

            if (terminalKey === handledBackupTerminalKey)
                return;

            handledBackupTerminalKey = terminalKey;

            if (!backupWasRunning && previousState !== "running") {
                backupStateInitialized = true;
                return;
            }
        }

        backupStateInitialized = true;
        backupState = nextState;
        backupProfile = String(payload.profile || payload.target || "");
        backupArchive = nextArchive;
        backupMessage = String(payload.message || "");
        backupStartedAt = String(payload.startedAt || "");
        backupUpdatedAt = String(payload.updatedAt || "");
        backupFinishedAt = String(payload.finishedAt || "");
        backupCurrentPath = String(payload.currentPath || "");
        backupLastFileStatus = String(payload.lastFileStatus || "");
        backupLastFilePath = String(payload.lastFilePath || "");
        backupFiles = numberValue(payload.files, numberValue(payload.stats && payload.stats.archive && payload.stats.archive.stats && payload.stats.archive.stats.nfiles, 0));
        backupRc = numberValue(payload.rc, -1);
        backupOriginalSize = numberValue(payload.originalSize, numberValue(payload.stats && payload.stats.archive && payload.stats.archive.stats && payload.stats.archive.stats.original_size, 0));
        backupCompressedSize = numberValue(payload.compressedSize, numberValue(payload.stats && payload.stats.archive && payload.stats.archive.stats && payload.stats.archive.stats.compressed_size, 0));
        backupDeduplicatedSize = numberValue(payload.deduplicatedSize, numberValue(payload.stats && payload.stats.archive && payload.stats.archive.stats && payload.stats.archive.stats.deduplicated_size, 0));

        if (nextState === "running") {
            backupPanelHideTimer.stop();
            backupPanelOpen = true;
            handledBackupTerminalKey = "";
            applyBackupRunningStatus("");
            requestBackupFinal();

            if (!wasInitialized || previousState !== "running" || archiveChanged)
                pulseRequested();

            backupWasRunning = true;
            return;
        }

        if (isTerminalBackupState(nextState)) {
            backupPanelOpen = true;
            backupWasRunning = false;
            shakeRequested();
            refresh();
            backupPanelHideTimer.restart();
        }
    }

    function requestBackupFinal() {
        if (backupFinalPath.length === 0 || backupFinalReader.running)
            return;

        backupFinalReader.command = ["cat", backupFinalPath];
        backupFinalReader.running = true;
    }

    function applyBackupFinalOutput(stdoutText, exitCode) {
        if (exitCode !== 0)
            return;

        const contents = String(stdoutText || "").trim();

        if (contents.length === 0)
            return;

        try {
            const payload = JSON.parse(contents);
            const archiveName = String(payload.archive && payload.archive.name || "");

            if (backupState !== "running" || archiveName.length === 0 || archiveName !== backupArchive)
                return;

            applyBackupState({
                state: "success",
                archive: archiveName,
                profile: backupProfile,
                finishedAt: String(payload.archive && payload.archive.end || ""),
                rc: 0,
                stats: payload
            });
        } catch (error) {
            // final.json may be mid-write while Borg is still running. Ignore and retry on the next poll.
        }
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
        if (backupIsRunning()) {
            applyBackupRunningStatus(message);
            return;
        }

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

    function applyBackupRunningStatus(message) {
        text = "";
        className = "warning";
        status = "Borg backup running";
        tooltip = ({
            rows: [
                { text: "", size: 36, align: "right", bold: true, color: "{{warning}}" },
                { text: "BORG BACKUP", align: "center", size: 13, bold: true, color: "{{on_surface}}" },
                { text: "Backup running. Latest-archive checks can wait their turn.", size: 11, align: "center", color: "{{warning}}" },
                { blank: true },
                { columns: [{ text: "Profile:", color: "{{primary}}" }, { text: backupProfile.length > 0 ? backupProfile : "unknown", color: "{{on_surface}}" }] },
                { columns: [{ text: "Archive:", color: "{{primary}}" }, { text: backupArchive.length > 0 ? backupArchive : "pending", color: "{{on_surface}}" }] },
                { columns: [{ text: "Message:", color: "{{primary}}" }, { text: backupMessage.length > 0 ? backupMessage : message, color: "{{on_surface_variant}}" }] }
            ]
        });
        lastError = "";
    }

    function info() {
        (log || fallbackLog).info.apply(log || fallbackLog, arguments);
    }

    function warn() {
        (log || fallbackLog).warn.apply(log || fallbackLog, arguments);
    }

    function isTerminalBackupState(state) {
        return state === "success" || state === "error" || state === "failed";
    }

    function backupIsRunning() {
        return backupState === "running";
    }

    function backupTerminalKey(state, archive, finishedAt, rc) {
        return state + "|" + archive + "|" + finishedAt + "|" + rc;
    }

    function numberValue(value, fallback) {
        const numeric = Number(value);
        return Number.isFinite(numeric) ? numeric : fallback;
    }

    Component.onCompleted: {
        requestBackupState();
        refresh();
    }
}
