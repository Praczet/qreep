import QtQuick

// /p as the panel sees it: Places' projects, filtered by the typed words,
// with git and quest state on the second line. Enter opens Places on the
// project, Shift+Enter its cockpit, Ctrl+Enter its editor. The data is
// Places' own service (places = the Places controller), so the two never
// disagree. host is KipPanel.
Item {
    id: rootKipProjectsCommand

    required property QtObject host
    property QtObject places: null

    readonly property QtObject service: places ? places.service : null
    readonly property bool active: host.contentState === "projects"
    property int index: 0
    property string query: ""
    readonly property var matches: service ? service.filterProjects(service.projects, query) : []
    readonly property var results: matches.map(project => row(project))
    readonly property bool listVisible: active && results.length > 0
    readonly property string eventKey: service === null ? "projects.error" : query.trim().length === 0 ? "projects.ready" : results.length > 0 ? "projects.found" : "projects.empty"

    function reset() {
        query = "";
        index = 0;
    }

    // "/p " lists every project; typing narrows them (name, id, group, path).
    function show() {
        if (!active) {
            host.backToCompose();
            host.contentState = "projects";
            index = 0;
            if (service)
                service.refreshSummaries();
        }
        query = host.parsed.argument;
        index = Math.min(index, Math.max(0, results.length - 1));
    }

    // KipResultList shape: origin chip = group, folder + file = path + name.
    function row(project) {
        const summary = service.summaries[project.id] || null;

        return {
            origin: project.group,
            folder: project.displayPath ? project.displayPath.replace(/[^\/]+$/, "") : "",
            file: project.name,
            excerpt: project.kind === "place" ? project.blocks.map(block => block.title).join(" · ") : describe(summary)
        };
    }

    function describe(summary) {
        if (!summary)
            return "";
        if (summary.missing)
            return "folder missing";
        if (!summary.git)
            return "not a git repo";

        const parts = ["⎇ " + summary.branch];

        if (summary.lastCommitTime)
            parts.push(service.ago(summary.lastCommitTime) + " ago");
        if (summary.changed > 0)
            parts.push("● " + summary.changed + " changed");
        if (summary.ahead > 0)
            parts.push("↑" + summary.ahead);
        if (summary.quests)
            parts.push(summary.quests.active + " active quests" + (summary.quests.blockedSteps > 0 ? ", " + summary.quests.blockedSteps + " blocked steps" : ""));
        return parts.join(" · ");
    }

    // Enter: Places on it. Shift+Enter: cockpit (Ctrl+Enter is in handleKey).
    // KIP closes either way.
    function submit(shifted) {
        const project = matches[index];

        if (!project)
            return;

        if (shifted)
            service.openCockpit(project);
        else
            places.showProject(project.id);
        host.closeRequested();
    }

    function handleKey(event) {
        if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && listVisible) {
            index = host.clampIndex(index + (event.key === Qt.Key_Down ? 1 : -1), results.length);
            event.accepted = true;
            return true;
        }

        // Ctrl+Enter: the panel's Enter path only knows Shift, so take it here.
        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier) && listVisible) {
            event.accepted = true;
            const project = matches[index];

            if (project) {
                service.openInEditor(project, "");
                host.closeRequested();
            }
            return true;
        }

        return false;
    }

    function status() {
        if (service === null)
            return "Places is not loaded";
        if (service.configError.length > 0)
            return service.configError;
        return results.length === service.projects.length ? results.length + " projects" : results.length + " of " + service.projects.length + " projects";
    }

    function enterLabel() {
        return listVisible ? "open in Places" : "";
    }

    function keyHints() {
        return listVisible ? "↑↓ choose · Enter Places · Shift+Enter cockpit · Ctrl+Enter editor · Esc back" : "Esc back · fewer words?";
    }
}
