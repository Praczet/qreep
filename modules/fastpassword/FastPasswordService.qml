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
    property string authPurpose: "open"
    property string pendingCopyEntry: ""
    property var pendingCopyCommand: []

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

        authPurpose = "open";
        authenticating = true;
        error = "";
        status = "authenticating";
        authRunner.command = [authCommand];
        authRunner.running = true;
    }

    function applyAuthOutput(stdout, stderr, exitCode) {
        authenticating = false;

        if (exitCode !== 0) {
            if (authPurpose === "copy") {
                status = "copy authentication cancelled";
                pendingCopyCommand = [];
                pendingCopyEntry = "";
                currentCopyEntry = "";
                authPurpose = "open";
                (log || fallbackLog).info("Fast password copy authentication did not complete");
                return;
            }

            reportError("Fast password auth failed:", processMessage(stderr, authCommand + " returned " + exitCode));
            return;
        }

        status = "authenticated";

        if (authPurpose === "copy") {
            retryPendingCopy();
            return;
        }

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
            reportError("Fast password list failed:", processMessage(stderr, listCommand + " returned " + exitCode));
            return;
        }

        const parsedEntries = parseEntries(stdout);

        entries = parsedEntries;
        applyFilter();
        status = parsedEntries.length + " entries";
    }

    function parseEntries(stdout) {
        const text = String(stdout || "").trim();
        const parsedEntries = [];
        const seen = {};

        if (text.length === 0)
            return parsedEntries;

        try {
            const jsonEntries = JSON.parse(text);

            if (!Array.isArray(jsonEntries))
                throw new Error("qreep-pass-list returned non-array JSON");

            for (let index = 0; index < jsonEntries.length; index++) {
                const entry = normalizeEntryObject(jsonEntries[index], parsedEntries.length);

                if (!entry)
                    continue;

                const identity = entry.source + ":" + entry.key;

                if (seen[identity])
                    continue;

                seen[identity] = true;
                parsedEntries.push(entry);
            }

            return parsedEntries;
        } catch (error) {
            const lines = text.split("\n");

            for (let index = 0; index < lines.length; index++) {
                const name = lines[index].trim();

                if (name.length === 0 || seen[name])
                    continue;

                seen[name] = true;
                parsedEntries.push(normalizeLegacyEntry(name, parsedEntries.length));
            }

            return parsedEntries;
        }
    }

    function normalizeLegacyEntry(name, index) {
        const parts = name.split("/").filter(part => part.length > 0);
        const label = parts.length > 0 ? parts[parts.length - 1] : name;
        const group = parts.length > 1 ? parts.slice(0, -1).join("/") : "Vault";

        return {
            name,
            displayName: label,
            key: name,
            source: "keepass",
            label,
            group,
            desc: "",
            icon: iconForEntry(name, group, label, "", "keepass"),
            listIndex: index
        };
    }

    function normalizeEntryObject(rawEntry, index) {
        if (!rawEntry || typeof rawEntry !== "object")
            return null;

        const source = normalizeSource(rawEntry.source || "keepass");
        const key = String(rawEntry.key || rawEntry.name || "").trim();

        if (key.length === 0)
            return null;

        const name = String(rawEntry.name || key).trim();
        const displayName = String(rawEntry.displayName || rawEntry.label || labelFromKey(key)).trim();
        const desc = String(rawEntry.desc || "").trim();
        const sourceLabel = sourceDisplayName(source);
        const group = desc.length > 0 ? sourceLabel + " · " + desc : sourceLabel + " · " + key;

        return {
            name,
            displayName,
            key,
            source,
            label: displayName,
            group,
            desc,
            icon: iconForEntry(name, group, displayName, String(rawEntry.icon || ""), source),
            listIndex: index
        };
    }

    function applyFilter() {
        const needle = searchText.trim().toLowerCase();
        let nextEntries = entries;

        if (needle.length > 0) {
            nextEntries = nextEntries.filter(entry => {
                const haystack = (entry.name + " " + entry.group + " " + entry.label + " " + entry.key + " " + entry.source + " " + entry.desc).toLowerCase();
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

        return copyEntry(entry) === "copy requested";
    }

    function copyEntry(entry) {
        if (!entry)
            return "missing entry";

        return startCopy([copyCommand, "--source", entry.source, "--key", entry.key], entry.label || entry.displayName || entry.key);
    }

    function copyEntryName(entryName) {
        const normalizedName = String(entryName || "").trim();

        if (normalizedName.length === 0)
            return "missing entry";

        return startCopy([copyCommand, normalizedName], normalizedName);
    }

    function startCopy(command, label) {
        currentCopyEntry = label;
        pendingCopyEntry = label;
        pendingCopyCommand = command;
        copying = true;
        error = "";
        status = "copy requested";
        copyRunner.running = false;
        copyRunner.command = command;
        copyRunner.running = true;
        return "copy requested";
    }

    function applyCopyOutput(stdout, stderr, exitCode) {
        copying = false;

        if (exitCode !== 0) {
            if (exitCode === 6) {
                requestCopyAuthentication();
                return;
            }

            if (exitCode === 9) {
                reportWarning("Fast password provider needs attention:", processMessage(stderr, copyCommand + " returned " + exitCode));
                currentCopyEntry = "";
                pendingCopyCommand = [];
                pendingCopyEntry = "";
                return;
            }

            reportError("Fast password copy failed:", processMessage(stderr, copyCommand + " returned " + exitCode));
            currentCopyEntry = "";
            pendingCopyCommand = [];
            pendingCopyEntry = "";
            return;
        }

        status = currentCopyEntry.length > 0 ? "copied " + currentCopyEntry : "copied";
        currentCopyEntry = "";
        pendingCopyCommand = [];
        pendingCopyEntry = "";
    }

    function requestCopyAuthentication() {
        if (pendingCopyCommand.length === 0) {
            status = "authentication required";
            currentCopyEntry = "";
            return;
        }

        if (authRunner.running)
            return;

        authPurpose = "copy";
        authenticating = true;
        error = "";
        status = "authentication required";
        authRunner.command = [authCommand];
        authRunner.running = true;
    }

    function retryPendingCopy() {
        const command = pendingCopyCommand;
        const label = pendingCopyEntry;

        authPurpose = "open";

        if (!command || command.length === 0) {
            status = "authenticated";
            return;
        }

        currentCopyEntry = label;
        copying = true;
        error = "";
        status = "copy requested";
        copyRunner.running = false;
        copyRunner.command = command;
        copyRunner.running = true;
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

    function normalizeSource(source) {
        const normalizedSource = String(source || "keepass").trim().toLowerCase();

        if (normalizedSource === "gnome" || normalizedSource === "gnomering" || normalizedSource === "gnome-ring" || normalizedSource === "keyring")
            return "gnome-keyring";

        if (normalizedSource === "protonpass" || normalizedSource === "proton-pass")
            return "proton";

        return normalizedSource.length > 0 ? normalizedSource : "keepass";
    }

    function sourceDisplayName(source) {
        if (source === "keepass")
            return "KeePass";
        if (source === "proton")
            return "Proton";
        if (source === "gnome-keyring")
            return "GNOME Keyring";

        return source;
    }

    function labelFromKey(key) {
        const parts = String(key || "").split("/").filter(part => part.length > 0);

        return parts.length > 0 ? parts[parts.length - 1] : String(key || "");
    }

    function iconForEntry(name, group, label, icon, source) {
        const normalizedIcon = String(icon || "").trim().toLowerCase();

        if (normalizedIcon === "database" || normalizedIcon === "db")
            return "󰆼";
        if (normalizedIcon === "server" || normalizedIcon === "nas")
            return "󰒋";
        if (normalizedIcon === "mail" || normalizedIcon === "email")
            return "󰇮";
        if (normalizedIcon === "bank" || normalizedIcon === "card")
            return "󰄰";
        if (normalizedIcon === "work")
            return "󰌢";
        if (normalizedIcon === "proton")
            return "󰕥";
        if (normalizedIcon === "keyring" || normalizedIcon === "key" || normalizedIcon === "keepass")
            return "󰌾";
        if (icon.length > 0 && icon.length <= 2)
            return icon;

        if (source === "proton")
            return "󰕥";
        if (source === "gnome-keyring")
            return "󰌾";

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

    function reportWarning() {
        error = messageText(arguments);
        status = error;
        (log || fallbackLog).warn(error);
    }

    function processMessage(message, fallback) {
        const cleaned = cleanTerminalText(String(message || "")).trim();

        return cleaned.length > 0 ? cleaned : fallback;
    }

    function messageText(messages) {
        const parts = [];

        for (let index = 0; index < messages.length; index++)
            parts.push(cleanTerminalText(String(messages[index])).trim());

        return parts.join(" ");
    }

    function cleanTerminalText(message) {
        return String(message || "").replace(/\x1b\[[0-9;]*m/g, "").replace(/\[[0-9;]*m/g, "");
    }
}
