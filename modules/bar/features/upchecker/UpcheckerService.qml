import QtQuick
import Quickshell.Io
import "../../../../core" as Core

QtObject {
    id: rootUpcheckerService

    property QtObject log
    property string updateTerminalCommand: "ghostty"
    property string updateCommand: "update-btw"
    property string restartCheckCommand: "restart-check"
    property string restartCheckTimezone: "Europe/Luxembourg"
    property string restartSessionPackages: "xorg-server,xorg-xwayland,hyprland,waybar,xdg-desktop-portal-hyprland"
    property string restartRebootPackages: "systemd,linux-firmware,intel-ucode"
    property var updates: []
    property int selectedIndex: -1
    property var selectedItem: selectedIndex >= 0 && selectedIndex < updates.length ? updates[selectedIndex] : null
    property var details: ({})
    property string detailsView: "empty"
    property string error: ""
    property bool restartNeeded: false
    property string restartAction: "nothing"
    property string restartSummary: ""
    property string restartDetails: ""
    property string restartSeverity: "ok"
    property string restartIcon: "emblem-ok-symbolic"
    property var restartReport: ({})
    property bool loadingRestartState: false
    property bool loadingUpdates: false
    property bool loadingDetails: false
    property bool pendingRefresh: false
    property string detailsRequestName: ""
    property var detailsCache: ({})

    signal pulseRequested
    signal toggleRequested
    signal updateRequested

    readonly property Core.Log fallbackLog: Core.Log {}

    readonly property Process updateRunner: Process {}

    readonly property Process restartRunner: Process {
        id: restartRunner

        stdout: StdioCollector {
            id: restartStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: restartStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootUpcheckerService.applyRestartOutput(restartStdout.text, restartStderr.text, exitCode)
    }

    readonly property Process updatesRunner: Process {
        id: updatesRunner

        stdout: StdioCollector {
            id: updatesStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: updatesStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            rootUpcheckerService.applyUpdatesOutput(updatesStdout.text, updatesStderr.text, exitCode);

            if (rootUpcheckerService.pendingRefresh) {
                rootUpcheckerService.pendingRefresh = false;
                rootUpcheckerService.refresh();
            }
        }
    }

    readonly property Process detailsRunner: Process {
        id: detailsRunner

        stdout: StdioCollector {
            id: detailsStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: detailsStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootUpcheckerService.applyDetailsOutput(detailsStdout.text, detailsStderr.text, exitCode)
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-upchecker"

        function refresh() {
            rootUpcheckerService.refreshWithPulse();
        }

        function toggle() {
            rootUpcheckerService.toggleRequested();
        }

        function update() {
            rootUpcheckerService.update();
        }
    }

    function refresh() {
        if (updatesRunner.running) {
            pendingRefresh = true;
            return;
        }

        loadingUpdates = true;
        checkRestartState();
        error = "";
        detailsView = "loading";
        updatesRunner.running = false;
        updatesRunner.command = ["checkupdates", "--nocolor"];
        updatesRunner.running = true;
    }

    function refreshWithPulse() {
        pulseRequested();
        refresh();
    }

    function checkRestartState() {
        if (restartRunner.running)
            return;

        loadingRestartState = true;
        restartRunner.running = false;
        restartRunner.command = [restartCheckCommand, "--timezone", restartCheckTimezone, "--restart-packages", restartSessionPackages, "--reboot-packages", restartRebootPackages];
        restartRunner.running = true;
    }

    function selectIndex(index) {
        if (index < 0 || index >= updates.length)
            return;

        selectedIndex = index;
        error = "";

        const item = updates[index];
        const cachedDetails = detailsCache[item.name];

        if (cachedDetails !== undefined) {
            details = cachedDetails;
            detailsView = "details";
            loadingDetails = false;
            return;
        }

        loadingDetails = true;
        detailsRequestName = item.name;
        details = ({});
        detailsView = "loading";
        detailsRunner.running = false;
        detailsRunner.command = ["pacquery", item.name];
        detailsRunner.running = true;
    }

    function update() {
        updateRequested();
        openUpdaterTerminal();
    }

    function openUpdaterTerminal() {
        updateRunner.running = false;
        updateRunner.command = [updateTerminalCommand, "-e", updateCommand];
        updateRunner.startDetached();
    }

    function applyUpdatesOutput(stdoutText, stderrText, exitCode) {
        loadingUpdates = false;

        if (exitCode === 2 || String(stderrText || "").match(/there are no updates available/i)) {
            updates = [];
            selectedIndex = -1;
            details = ({});
            detailsView = "nodata";
            info("No package updates available");
            return;
        }

        if (exitCode !== 0) {
            updates = [];
            selectedIndex = -1;
            applyError("checkupdates failed: " + failureText(stderrText, exitCode));
            return;
        }

        updates = parseUpdates(stdoutText);
        selectedIndex = -1;
        details = ({});
        detailsView = updates.length > 0 ? "empty" : "nodata";
        info("Package updates refreshed:", updates.length);
    }

    function applyRestartOutput(stdoutText, stderrText, exitCode) {
        loadingRestartState = false;

        const output = String(stdoutText || "").trim();
        const stderrOutput = String(stderrText || "").trim();

        if (output.length === 0) {
            applyRestartFailure(restartCheckCommand + " exited without output" + (stderrOutput.length > 0 ? ": " + stderrOutput : ""));
            return;
        }

        try {
            applyRestartReport(JSON.parse(output), stderrOutput);
        } catch (parseError) {
            applyRestartFailure("Could not parse " + restartCheckCommand + " JSON: " + parseError);
        }
    }

    function applyRestartReport(report, stderrOutput) {
        restartReport = report || ({});
        restartAction = String(restartReport.actionNeeded || "unknown");
        restartNeeded = restartAction === "reboot" || restartAction === "restart";
        restartSeverity = String(restartReport.severity || (restartAction === "unknown" ? "error" : "ok"));
        restartIcon = String(restartReport.icon || restartActionIcon(restartAction));
        restartSummary = restartNeeded ? displayText(restartReport.summary, restartActionLabel(restartAction)) : "";
        restartDetails = restartNeeded ? displayText(restartReport.detail, restartDetailText(restartReport)) : "";

        if (restartAction === "unknown")
            warn(restartCheckCommand + " returned unknown state:", restartReport.error || "no error field");

        if (stderrOutput.length > 0)
            warn(restartCheckCommand + " stderr:", stderrOutput);
    }

    function applyRestartFailure(message) {
        restartReport = ({
                actionNeeded: "unknown",
                error: message
            });
        restartAction = "unknown";
        restartNeeded = false;
        restartSummary = "Restart state unknown";
        restartDetails = message;
        restartSeverity = "error";
        restartIcon = "dialog-warning-symbolic";
        warn(message);
    }

    function restartActionLabel(action) {
        switch (action) {
        case "reboot":
            return "Reboot needed";
        case "restart":
            return "Session restart needed";
        default:
            return "Restart state unknown";
        }
    }

    function restartActionIcon(action) {
        switch (action) {
        case "reboot":
            return "system-reboot-symbolic";
        case "restart":
            return "system-log-out-symbolic";
        case "nothing":
            return "emblem-ok-symbolic";
        default:
            return "dialog-warning-symbolic";
        }
    }

    function displayText(value, fallback) {
        const text = String(value || "").trim();
        return text.length > 0 ? text : fallback;
    }

    function restartDetailText(report) {
        if (report.kernel && report.kernel.changed) {
            return "Kernel: installed " + (report.kernel.installed || "unknown") + ", running " + (report.kernel.running || "unknown");
        }

        if (Array.isArray(report.packages) && report.packages.length > 0) {
            const firstPackage = report.packages[0];
            const suffix = report.packages.length > 1 ? " +" + (report.packages.length - 1) + " more" : "";
            return firstPackage.name + " updated " + (firstPackage.updated || "recently") + suffix;
        }

        if (Array.isArray(report.warnings) && report.warnings.length > 0)
            return report.warnings[0];

        return "Restart is needed after recent updates.";
    }

    function applyDetailsOutput(stdoutText, stderrText, exitCode) {
        loadingDetails = false;

        if (exitCode !== 0) {
            applyError("pacquery failed: " + failureText(stderrText, exitCode));
            return;
        }

        try {
            const parsedDetails = parsePacquery(stdoutText);
            const requestName = detailsRequestName;
            const item = selectedItem;

            if (requestName.length > 0) {
                const nextCache = Object.assign({}, detailsCache);
                nextCache[requestName] = parsedDetails;
                detailsCache = nextCache;
            }

            if (item === null || item === undefined || item.name !== requestName)
                return;

            details = parsedDetails;
            detailsView = "details";
        } catch (parseError) {
            applyError("Could not parse pacquery JSON: " + parseError);
        }
    }

    function parseUpdates(stdoutText) {
        const parsedUpdates = [];
        const lines = String(stdoutText || "").split("\n");

        for (let index = 0; index < lines.length; index++) {
            const line = lines[index].trim();

            if (line.length === 0)
                continue;

            const match = line.match(/^(\S+)\s+(\S+)\s+->\s+(\S+)$/);

            if (match === null) {
                warn("Ignoring unrecognized checkupdates line:", line);
                continue;
            }

            parsedUpdates.push({
                name: match[1],
                oldVer: match[2],
                newVer: match[3]
            });
        }

        return parsedUpdates;
    }

    function parsePacquery(stdoutText) {
        const payload = JSON.parse(String(stdoutText || ""));
        const packageInfo = Array.isArray(payload) ? payload[0] : payload;

        return {
            name: String(packageInfo.name || ""),
            repo: packageInfo.repository || "",
            version: packageInfo.version || "",
            desc: packageInfo.description || "",
            url: packageInfo.url || "",
            arch: packageInfo.architecture || "",
            depends: Array.isArray(packageInfo.depends) ? packageInfo.depends : [],
            optdepends: Array.isArray(packageInfo.optdepends) ? packageInfo.optdepends : [],
            requiredby: Array.isArray(packageInfo.required_by) ? packageInfo.required_by : []
        };
    }

    function applyError(message) {
        error = message;
        detailsView = "error";
        warn(message);
    }

    function failureText(stderrText, exitCode) {
        const text = String(stderrText || "").trim();
        return text.length > 0 ? text : "exit code " + exitCode;
    }

    function info() {
        (log || fallbackLog).info.apply(log || fallbackLog, arguments);
    }

    function warn() {
        (log || fallbackLog).warn.apply(log || fallbackLog, arguments);
    }

    Component.onCompleted: refresh()
}
