import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "../../core" as Core

QtObject {
    id: rootWorkspaceService

    property QtObject log
    property bool showEmptyWorkspaces: false
    property bool showSpecialWorkspaces: true
    property int normalWorkspaceStart: 1
    property int normalWorkspaceEnd: 10
    property bool useHyprlandEvents: true
    property int refreshInterval: 10000
    property int eventRefreshDelay: 60
    property int refreshAfterDispatchDelay: 120
    property int tooltipMaxWindows: 8
    property var rawWorkspaces: []
    property var rawClients: []
    property var rawMonitors: []
    property var activeWorkspace: ({ id: 0, name: "" })
    property string activeSpecialWorkspaceName
    property var workspaceModel: []
    property var dispatchQueue: []

    readonly property Core.Log fallbackLog: Core.Log {}

    readonly property Process workspacesRunner: Process {
        id: workspacesRunner

        stdout: StdioCollector {
            id: workspacesStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: workspacesStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootWorkspaceService.applyWorkspacesOutput(workspacesStdout.text, workspacesStderr.text, exitCode)
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

        onExited: (exitCode, exitStatus) => rootWorkspaceService.applyActiveOutput(activeStdout.text, activeStderr.text, exitCode)
    }

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

        onExited: (exitCode, exitStatus) => rootWorkspaceService.applyClientsOutput(clientsStdout.text, clientsStderr.text, exitCode)
    }

    readonly property Process monitorsRunner: Process {
        id: monitorsRunner

        stdout: StdioCollector {
            id: monitorsStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: monitorsStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootWorkspaceService.applyMonitorsOutput(monitorsStdout.text, monitorsStderr.text, exitCode)
    }

    readonly property Process dispatchRunner: Process {
        onExited: (exitCode, exitStatus) => rootWorkspaceService.runNextDispatch()
    }

    readonly property Timer refreshTimer: Timer {
        interval: rootWorkspaceService.refreshInterval
        repeat: true
        running: true
        onTriggered: rootWorkspaceService.refresh()
    }

    readonly property Timer refreshAfterDispatchTimer: Timer {
        interval: rootWorkspaceService.refreshAfterDispatchDelay
        repeat: false
        onTriggered: rootWorkspaceService.refresh()
    }

    readonly property Timer eventRefreshTimer: Timer {
        interval: rootWorkspaceService.eventRefreshDelay
        repeat: false
        onTriggered: rootWorkspaceService.refresh()
    }

    readonly property Connections hyprlandEvents: Connections {
        target: Hyprland

        function onRawEvent(event) {
            rootWorkspaceService.handleHyprlandEvent(event);
        }
    }

    onShowEmptyWorkspacesChanged: rebuildModel()
    onShowSpecialWorkspacesChanged: rebuildModel()
    onNormalWorkspaceStartChanged: rebuildModel()
    onNormalWorkspaceEndChanged: rebuildModel()
    onTooltipMaxWindowsChanged: rebuildModel()

    function refresh() {
        runJsonCommand(workspacesRunner, ["hyprctl", "workspaces", "-j"]);
        runJsonCommand(activeRunner, ["hyprctl", "activeworkspace", "-j"]);
        runJsonCommand(clientsRunner, ["hyprctl", "clients", "-j"]);
        runJsonCommand(monitorsRunner, ["hyprctl", "monitors", "-j"]);
    }

    function switchToWorkspace(workspace) {
        if (!workspace)
            return;

        if (workspace.isSpecial) {
            const specialName = specialWorkspaceName(workspace.name);
            dispatch("togglespecialworkspace", specialName);
            return;
        }

        focusWorkspace(String(workspace.name || workspace.id));
    }

    function focusWorkspace(workspaceName) {
        const requests = [];

        if (activeSpecialWorkspaceName.length > 0)
            requests.push(dispatchRequest("togglespecialworkspace", activeSpecialWorkspaceName));

        requests.push(dispatchRequest("workspace", workspaceName));
        queueDispatches(requests);
    }

    function switchByStep(step) {
        focusWorkspace(step > 0 ? "e+1" : "e-1");
    }

    function dispatch(dispatcher, argument) {
        queueDispatches([dispatchRequest(dispatcher, argument)]);
    }

    function focusClient(client) {
        const address = client && client.address ? String(client.address) : "";

        if (address.length === 0)
            return;

        dispatch("focuswindow", "address:" + address);
    }

    function dispatchRequest(dispatcher, argument) {
        return Hyprland.usingLua ? ["hyprctl", "dispatch", luaDispatch(dispatcher, argument)] : ["hyprctl", "dispatch", dispatcher, argument];
    }

    function queueDispatches(requests) {
        dispatchQueue = requests.filter(request => request && request.length > 0);
        runNextDispatch();
    }

    function runNextDispatch() {
        if (dispatchRunner.running || dispatchQueue.length === 0)
            return;

        const nextQueue = dispatchQueue.slice();
        const command = nextQueue.shift();

        dispatchQueue = nextQueue;
        dispatchRunner.running = false;
        dispatchRunner.command = command;
        dispatchRunner.running = true;
        refreshAfterDispatchTimer.restart();
    }

    function luaDispatch(dispatcher, argument) {
        const escapedArgument = luaString(argument);

        if (dispatcher === "workspace")
            return "hl.dsp.focus({ workspace = " + escapedArgument + " })";

        if (dispatcher === "togglespecialworkspace")
            return argument ? "hl.dsp.workspace.toggle_special(" + escapedArgument + ")" : "hl.dsp.workspace.toggle_special()";

        if (dispatcher === "focuswindow")
            return "hl.dsp.focus({ window = " + escapedArgument + " })";

        return "hl.dsp." + dispatcher + "(" + escapedArgument + ")";
    }

    function luaString(value) {
        return "\"" + String(value || "").replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\"";
    }

    function handleHyprlandEvent(event) {
        if (!useHyprlandEvents || !event)
            return;

        const eventName = String(event.name || "");

        if (eventName === "activespecial")
            applyActiveSpecialEvent(event.data);

        if (!shouldRefreshForEvent(eventName))
            return;

        eventRefreshTimer.restart();
    }

    function applyActiveSpecialEvent(payload) {
        const name = String(payload || "").split(",")[0] || "";
        activeSpecialWorkspaceName = specialWorkspaceName(name);
        rebuildModel();
    }

    function shouldRefreshForEvent(eventName) {
        switch (eventName) {
        case "workspace":
        case "workspacev2":
        case "focusedmon":
        case "focusedmonv2":
        case "createworkspace":
        case "createworkspacev2":
        case "destroyworkspace":
        case "destroyworkspacev2":
        case "moveworkspace":
        case "moveworkspacev2":
        case "renameworkspace":
        case "activespecial":
        case "openwindow":
        case "openwindowv2":
        case "closewindow":
        case "movewindow":
        case "movewindowv2":
        case "windowtitle":
        case "windowtitlev2":
        case "activewindow":
        case "activewindowv2":
        case "urgent":
        case "fullscreen":
        case "changefloatingmode":
        case "monitoradded":
        case "monitorremoved":
            return true;
        default:
            return false;
        }
    }

    function runJsonCommand(runner, command) {
        if (runner.running)
            return;

        runner.running = false;
        runner.command = command;
        runner.running = true;
    }

    function applyWorkspacesOutput(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0) {
            warn("Could not read Hyprland workspaces:", String(stderrText || "").trim());
            return;
        }

        rawWorkspaces = parseJsonArray(stdoutText, []);
        rebuildModel();
    }

    function applyActiveOutput(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0) {
            warn("Could not read active Hyprland workspace:", String(stderrText || "").trim());
            return;
        }

        activeWorkspace = parseJsonObject(stdoutText, ({ id: 0, name: "" }));
        rebuildModel();
    }

    function applyClientsOutput(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0) {
            warn("Could not read Hyprland clients:", String(stderrText || "").trim());
            return;
        }

        rawClients = parseJsonArray(stdoutText, []);
        rebuildModel();
    }

    function applyMonitorsOutput(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0) {
            warn("Could not read Hyprland monitors:", String(stderrText || "").trim());
            return;
        }

        rawMonitors = parseJsonArray(stdoutText, []);
        activeSpecialWorkspaceName = activeSpecialFromMonitors(rawMonitors);
        rebuildModel();
    }

    function rebuildModel() {
        const clientsByWorkspace = clientsByWorkspaceName();
        const workspaceByName = {};
        const result = [];

        for (let index = 0; index < rawWorkspaces.length; index++) {
            const workspace = rawWorkspaces[index];

            if (!workspace || !workspace.name)
                continue;

            workspaceByName[String(workspace.name)] = workspace;
        }

        for (let number = normalWorkspaceStart; number <= normalWorkspaceEnd; number++) {
            const name = String(number);
            const workspace = workspaceByName[name] || ({ id: number, name: name, windows: 0 });
            const item = workspaceItem(workspace, clientsByWorkspace[name] || []);

            if (showEmptyWorkspaces || item.active || item.windowCount > 0)
                result.push(item);
        }

        for (let index = 0; index < rawWorkspaces.length; index++) {
            const workspace = rawWorkspaces[index];

            if (!workspace || !isSpecialWorkspace(workspace))
                continue;

            const item = workspaceItem(workspace, clientsByWorkspace[String(workspace.name)] || []);

            if (showSpecialWorkspaces && (item.active || item.windowCount > 0))
                result.push(item);
        }

        workspaceModel = result.sort((left, right) => {
            if (left.isSpecial !== right.isSpecial)
                return left.isSpecial ? 1 : -1;

            if (!left.isSpecial && left.id !== right.id)
                return left.id - right.id;

            return left.displayName.localeCompare(right.displayName);
        });
    }

    function workspaceItem(workspace, clients) {
        const name = String(workspace.name || workspace.id || "");
        const isSpecial = isSpecialWorkspace(workspace);
        const active = isActiveWorkspace(workspace);
        const specialActive = isSpecial && specialWorkspaceName(name) === activeSpecialWorkspaceName;
        const windowCount = clients.length > 0 ? clients.length : Number(workspace.windows || 0);

        return {
            id: Number(workspace.id || 0),
            name: name,
            displayName: displayName(workspace),
            isSpecial: isSpecial,
            active: active,
            specialActive: specialActive,
            empty: windowCount === 0,
            windowCount: windowCount,
            clients: clients,
            tooltipTitle: tooltipTitle(workspace, windowCount),
            tooltipContent: tooltipContent(workspace, clients, windowCount)
        };
    }

    function clientsByWorkspaceName() {
        const result = {};

        for (let index = 0; index < rawClients.length; index++) {
            const client = rawClients[index];
            const workspace = client && client.workspace ? client.workspace : null;
            const name = workspace && workspace.name ? String(workspace.name) : "";

            if (name.length === 0)
                continue;

            if (!result[name])
                result[name] = [];

            result[name].push(client);
        }

        return result;
    }

    function isActiveWorkspace(workspace) {
        return String(workspace.name || "") === String(activeWorkspace.name || "") || Number(workspace.id || 0) === Number(activeWorkspace.id || 0);
    }

    function isSpecialWorkspace(workspace) {
        return Number(workspace.id || 0) < 0 || String(workspace.name || "").indexOf("special:") === 0;
    }

    function specialWorkspaceName(name) {
        return String(name || "").replace(/^special:/, "");
    }

    function activeSpecialFromMonitors(monitors) {
        for (let index = 0; index < monitors.length; index++) {
            const monitor = monitors[index];
            const specialWorkspace = monitor && monitor.specialWorkspace ? monitor.specialWorkspace : null;
            const name = specialWorkspace && specialWorkspace.name ? specialWorkspaceName(specialWorkspace.name) : "";

            if (name.length > 0)
                return name;
        }

        return "";
    }

    function displayName(workspace) {
        const name = String(workspace.name || workspace.id || "");

        return isSpecialWorkspace(workspace) ? specialWorkspaceName(name) : name;
    }

    function tooltipTitle(workspace, windowCount) {
        const name = displayName(workspace);
        const prefix = isSpecialWorkspace(workspace) ? "Special " : "Workspace ";

        return prefix + name + " - " + windowCount + (windowCount === 1 ? " window" : " windows");
    }

    function tooltipContent(workspace, clients, windowCount) {
        if (clients.length === 0)
            return windowCount > 0 ? windowCount + " windows" : "No windows";

        const lines = [];
        const max = Math.min(clients.length, tooltipMaxWindows);

        for (let index = 0; index < max; index++) {
            const client = clients[index];
            const app = appLabel(client);
            const title = String(client.title || "").trim();

            lines.push(title.length > 0 ? app + " - " + title : app);
        }

        if (clients.length > max)
            lines.push("+" + (clients.length - max) + " more");

        return lines.join("\n");
    }

    function appLabel(client) {
        const text = String(client.class || client.initialClass || "Unknown").trim();
        const chromeMatch = text.match(/^chrome-[^-]+-(.+)$/);

        if (chromeMatch)
            return chromeMatch[1];

        if (text === "com.mitchellh.ghostty")
            return "ghostty";

        return text;
    }

    function parseJsonArray(text, fallback) {
        try {
            const value = JSON.parse(String(text || "[]"));
            return Array.isArray(value) ? value : fallback;
        } catch (error) {
            warn("Workspace JSON parse error:", error);
            return fallback;
        }
    }

    function parseJsonObject(text, fallback) {
        try {
            const value = JSON.parse(String(text || "{}"));
            return value && typeof value === "object" && !Array.isArray(value) ? value : fallback;
        } catch (error) {
            warn("Active workspace JSON parse error:", error);
            return fallback;
        }
    }

    function warn() {
        (log || fallbackLog).warn.apply(log || fallbackLog, arguments);
    }

    Component.onCompleted: refresh()
}
