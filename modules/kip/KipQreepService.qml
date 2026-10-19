import QtQuick
import Quickshell
import Quickshell.Io

// /qreep: every IPC function the running Qreep registers, from
// `quickshell ipc --pid <this process> show`, so the list is whatever the
// shell actually has, not a copy that drifts. Calls go back through the same
// CLI. Arguments are typed after the function name; the last parameter takes
// the rest of the line, so labels with spaces work.
Item {
    id: rootKipQreepService

    required property QtObject theme

    readonly property QtObject kt: theme.modules.kip

    // idle | loading | ready | error
    property string status: "idle"
    property var entries: []
    property var results: []
    // The input names one function exactly: { entry, args, ready }.
    property var exact: null
    property string errorText: ""
    // What the input asked for; re-applied when the list arrives.
    property string lastArgument: ""
    property string eventKey: ""
    // Last call: running | done | error, and what it returned.
    property string callStatus: "idle"
    property string callOutput: ""
    property string callLabel: ""
    // Ctrl+H: debug and hidden functions too. The catalog tidies, it does not forbid.
    property bool showAll: false
    // Toggle list: the exact entry has catalog `toggles`. Items are
    // { id, on } read from its state function; toggleResults is that list
    // narrowed by whatever was typed after the function name.
    property var toggleEntry: null
    property var toggleItems: []
    property var toggleResults: []
    // idle | loading | ready | error
    property string toggleStatus: "idle"
    property string toggleError: ""
    property string toggleFilter: ""

    KipQreepCatalog {
        id: catalog
    }

    // Section title -> icon for KipQreepList.
    readonly property var groupIcons: {
        const icons = {};

        for (const group of catalog.groups)
            icons[group.title] = group.icon;
        return icons;
    }

    Process {
        id: showProcess

        stdout: StdioCollector {
            id: showStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: showStderr

            waitForEnd: true
        }

        onExited: exitCode => rootKipQreepService.finishShow(exitCode, showStdout.text, showStderr.text)
    }

    Process {
        id: callProcess

        stdout: StdioCollector {
            id: callStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: callStderr

            waitForEnd: true
        }

        onExited: exitCode => rootKipQreepService.finishCall(exitCode, callStdout.text, callStderr.text)
    }

    Process {
        id: detachedCall
    }

    Process {
        id: toggleStateProcess

        stdout: StdioCollector {
            id: toggleStateStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: toggleStateStderr

            waitForEnd: true
        }

        onExited: exitCode => rootKipQreepService.finishToggleState(exitCode, toggleStateStdout.text, toggleStateStderr.text)
    }

    Process {
        id: flipProcess

        stderr: StdioCollector {
            id: flipStderr

            waitForEnd: true
        }

        // Re-read instead of trusting the flip: the switch shows what the
        // shell says now, not what KIP hoped would happen.
        onExited: exitCode => {
            if (exitCode !== 0) {
                rootKipQreepService.toggleStatus = "error";
                rootKipQreepService.toggleError = String(flipStderr.text || "").trim() || "exited " + exitCode;
                return;
            }
            rootKipQreepService.loadToggleState();
        }
    }

    function ipcBase() {
        return ["quickshell", "ipc", "--pid", String(Quickshell.processId)];
    }

    function load() {
        if (showProcess.running)
            return;

        status = "loading";
        errorText = "";
        showProcess.command = ipcBase().concat(["show"]);
        showProcess.running = true;
    }

    // "target qreep-timer" then "  function startCountdown(duration: string, label: string): void"
    function finishShow(exitCode, stdoutText, stderrText) {
        if (exitCode !== 0) {
            status = "error";
            errorText = String(stderrText || "").trim().split("\n")[0] || "quickshell ipc show exited " + exitCode;
            eventKey = "qreep.error";
            return;
        }

        const parsed = [];
        let target = "";

        for (const line of String(stdoutText || "").split("\n")) {
            const targetMatch = /^target\s+(\S+)/.exec(line);

            if (targetMatch) {
                target = targetMatch[1];
                continue;
            }

            const fn = /^\s+function\s+(\w+)\((.*)\):\s*(\S+)/.exec(line);

            if (!fn || target.length === 0)
                continue;

            const params = fn[2].trim().length === 0 ? [] : fn[2].split(",").map(part => {
                const pieces = part.split(":");

                return {
                    name: pieces[0].trim(),
                    type: (pieces[1] || "").trim()
                };
            });
            const shortName = target.replace(/^qreep-/, "");
            const shown = catalog.describe(target, fn[1]);
            const group = catalog.group(shown.group);

            parsed.push({
                target: target,
                shortName: shortName,
                name: fn[1],
                params: params,
                returns: fn[3],
                label: shortName + " " + fn[1],
                title: shown.label.length > 0 ? shown.label : shortName + " " + fn[1],
                icon: shown.icon,
                choices: shown.choices,
                toggles: shown.toggles,
                listed: shown.visible,
                group: group.id,
                groupTitle: group.title,
                groupRank: catalog.groupRank(group.id),
                rank: shown.rank,
                excerpt: "(" + params.map(param => param.name + ": " + param.type).join(", ") + "): " + fn[3]
            });
        }

        // Group order, then catalog order, then name: ListView sections need groups contiguous.
        parsed.sort((left, right) => left.groupRank - right.groupRank || left.rank - right.rank || left.shortName.localeCompare(right.shortName) || left.name.localeCompare(right.name));
        entries = parsed;
        status = "ready";
        eventKey = "qreep.ready";
        filter(lastArgument);
    }

    // Every word must appear in "target function". Once the first two words
    // name a function exactly, the rest are its arguments.
    function filter(argument) {
        const text = String(argument || "").trim();

        lastArgument = text;

        const words = text.length > 0 ? text.split(/\s+/) : [];

        exact = resolve(words);
        updateToggleEntry();

        if (exact) {
            results = [exact.entry];
            return;
        }

        const lowered = words.map(word => word.toLowerCase());

        results = listedEntries().filter(entry => {
            const haystack = (entry.title + " " + entry.label + " " + entry.target + " " + entry.groupTitle).toLowerCase();

            return lowered.every(word => haystack.indexOf(word) >= 0);
        });
        if (status === "ready")
            eventKey = results.length > 0 ? "qreep.ready" : "qreep.nomatch";
    }

    function listedEntries() {
        return showAll ? entries : entries.filter(entry => entry.listed);
    }

    function toggleShowAll() {
        showAll = !showAll;
        filter(lastArgument);
    }

    // A choice the typed value names, exactly or as the only prefix match.
    function matchChoice(entry, value) {
        const typed = String(value || "").toLowerCase();
        const exactChoice = entry.choices.find(choice => choice.toLowerCase() === typed);

        if (exactChoice !== undefined)
            return exactChoice;

        const prefixed = entry.choices.filter(choice => choice.toLowerCase().startsWith(typed));

        return prefixed.length === 1 ? prefixed[0] : null;
    }

    function resolve(words) {
        if (words.length < 2)
            return null;

        const target = words[0].toLowerCase();
        const name = words[1].toLowerCase();
        const entry = entries.find(candidate => (candidate.shortName.toLowerCase() === target || candidate.target.toLowerCase() === target) && candidate.name.toLowerCase() === name);

        if (!entry)
            return null;

        const rest = words.slice(2);
        const count = entry.params.length;
        // The last parameter swallows the rest: "Tea break" stays one label.
        const args = count === 0 ? [] : rest.slice(0, count - 1).concat(rest.length >= count ? [rest.slice(count - 1).join(" ")] : []);

        return {
            entry: entry,
            args: args,
            ready: args.length === count
        };
    }

    // Void calls run detached (KIP closes, the target's panel takes focus);
    // anything that returns a value is waited for so KIP can show it.
    function call(entry, args) {
        const command = ipcBase().concat(["call", entry.target, entry.name]).concat(args || []);

        callLabel = entry.label + (args && args.length > 0 ? " " + args.join(" ") : "");

        if (entry.returns === "void") {
            detachedCall.command = command;
            detachedCall.startDetached();
            callStatus = "done";
            callOutput = "";
            return false;
        }

        callProcess.running = false;
        callStatus = "running";
        callOutput = "";
        callProcess.command = command;
        callProcess.running = true;
        return true;
    }

    function finishCall(exitCode, stdoutText, stderrText) {
        if (exitCode !== 0) {
            callStatus = "error";
            callOutput = String(stderrText || stdoutText || "").trim() || "exited " + exitCode;
            eventKey = "qreep.error";
            return;
        }

        callStatus = "done";
        callOutput = String(stdoutText || "").trim();
        eventKey = "qreep.called";
    }

    function updateToggleEntry() {
        const entry = exact && exact.entry.toggles ? exact.entry : null;

        toggleFilter = entry ? exact.args.join(" ").trim().toLowerCase() : "";

        if (entry !== toggleEntry) {
            toggleEntry = entry;
            toggleItems = [];
            toggleStatus = "idle";
            toggleError = "";
            if (entry)
                loadToggleState();
        }

        applyToggleFilter();
    }

    function applyToggleFilter() {
        toggleResults = toggleFilter.length > 0 ? toggleItems.filter(item => item.id.toLowerCase().indexOf(toggleFilter) >= 0) : toggleItems;
    }

    function loadToggleState() {
        if (!toggleEntry)
            return;

        const source = String(toggleEntry.toggles.stateFrom || "").split(".");

        toggleStateProcess.running = false;
        toggleStatus = "loading";
        toggleStateProcess.command = ipcBase().concat(["call", source[0], source.slice(1).join(".")]);
        toggleStateProcess.running = true;
    }

    function finishToggleState(exitCode, stdoutText, stderrText) {
        if (!toggleEntry)
            return;

        if (exitCode !== 0) {
            toggleStatus = "error";
            toggleError = String(stderrText || "").trim().split("\n")[0] || "state call exited " + exitCode;
            return;
        }

        toggleItems = parseToggleState(stdoutText, toggleEntry.toggles.stateKey || "");
        toggleStatus = "ready";
        toggleError = "";
        applyToggleFilter();
    }

    // "on  cpu-temp" / "off disk", or "clock visible=true pinned=false" with stateKey.
    function parseToggleState(text, stateKey) {
        const items = [];

        for (const line of String(text || "").split("\n")) {
            const onOff = /^\s*(on|off)\s+(\S+)/.exec(line);

            if (onOff) {
                items.push({ id: onOff[2], on: onOff[1] === "on" });
                continue;
            }

            const keyed = stateKey.length > 0 ? new RegExp("^\\s*(\\S+)\\s.*\\b" + stateKey + "=(true|false)\\b").exec(line) : null;

            if (keyed)
                items.push({ id: keyed[1], on: keyed[2] === "true" });
        }

        return items;
    }

    function flip(item) {
        if (!toggleEntry || !item || flipProcess.running)
            return;

        callLabel = toggleEntry.label + " " + item.id;
        flipProcess.command = ipcBase().concat(["call", toggleEntry.target, toggleEntry.name, item.id]);
        flipProcess.running = true;
    }

    function signature(entry) {
        return entry.label + (entry.params.length > 0 ? " " + entry.params.map(param => "<" + param.name + ">").join(" ") : "") + (entry.choices.length > 0 ? " · " + entry.choices.join(" · ") : "");
    }

    function reset() {
        showProcess.running = false;
        callProcess.running = false;
        status = "idle";
        entries = [];
        results = [];
        exact = null;
        errorText = "";
        eventKey = "";
        callStatus = "idle";
        callOutput = "";
        callLabel = "";
        showAll = false;
        toggleStateProcess.running = false;
        toggleEntry = null;
        toggleItems = [];
        toggleResults = [];
        toggleStatus = "idle";
        toggleError = "";
        toggleFilter = "";
    }

    function cancel() {
        showProcess.running = false;
        callProcess.running = false;
    }
}
