import QtQuick
import Quickshell
import Quickshell.Io

// /win: Hyprland clients from `hyprctl clients -j`, read once when /win is
// entered and filtered locally while typing. Focusing goes through Expose's
// service (workspace switch, then focuswindow, Lua dispatch aware) so there is
// one focus path in Qreep, not two with different opinions. Previews borrow
// Expose's Toplevel matching for the same reason.
Item {
    id: rootKipWindowService

    required property QtObject kipTheme
    property var exposeService: null
    // grid | list, and icon | preview. Runtime only, like the app view.
    property string view: kipTheme.windowDefaultView
    property string display: kipTheme.windowDefaultDisplay

    // idle | loading | ready | error
    property string status: "idle"
    property var clients: []
    property var results: []
    property string query: ""
    property string errorText: ""
    property string eventKey: ""

    Process {
        id: clientsProcess

        stdout: StdioCollector {
            id: clientsStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: clientsStderr

            waitForEnd: true
        }

        onExited: exitCode => rootKipWindowService.finish(exitCode, clientsStdout.text, clientsStderr.text)
    }

    function load() {
        if (clientsProcess.running)
            return;

        status = "loading";
        clientsProcess.command = ["hyprctl", "clients", "-j"];
        clientsProcess.running = true;
    }

    function reset() {
        clientsProcess.running = false;
        status = "idle";
        clients = [];
        results = [];
        query = "";
        errorText = "";
        eventKey = "";
    }

    function finish(exitCode, stdoutText, stderrText) {
        let parsed = null;

        try {
            parsed = JSON.parse(stdoutText);
        } catch (error) {
            parsed = null;
        }

        if (exitCode !== 0 || !Array.isArray(parsed)) {
            status = "error";
            errorText = String(stderrText).trim() || "hyprctl clients -j did not return a list.";
            eventKey = "win.empty";
            return;
        }

        // Mapped, visible clients; most recently focused first.
        const usedToplevels = [];

        clients = parsed.filter(client => client.mapped !== false && client.hidden !== true && String(client.address || "").length > 0).sort((left, right) => Number(left.focusHistoryID) - Number(right.focusHistoryID)).map(client => {
            const workspace = client.workspace || {};
            const workspaceName = String(workspace.name || workspace.id || "");
            const size = client.size || [0, 0];

            return {
                address: String(client.address),
                title: String(client.title || ""),
                className: String(client.class || client.initialClass || ""),
                appLabel: exposeService ? exposeService.appLabel(client) : String(client.class || ""),
                iconSource: iconSourceFor(client),
                // A Wayland Toplevel for ScreencopyView, or null when the match
                // is ambiguous; then the card shows the icon instead of a guess.
                previewSource: exposeService ? exposeService.previewSourceForClient(client, usedToplevels) : null,
                width: Number(size[0] || 0),
                height: Number(size[1] || 0),
                workspaceId: Number(workspace.id || 0),
                workspaceName: workspaceName,
                focused: Number(client.focusHistoryID) === 0
            };
        });
        status = "ready";
        filter(query);
    }

    // Every word must appear in class, title or workspace; ranking prefers
    // class matches, then title, then recency (the list is already in focus order).
    function filter(text) {
        query = String(text || "");

        const words = query.toLowerCase().split(/\s+/).filter(word => word.length > 0);
        const matched = [];

        clients.forEach((client, order) => {
            const className = client.className.toLowerCase();
            const title = client.title.toLowerCase();
            const haystack = className + " " + title + " workspace " + client.workspaceName.toLowerCase();

            if (!words.every(word => haystack.indexOf(word) >= 0))
                return;

            const classHits = words.filter(word => className.indexOf(word) >= 0).length;
            const titleHits = words.filter(word => title.indexOf(word) >= 0).length;

            matched.push(Object.assign({}, client, {
                rank: -(classHits * 2 + titleHits),
                order: order
            }));
        });

        matched.sort((left, right) => left.rank - right.rank || left.order - right.order);
        results = matched;

        if (status === "ready")
            eventKey = matched.length > 0 ? "win.found" : "win.empty";
    }

    function toggleView() {
        view = view === "grid" ? "list" : "grid";
    }

    function toggleDisplay() {
        display = display === "preview" ? "icon" : "preview";
    }

    // Desktop entry first (it knows StartupWMClass), then Expose's hand-made
    // class -> icon fixes, then the class itself.
    function iconSourceFor(client) {
        const className = String(client.class || client.initialClass || "");
        const entry = className.length > 0 && typeof DesktopEntries.heuristicLookup === "function" ? DesktopEntries.heuristicLookup(className) : null;
        const icon = entry && entry.icon ? String(entry.icon) : exposeService ? exposeService.appIconName(client) : className.toLowerCase();

        if (icon.startsWith("/"))
            return "file://" + icon;
        return Quickshell.iconPath(icon, "application-x-executable");
    }

    function focusClient(client) {
        if (!exposeService || !client)
            return false;

        exposeService.focusClientObject(client);
        return true;
    }
}
