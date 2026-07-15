import QtQuick
import Quickshell.Io
import "../../core" as Core

QtObject {
    id: rootFastPasswordService

    required property QtObject theme
    property QtObject log
    property string searchText: ""
    property var entries: []
    property var filteredEntries: []
    property int selectedIndex: filteredEntries.length > 0 ? 0 : -1
    property bool authenticating: false
    property bool loading: false
    property bool copying: false
    property string error: ""
    property string status: ""
    property string currentCopyEntry: ""

    signal openAuthorized

    readonly property string authCommand: "qreep-pass-auth"
    readonly property string listCommand: "qreep-pass-list"
    readonly property string copyCommand: "qreep-pass-copy"
    readonly property Core.Log fallbackLog: Core.Log {}

    onSearchTextChanged: applyFilter()

    readonly property Process authRunner: Process {
        id: authRunner

        stdout: StdioCollector {
            id: authStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: authStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootFastPasswordService.applyAuthOutput(authStdout.text, authStderr.text, exitCode)
    }

    readonly property Process listRunner: Process {
        id: listRunner

        stdout: StdioCollector {
            id: listStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: listStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootFastPasswordService.applyListOutput(listStdout.text, listStderr.text, exitCode)
    }

    readonly property Process copyRunner: Process {
        id: copyRunner

        stdout: StdioCollector {
            id: copyStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: copyStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootFastPasswordService.applyCopyOutput(copyStdout.text, copyStderr.text, exitCode)
    }

    function requestOpen() {
        if (authRunner.running)
            return;

        authenticating = true;
        error = "";
        status = "authenticating";
        authRunner.command = [authCommand];
        authRunner.running = true;
    }

    function applyAuthOutput(stdout, stderr, exitCode) {
        authenticating = false;

        if (exitCode !== 0) {
            reportError("Fast password auth failed:", stderr.length > 0 ? stderr : authCommand + " returned " + exitCode);
            return;
        }

        status = "authenticated";
        openAuthorized();
    }

    function refresh() {
        if (listRunner.running)
            return;

        loading = true;
        error = "";
        status = "";
        listRunner.command = [listCommand];
        listRunner.running = true;
    }

    function applyListOutput(stdout, stderr, exitCode) {
        loading = false;

        if (exitCode !== 0) {
            entries = [];
            filteredEntries = [];
            selectedIndex = -1;
            reportError("Fast password list failed:", stderr.length > 0 ? stderr : listCommand + " returned " + exitCode);
            return;
        }

        const parsedEntries = [];
        const seen = {};
        const lines = String(stdout || "").split("\n");

        for (let index = 0; index < lines.length; index++) {
            const name = lines[index].trim();

            if (name.length === 0 || seen[name])
                continue;

            seen[name] = true;
            parsedEntries.push(normalizeEntry(name, parsedEntries.length));
        }

        entries = parsedEntries;
        applyFilter();
        status = parsedEntries.length + " entries";
    }

    function normalizeEntry(name, index) {
        const parts = name.split("/").filter(part => part.length > 0);
        const label = parts.length > 0 ? parts[parts.length - 1] : name;
        const group = parts.length > 1 ? parts.slice(0, -1).join("/") : "Vault";

        return {
            name,
            label,
            group,
            icon: iconForEntry(name, group, label),
            listIndex: index
        };
    }

    function applyFilter() {
        const needle = searchText.trim().toLowerCase();
        let nextEntries = entries;

        if (needle.length > 0) {
            nextEntries = nextEntries.filter(entry => {
                const haystack = (entry.name + " " + entry.group + " " + entry.label).toLowerCase();
                return haystack.indexOf(needle) !== -1;
            });
        }

        filteredEntries = nextEntries;
        clampSelection();
    }

    function clampSelection() {
        if (filteredEntries.length === 0) {
            selectedIndex = -1;
            return;
        }

        if (selectedIndex < 0)
            selectedIndex = 0;
        else if (selectedIndex >= filteredEntries.length)
            selectedIndex = filteredEntries.length - 1;
    }

    function copy(index) {
        const entry = entryAt(index);

        if (!entry)
            return false;

        return copyEntryName(entry.name) === "copy requested";
    }

    function copyEntryName(entryName) {
        const normalizedName = String(entryName || "").trim();

        if (normalizedName.length === 0)
            return "missing entry";

        currentCopyEntry = normalizedName;
        copying = true;
        error = "";
        status = "copy requested";
        copyRunner.running = false;
        copyRunner.command = [copyCommand, normalizedName];
        copyRunner.running = true;
        return "copy requested";
    }

    function applyCopyOutput(stdout, stderr, exitCode) {
        copying = false;

        if (exitCode !== 0) {
            reportError("Fast password copy failed:", stderr.length > 0 ? stderr : copyCommand + " returned " + exitCode);
            currentCopyEntry = "";
            return;
        }

        status = currentCopyEntry.length > 0 ? "copied " + currentCopyEntry : "copied";
        currentCopyEntry = "";
    }

    function entryAt(index) {
        if (index < 0 || index >= filteredEntries.length)
            return null;

        return filteredEntries[index];
    }

    function moveSelection(offset) {
        if (filteredEntries.length === 0)
            return;

        selectedIndex = Math.max(0, Math.min(filteredEntries.length - 1, selectedIndex + offset));
    }

    function setSelection(index) {
        if (filteredEntries.length === 0) {
            selectedIndex = -1;
            return;
        }

        selectedIndex = Math.max(0, Math.min(filteredEntries.length - 1, index));
    }

    function iconForEntry(name, group, label) {
        const lower = (name + " " + group + " " + label).toLowerCase();

        if (lower.indexOf("db") !== -1 || lower.indexOf("database") !== -1)
            return "󰆼";
        if (lower.indexOf("nas") !== -1 || lower.indexOf("server") !== -1 || lower.indexOf("borg") !== -1)
            return "󰒋";
        if (lower.indexOf("license") !== -1)
            return "󰌆";
        if (lower.indexOf("work") !== -1)
            return "󰌢";
        if (lower.indexOf("mail") !== -1 || lower.indexOf("email") !== -1)
            return "󰇮";
        if (lower.indexOf("bank") !== -1 || lower.indexOf("card") !== -1)
            return "󰄰";

        return "󰌾";
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
