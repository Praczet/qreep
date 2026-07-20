import QtQuick
import Quickshell
import Quickshell.Io
import "../../core" as Core

QtObject {
    id: rootTriageService

    required property QtObject theme
    property QtObject log
    property string searchText: ""
    property string noteText: ""
    property string activeCategory: "updates"
    property string activeDecisionFilter: "all"
    property var summary: ({})
    property var reviewItems: []
    property var commandEvents: []
    property var decisionByPackage: ({})
    property var packageItems: []
    property var filteredItems: []
    property int selectedIndex: filteredItems.length > 0 ? 0 : -1
    property var selectedItem: selectedIndex >= 0 && selectedIndex < filteredItems.length ? filteredItems[selectedIndex] : null
    property var packageDetails: ({})
    property string pendingFocusPackage: ""
    property string pendingInspectPackage: ""
    property string queuedCategory: ""
    property bool loadingSummary: false
    property bool loadingDecisions: false
    property bool loadingEvents: false
    property bool loadingDetails: false
    property bool writingDecision: false
    property bool pendingEventsRefresh: false
    property string error: ""
    property string status: "idle"
    property var lastEvent: null
    property string pendingDecisionKind: ""

    readonly property Core.Log fallbackLog: Core.Log {}

    readonly property Process copyNotifier: Process {}

    onSearchTextChanged: applyFilter()

    readonly property Process summaryRunner: Process {
        stdout: StdioCollector {
            id: summaryStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: summaryStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootTriageService.applySummaryOutput(summaryStdout.text, summaryStderr.text, exitCode)
    }

    readonly property Process decisionsRunner: Process {
        stdout: StdioCollector {
            id: decisionsStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: decisionsStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootTriageService.applyDecisionsOutput(decisionsStdout.text, decisionsStderr.text, exitCode)
    }

    readonly property Process eventsRunner: Process {
        stdout: StdioCollector {
            id: eventsStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: eventsStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootTriageService.applyEventsOutput(eventsStdout.text, eventsStderr.text, exitCode)
    }

    readonly property Process packageRunner: Process {
        stdout: StdioCollector {
            id: packageStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: packageStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootTriageService.applyPackageOutput(packageStdout.text, packageStderr.text, exitCode)
    }

    readonly property Process queueRunner: Process {
        stdout: StdioCollector {
            id: queueStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: queueStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootTriageService.applyQueueOutput(queueStdout.text, queueStderr.text, exitCode)
    }

    readonly property Process whyRunner: Process {
        stdout: StdioCollector {
            id: whyStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: whyStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootTriageService.applyWhyOutput(whyStdout.text, whyStderr.text, exitCode)
    }

    readonly property Process decideRunner: Process {
        stdout: StdioCollector {
            id: decideStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: decideStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootTriageService.applyDecideOutput(decideStdout.text, decideStderr.text, exitCode)
    }

    readonly property Process exportRunner: Process {
        stdout: StdioCollector {
            id: exportStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: exportStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootTriageService.applyExportOutput(exportStdout.text, exportStderr.text, exitCode)
    }

    function refresh() {
        loadSummary();
        loadDecisions();
        loadEvents();
        loadCategory(activeCategory);
    }

    function loadSummary() {
        if (summaryRunner.running)
            return;

        loadingSummary = true;
        error = "";
        status = "loading summary";
        summaryRunner.command = ["triagectl", "summary", "--json"];
        summaryRunner.running = true;
    }

    function loadDecisions() {
        if (decisionsRunner.running)
            return;

        loadingDecisions = true;
        error = "";
        status = "loading decisions";
        decisionsRunner.command = ["triagectl", "decisions", "--json"];
        decisionsRunner.running = true;
    }

    function loadEvents() {
        if (eventsRunner.running) {
            pendingEventsRefresh = true;
            return;
        }

        loadingEvents = true;
        pendingEventsRefresh = false;
        error = "";
        status = "loading command events";
        eventsRunner.command = ["triagectl", "events", "--limit", "80", "--json"];
        eventsRunner.running = true;
    }

    function loadCategory(category) {
        const normalized = normalizeCategory(category);
        if (packageRunner.running) {
            queuedCategory = normalized;
            activeCategory = normalized;
            return;
        }

        activeCategory = normalized;
        loadingDecisions = true;
        error = "";
        status = "loading " + categoryLabel(activeCategory);
        packageRunner.command = ["triagectl", "packages", activeCategory, "--json"];
        packageRunner.running = true;
    }

    function queueOrphans() {
        if (queueRunner.running)
            return;

        loadingDecisions = true;
        error = "";
        status = "queueing orphans";
        queueRunner.command = ["triagectl", "queue-orphans", "--json"];
        queueRunner.running = true;
    }

    function inspectSelected() {
        const item = selectedItem;
        if (!item)
            return;

        inspectPackage(item.package);
    }

    function inspectPackage(packageName) {
        if (!packageName || packageName.length === 0)
            return;

        if (whyRunner.running) {
            pendingInspectPackage = packageName;
            return;
        }

        pendingInspectPackage = "";
        loadingDetails = true;
        error = "";
        status = "inspecting " + packageName;
        whyRunner.command = ["triagectl", "why", packageName, "--json"];
        whyRunner.running = true;
    }

    function focusPackage(packageName) {
        const target = String(packageName || "").trim();
        if (target.length === 0)
            return;

        pendingFocusPackage = target;
        activeDecisionFilter = "all";
        searchText = target;
        packageDetails = {};
        loadCategory("total");
        inspectPackage(target);
    }

    function decideSelected(kind) {
        const item = selectedItem;
        if (!item || decideRunner.running)
            return;

        pendingDecisionKind = kind;
        writingDecision = true;
        error = "";
        status = "recording " + kind + " for " + item.package;

        const command = ["triagectl", "decide", item.package, kind, "--json"];
        const note = noteText.trim();
        if (note.length > 0) {
            command.splice(command.length - 1, 0, "--note", note);
        }

        decideRunner.command = command;
        decideRunner.running = true;
    }

    function exportJson() {
        runExport("export-json");
    }

    function exportMarkdown() {
        runExport("export-md");
    }

    function copyLastCommand() {
        copyEventCommand(lastEvent);
    }

    function copyEventCommand(event) {
        const command = eventCommandLine(event);
        copyCommand(command);
    }

    function copyCommand(commandText) {
        const command = String(commandText || "");
        if (command.length === 0)
            return;

        Quickshell.clipboardText = command;
        status = "copied command";
        notifyCommandCopied(command);
    }

    function eventCommandLine(event) {
        if (!event || !Array.isArray(event.argv) || event.argv.length === 0)
            return event && event.provider ? String(event.provider) : "";

        return event.argv.map(shellQuote).join(" ");
    }

    function shellQuote(value) {
        const part = String(value);
        if (/^[A-Za-z0-9_./:=+@%,-]+$/.test(part))
            return part;

        return "'" + part.replace(/'/g, "'\\''") + "'";
    }

    function notifyCommandCopied(command) {
        copyNotifier.running = false;
        copyNotifier.command = [
            "notify-send",
            "--app-name=Qreep",
            "--urgency=low",
            "--expire-time=1800",
            "Triage",
            "command \"" + command + "\" was copied to clipboard."
        ];
        copyNotifier.running = true;
    }

    function runExport(commandName) {
        if (exportRunner.running)
            return;

        error = "";
        status = "exporting";
        exportRunner.command = ["triagectl", commandName, "--json"];
        exportRunner.running = true;
    }

    function applySummaryOutput(stdout, stderr, exitCode) {
        loadingSummary = false;
        const parsed = parseOutput(stdout, stderr, exitCode, "summary");
        if (!parsed)
            return;

        summary = parsed;
        lastEvent = parsed.lastEvent || null;
        status = eventStatus(lastEvent, "summary loaded");
        loadEvents();
    }

    function applyDecisionsOutput(stdout, stderr, exitCode) {
        loadingDecisions = false;
        const parsed = parseOutput(stdout, stderr, exitCode, "decisions");
        if (!parsed)
            return;

        reviewItems = Array.isArray(parsed.items) ? parsed.items : [];
        rebuildDecisionMap();
        packageItems = mergeDecisions(packageItems, activeCategory);
        applyFilter();
        status = "loaded " + reviewItems.length + " review items";
    }

    function applyEventsOutput(stdout, stderr, exitCode) {
        loadingEvents = false;
        const parsed = parseOutput(stdout, stderr, exitCode, "events");
        if (!parsed)
            return;

        commandEvents = Array.isArray(parsed.events) ? parsed.events : [];
        status = "loaded " + commandEvents.length + " command events";
        if (pendingEventsRefresh)
            loadEvents();
    }

    function applyPackageOutput(stdout, stderr, exitCode) {
        loadingDecisions = false;
        const parsed = parseOutput(stdout, stderr, exitCode, "packages");
        if (!parsed)
            return;

        lastEvent = parsed.event || null;
        packageItems = mergeDecisions(Array.isArray(parsed.packages) ? parsed.packages.map(packageEntry => normalizePackageEntry(packageEntry, parsed.category || activeCategory)) : [], parsed.category || activeCategory);
        applyFilter();
        applyPendingFocusPackage();
        status = eventStatus(lastEvent, "loaded " + packageItems.length + " packages");
        loadEvents();
        if (queuedCategory.length > 0) {
            const nextCategory = queuedCategory;
            queuedCategory = "";
            if (nextCategory !== parsed.category)
                loadCategory(nextCategory);
        }
    }

    function applyQueueOutput(stdout, stderr, exitCode) {
        loadingDecisions = false;
        const parsed = parseOutput(stdout, stderr, exitCode, "queue-orphans");
        if (!parsed)
            return;

        lastEvent = parsed.internalEvent || parsed.sourceEvent || null;
        status = "queued " + parsed.added + " new orphan items";
        loadEvents();
        loadDecisions();
        loadCategory("orphans");
    }

    function applyWhyOutput(stdout, stderr, exitCode) {
        loadingDetails = false;
        const parsed = parseOutput(stdout, stderr, exitCode, "why");
        if (!parsed)
            return;

        packageDetails = parsed;
        if (Array.isArray(parsed.events) && parsed.events.length > 0)
            lastEvent = parsed.events[parsed.events.length - 1];
        status = eventStatus(lastEvent, "loaded package details");
        loadEvents();
        if (pendingInspectPackage.length > 0 && pendingInspectPackage !== parsed.package) {
            const nextPackage = pendingInspectPackage;
            pendingInspectPackage = "";
            inspectPackage(nextPackage);
        } else {
            pendingInspectPackage = "";
        }
    }

    function applyDecideOutput(stdout, stderr, exitCode) {
        writingDecision = false;
        const parsed = parseOutput(stdout, stderr, exitCode, "decide");
        if (!parsed)
            return;

        lastEvent = parsed.event || null;
        status = "recorded " + pendingDecisionKind + " for " + parsed.package;
        pendingDecisionKind = "";
        noteText = "";
        loadEvents();
        loadDecisions();
        loadCategory(activeCategory);
        inspectPackage(parsed.package);
    }

    function applyExportOutput(stdout, stderr, exitCode) {
        const parsed = parseOutput(stdout, stderr, exitCode, "export");
        if (!parsed)
            return;

        status = "exported " + parsed.path;
        loadEvents();
    }

    function parseOutput(stdout, stderr, exitCode, label) {
        if (exitCode !== 0) {
            reportError("triagectl " + label + " failed:", stderr.length > 0 ? stderr : "exit " + exitCode);
            return null;
        }

        try {
            return JSON.parse(stdout.length > 0 ? stdout : "{}");
        } catch (error) {
            reportError("triagectl " + label + " JSON error:", error);
            return null;
        }
    }

    function applyFilter() {
        const needle = searchText.trim().toLowerCase();
        let nextItems = packageItems;

        if (activeDecisionFilter !== "all") {
            nextItems = nextItems.filter(item => latestDecisionKind(item) === activeDecisionFilter);
        }

        if (needle.length > 0) {
            nextItems = nextItems.filter(item => {
                const latest = latestDecisionKind(item).toLowerCase();
                return String(item.package || "").toLowerCase().indexOf(needle) !== -1 || String(item.source || "").toLowerCase().indexOf(needle) !== -1 || latest.indexOf(needle) !== -1;
            });
        }

        filteredItems = nextItems;
        clampSelection();
    }

    function applyPendingFocusPackage() {
        if (pendingFocusPackage.length === 0)
            return;

        const target = pendingFocusPackage;
        for (let index = 0; index < filteredItems.length; index++) {
            if (filteredItems[index] && filteredItems[index].package === target) {
                selectedIndex = index;
                pendingFocusPackage = "";
                return;
            }
        }
    }

    function clampSelection() {
        if (filteredItems.length === 0) {
            selectedIndex = -1;
            packageDetails = {};
            return;
        }

        if (selectedIndex < 0)
            selectedIndex = 0;
        else if (selectedIndex >= filteredItems.length)
            selectedIndex = filteredItems.length - 1;

        if (packageDetails && packageDetails.package && selectedItem && packageDetails.package !== selectedItem.package)
            packageDetails = {};
    }

    function setSelection(index) {
        if (filteredItems.length === 0) {
            selectedIndex = -1;
            packageDetails = {};
            return;
        }

        selectedIndex = Math.max(0, Math.min(filteredItems.length - 1, index));
        if (packageDetails && packageDetails.package && selectedItem && packageDetails.package !== selectedItem.package)
            packageDetails = {};
    }

    function moveSelection(offset) {
        if (filteredItems.length === 0)
            return;

        setSelection(selectedIndex + offset);
    }

    function latestDecisionKind(item) {
        if (!item || !item.latestDecision)
            return "none";

        return String(item.latestDecision.kind || "none");
    }

    function rebuildDecisionMap() {
        const nextMap = {};
        for (let index = 0; index < reviewItems.length; index++) {
            const item = reviewItems[index];
            if (item && item.package)
                nextMap[item.package] = item;
        }
        decisionByPackage = nextMap;
    }

    function normalizePackageEntry(entry, category) {
        if (typeof entry === "string") {
            return {
                "package": entry,
                "source": category,
                "oldVersion": "",
                "newVersion": "",
                "createdTs": 0,
                "latestDecision": null,
                "decisions": []
            };
        }

        const packageName = entry && (entry.name || entry.package) ? String(entry.name || entry.package) : "";
        return {
            "package": packageName,
            "source": category,
            "oldVersion": entry && entry.oldVersion ? String(entry.oldVersion) : "",
            "newVersion": entry && entry.newVersion ? String(entry.newVersion) : "",
            "createdTs": 0,
            "latestDecision": null,
            "decisions": []
        };
    }

    function mergeDecisions(items, category) {
        return items.map(item => {
            const decisionItem = decisionByPackage[item.package];
            if (!decisionItem)
                return item;

            const copy = Object.assign({}, item);
            copy.source = category || item.source || decisionItem.source || activeCategory;
            copy.createdTs = decisionItem.createdTs || item.createdTs || 0;
            copy.latestDecision = decisionItem.latestDecision || null;
            copy.decisions = Array.isArray(decisionItem.decisions) ? decisionItem.decisions : [];
            return copy;
        });
    }

    function setCategory(category) {
        const normalized = normalizeCategory(category);
        searchText = "";
        if (activeCategory === normalized && packageItems.length > 0) {
            applyFilter();
            return;
        }

        loadCategory(normalized);
    }

    function setDecisionFilter(filter) {
        searchText = "";
        activeDecisionFilter = normalizeDecisionFilter(filter);
        applyFilter();
    }

    function normalizeCategory(category) {
        switch (category) {
        case "updates":
        case "outdated":
            return "updates";
        case "orphans":
            return "orphans";
        case "dependencies":
        case "deps":
            return "dependencies";
        case "explicit":
            return "explicit";
        default:
            return "total";
        }
    }

    function normalizeDecisionFilter(filter) {
        switch (filter) {
        case "keep":
        case "investigate":
        case "plan-remove":
        case "skip":
        case "none":
            return filter;
        default:
            return "all";
        }
    }

    function categoryLabel(category) {
        switch (normalizeCategory(category)) {
        case "updates":
            return "updates";
        case "orphans":
            return "orphans";
        case "dependencies":
            return "deps";
        case "explicit":
            return "explicit";
        default:
            return "total";
        }
    }

    function selectedDecisionKind() {
        return latestDecisionKind(selectedItem);
    }

    function summaryCount(key) {
        const normalizedKey = key === "updates" ? "outdated" : key;
        const value = summary[normalizedKey];
        if (!value)
            return "-";

        if (value.ok && value.count !== undefined && value.count !== null)
            return String(value.count);

        return "!";
    }

    function summaryError(key) {
        const normalizedKey = key === "updates" ? "outdated" : key;
        const value = summary[normalizedKey];
        return value && value.error ? String(value.error) : "";
    }

    function decisionCount(filter) {
        if (filter === "all")
            return packageItems.length;

        return packageItems.filter(item => latestDecisionKind(item) === filter).length;
    }

    function eventStatus(event, fallback) {
        if (!event)
            return fallback;

        const state = event.ok ? "ok" : "failed";
        return event.commandId + " " + state;
    }

    function reportError() {
        error = messageText(arguments);
        status = error;
        (log || fallbackLog).error(error);
    }

    function messageText(messages) {
        const parts = [];

        for (let index = 0; index < messages.length; index++)
            parts.push(String(messages[index]).trim());

        return parts.join(" ");
    }
}
