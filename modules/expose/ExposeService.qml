import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../core" as Core

QtObject {
    id: rootExposeService

    property QtObject theme
    property QtObject log
    property var clients: []
    property var activeWorkspace: ({ id: 0, name: "" })
    property var currentClients: []
    property var workspaceClusters: []
    property var thumbnailByAddress: ({})
    property var captureQueue: []
    property var captureCurrent: null
    property string selectedAddress: ""
    property string error: ""
    property bool waitingForOpen: false
    property bool clientsLoaded: false
    property bool activeLoaded: false
    readonly property string thumbnailDir: Quickshell.env("HOME") + "/.cache/qreep/expose"

    signal focusCompleted
    signal openReady

    readonly property Core.Log fallbackLog: Core.Log {}

    readonly property Process clientsRunner: Process {
        id: clientsRunner

        stdout: StdioCollector {
            id: clientsStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: clientsStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootExposeService.applyClientsOutput(clientsStdout.text, clientsStderr.text, exitCode)
    }

    readonly property Process activeRunner: Process {
        id: activeRunner

        stdout: StdioCollector {
            id: activeStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: activeStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootExposeService.applyActiveOutput(activeStdout.text, activeStderr.text, exitCode)
    }

    readonly property Process focusRunner: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                warn("Expose focus dispatch failed");

            rootExposeService.focusCompleted();
        }
    }

    readonly property Process captureRunner: Process {
        onExited: (exitCode, exitStatus) => rootExposeService.applyCaptureBatchOutput(exitCode)
    }

    function refresh() {
        error = "";
        clientsLoaded = false;
        activeLoaded = false;
        Hyprland.refreshToplevels();
        runJsonCommand(activeRunner, ["hyprctl", "activeworkspace", "-j"]);
        runJsonCommand(clientsRunner, ["hyprctl", "clients", "-j"]);
    }

    function refreshForOpen() {
        waitingForOpen = true;
        refresh();
    }

    function focusSelected() {
        focusClientByAddress(selectedAddress);
    }

    function focusClient(client) {
        if (!client)
            return;

        focusClientByAddress(String(client.address || ""));
    }

    function focusClientByAddress(address) {
        const value = String(address || "");

        if (value.length === 0)
            return;

        if (Hyprland.usingLua)
            focusRunner.command = ["hyprctl", "dispatch", "hl.dsp.focus({ window = \"" + value.replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\" })"];
        else
            focusRunner.command = ["hyprctl", "dispatch", "focuswindow", "address:" + value];

        focusRunner.running = true;
    }

    function selectAddress(address) {
        selectedAddress = String(address || "");
    }

    function appIconName(client) {
        const label = appLabel(client).toLowerCase();

        if (label === "ghostty")
            return "com.mitchellh.ghostty";

        if (label === "whatsapp web")
            return "whatsapp-symbolic";

        if (label === "zen" || label === "zen browser")
            return "app.zen_browser.zen";

        return label;
    }

    function appLabel(client) {
        const title = String(client && client.title || "").trim();
        const text = String(client && (client.class || client.initialClass) || "Unknown").trim();
        const chromeMatch = text.match(/^chrome-[^-]+-(.+)$/);

        if (title.length > 0 && chromeMatch)
            return title;

        if (text === "com.mitchellh.ghostty")
            return "ghostty";

        return text.length > 0 ? text : "Unknown";
    }

    function workspaceTitle(workspaceId, workspaceName) {
        const name = String(workspaceName || workspaceId || "");

        if (name.indexOf("special:") === 0)
            return "Magic Workspace";

        return "Workspace: " + name;
    }

    function runJsonCommand(runner, command) {
        if (runner.running)
            return;

        runner.command = command;
        runner.running = true;
    }

    function applyClientsOutput(stdoutText, stderrText, exitCode) {
        clientsLoaded = true;

        if (exitCode !== 0) {
            applyFailure("Could not read Hyprland clients: " + String(stderrText || "").trim());
            maybePrepareOpen();
            return;
        }

        clients = parseJsonArray(stdoutText, []).filter(client => client && client.address && client.mapped !== false && client.hidden !== true);
        rebuildModel();
        maybePrepareOpen();
    }

    function applyActiveOutput(stdoutText, stderrText, exitCode) {
        activeLoaded = true;

        if (exitCode !== 0) {
            applyFailure("Could not read active Hyprland workspace: " + String(stderrText || "").trim());
            maybePrepareOpen();
            return;
        }

        activeWorkspace = parseJsonObject(stdoutText, ({ id: 0, name: "" }));
        rebuildModel();
        maybePrepareOpen();
    }

    function maybePrepareOpen() {
        if (!waitingForOpen || !clientsLoaded || !activeLoaded)
            return;

        startThumbnailCapture();
    }

    function startThumbnailCapture() {
        if (captureRunner.running)
            captureRunner.running = false;

        captureQueue = currentClients.filter(client => {
            const size = client.size || [0, 0];
            return (!useScreencopyPreviews() || !client.previewSource) && Number(size[0] || 0) > 0 && Number(size[1] || 0) > 0;
        });

        runCaptureBatch();
    }

    function runCaptureBatch() {
        if (captureQueue.length === 0) {
            captureCurrent = null;
            waitingForOpen = false;
            openReady();
            return;
        }

        const commands = [
            "mkdir -p " + shellQuote(thumbnailDir),
            "rc=0",
            "pids=()"
        ];

        for (let index = 0; index < captureQueue.length; index++) {
            const client = captureQueue[index];
            const at = client.at || [0, 0];
            const size = client.size || [0, 0];
            const geometry = Math.round(Number(at[0] || 0)) + "," + Math.round(Number(at[1] || 0)) + " "
                + Math.round(Number(size[0] || 0)) + "x" + Math.round(Number(size[1] || 0));
            const path = thumbnailPath(client.address);

            commands.push("grim -g " + shellQuote(geometry) + " -t png -l 0 " + shellQuote(path) + " & pids+=(\"$!\")");
        }

        commands.push("for pid in \"${pids[@]}\"; do wait \"$pid\" || rc=1; done");
        commands.push("exit \"$rc\"");

        captureRunner.command = ["bash", "-lc", commands.join("\n")];
        captureRunner.running = true;
    }

    function applyCaptureBatchOutput(exitCode) {
        if (exitCode === 0) {
            const nextThumbnails = Object.assign({}, thumbnailByAddress);

            for (let index = 0; index < captureQueue.length; index++) {
                const client = captureQueue[index];
                nextThumbnails[String(client.address || "")] = thumbnailPath(client.address);
            }

            thumbnailByAddress = nextThumbnails;
            rebuildModel();
        } else {
            warn("Expose thumbnail batch failed");
        }

        captureQueue = [];
        captureCurrent = null;
        waitingForOpen = false;
        openReady();
    }

    function thumbnailPath(address) {
        return thumbnailDir + "/" + String(address || "").replace(/[^A-Za-z0-9_.-]/g, "_") + ".png";
    }

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\\''") + "'";
    }

    function previewSourceForAddress(address) {
        if (!useScreencopyPreviews())
            return null;

        const value = String(address || "");

        if (value.length === 0)
            return null;

        const toplevels = Hyprland.toplevels && Hyprland.toplevels.values ? Hyprland.toplevels.values : [];

        for (let index = 0; index < toplevels.length; index++) {
            const toplevel = toplevels[index];

            if (toplevel && String(toplevel.address || "") === value)
                return toplevel.wayland || null;
        }

        return null;
    }

    function useScreencopyPreviews() {
        return Boolean(theme && theme.modules && theme.modules.expose && theme.modules.expose.useScreencopy);
    }

    function rebuildModel() {
        const activeId = Number(activeWorkspace.id || 0);
        const activeName = String(activeWorkspace.name || activeId);
        const active = [];
        const grouped = {};

        for (let index = 0; index < clients.length; index++) {
            const client = clients[index];
            const workspace = client.workspace || {};
            const workspaceId = Number(workspace.id || -9999);
            const workspaceName = String(workspace.name || workspaceId);
            const item = normalizeClient(client);

            if (workspaceId === activeId || workspaceName === activeName) {
                active.push(item);
                continue;
            }

            const key = workspaceName;

            if (!grouped[key]) {
                grouped[key] = {
                    workspaceId: workspaceId,
                    workspaceName: workspaceName,
                    title: workspaceTitle(workspaceId, workspaceName),
                    clients: []
                };
            }

            grouped[key].clients.push(item);
        }

        active.sort(compareClients);

        const clusters = Object.keys(grouped).map(key => {
            const cluster = grouped[key];
            cluster.clients.sort(compareClients);
            return cluster;
        });

        clusters.sort((left, right) => {
            if (left.workspaceId !== right.workspaceId)
                return left.workspaceId - right.workspaceId;

            return left.workspaceName.localeCompare(right.workspaceName);
        });

        currentClients = active;
        workspaceClusters = clusters;

        if (!selectedAddressValid())
            selectedAddress = firstSelectableAddress();
    }

    function normalizeClient(client) {
        return {
            address: String(client.address || ""),
            title: String(client.title || "").trim(),
            className: String(client.class || client.initialClass || "").trim(),
            appLabel: appLabel(client),
            iconName: appIconName(client),
            workspaceId: Number(client.workspace && client.workspace.id || 0),
            workspaceName: String(client.workspace && client.workspace.name || ""),
            at: client.at || [0, 0],
            size: client.size || [0, 0],
            previewSource: previewSourceForAddress(client.address),
            thumbPath: thumbnailByAddress[String(client.address || "")] || "",
            floating: Boolean(client.floating),
            urgent: Boolean(client.urgent)
        };
    }

    function selectedAddressValid() {
        if (selectedAddress.length === 0)
            return false;

        return allSelectableClients().some(client => client.address === selectedAddress);
    }

    function firstSelectableAddress() {
        const all = allSelectableClients();

        return all.length > 0 ? all[0].address : "";
    }

    function allSelectableClients() {
        let result = currentClients.slice();

        for (let index = 0; index < workspaceClusters.length; index++)
            result = result.concat(workspaceClusters[index].clients || []);

        return result;
    }

    function compareClients(left, right) {
        const leftAt = left.at || [0, 0];
        const rightAt = right.at || [0, 0];

        if (leftAt[1] !== rightAt[1])
            return leftAt[1] - rightAt[1];

        if (leftAt[0] !== rightAt[0])
            return leftAt[0] - rightAt[0];

        return String(left.title || left.appLabel).localeCompare(String(right.title || right.appLabel));
    }

    function parseJsonArray(text, fallback) {
        try {
            const value = JSON.parse(String(text || "[]"));
            return Array.isArray(value) ? value : fallback;
        } catch (error) {
            applyFailure("Expose clients JSON parse error: " + error);
            return fallback;
        }
    }

    function parseJsonObject(text, fallback) {
        try {
            const value = JSON.parse(String(text || "{}"));
            return value && typeof value === "object" && !Array.isArray(value) ? value : fallback;
        } catch (error) {
            applyFailure("Expose active workspace JSON parse error: " + error);
            return fallback;
        }
    }

    function applyFailure(message) {
        error = message;
        warn(message);
    }

    function warn() {
        (log || fallbackLog).warn.apply(log || fallbackLog, arguments);
    }
}
