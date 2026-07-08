import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: rootBorgStatusService

    property var config: ({})
    property string state: "unknown"
    property string profile: ""
    property string archive: ""
    property string finishedAt: ""
    property int rc: -1
    property string message: ""
    property string error: ""

    readonly property string cacheDir: resolvePath(stringValue(config.cacheDir, "~/.cache/qreep/borg"))
    readonly property string statePath: resolvePath(stringValue(config.statePath, cacheDir + "/state.json"))
    readonly property string finalPath: resolvePath(stringValue(config.finalPath, cacheDir + "/final.json"))
    readonly property string statusText: displayStatus()
    readonly property string finishedText: formatDateTime(finishedAt)

    readonly property FileView stateFile: FileView {
        path: rootBorgStatusService.statePath
        preload: true
        watchChanges: true

        onLoaded: rootBorgStatusService.loadState()
        onTextChanged: rootBorgStatusService.loadState()
        onLoadFailed: error => {
            rootBorgStatusService.error = "Borg state load failed: " + FileViewError.toString(error);
            rootBorgStatusService.loadFinal();
        }
    }

    readonly property FileView finalFile: FileView {
        path: rootBorgStatusService.finalPath
        preload: true
        watchChanges: true

        onLoaded: rootBorgStatusService.loadFinal()
        onTextChanged: rootBorgStatusService.loadFinal()
        onLoadFailed: error => {
            if (rootBorgStatusService.archive.length === 0)
                rootBorgStatusService.error = "Borg final load failed: " + FileViewError.toString(error);
        }
    }

    function loadState() {
        const contents = stateFile.text().trim();

        if (contents.length === 0) {
            loadFinal();
            return;
        }

        try {
            applyState(JSON.parse(contents));
            error = "";
        } catch (loadError) {
            error = "Borg state JSON error: " + loadError;
            loadFinal();
        }
    }

    function loadFinal() {
        const contents = finalFile.text().trim();

        if (contents.length === 0)
            return;

        try {
            applyFinal(JSON.parse(contents));
            if (error.indexOf("final") >= 0)
                error = "";
        } catch (loadError) {
            if (archive.length === 0)
                error = "Borg final JSON error: " + loadError;
        }
    }

    function applyState(payload) {
        const stats = payload && payload.stats ? payload.stats : ({});
        const archiveStats = stats && stats.archive ? stats.archive : ({});

        state = stringValue(payload && payload.state, "unknown");
        profile = stringValue(payload && (payload.profile || payload.target), stringValue(stats && stats.profile, profile));
        archive = stringValue(payload && payload.archive, stringValue(archiveStats && archiveStats.name, archive));
        finishedAt = stringValue(payload && payload.finishedAt, stringValue(archiveStats && archiveStats.end, finishedAt));
        rc = numberValue(payload && payload.rc, rc);
        message = stringValue(payload && payload.message, "");
    }

    function applyFinal(payload) {
        const archivePayload = payload && payload.archive ? payload.archive : ({});

        if (profile.length === 0)
            profile = stringValue(payload && payload.profile, "");

        if (archive.length === 0)
            archive = stringValue(archivePayload.name, "");

        if (finishedAt.length === 0)
            finishedAt = stringValue(archivePayload.end, stringValue(payload && payload.finishedAt, ""));

        if (state === "unknown" && archive.length > 0)
            state = "success";

        if (rc < 0 && state === "success")
            rc = 0;
    }

    function displayStatus() {
        if (state === "success")
            return rc === 0 ? "Success" : "Finished";

        if (state === "running")
            return "Running";

        if (state === "error" || state === "failed")
            return "Failed";

        if (message.length > 0)
            return message;

        return "Unknown";
    }

    function formatDateTime(value) {
        const text = String(value || "");

        if (text.length === 0)
            return "Unknown";

        const date = new Date(text);

        if (Number.isNaN(date.getTime()))
            return text;

        return Qt.formatDateTime(date, "ddd, dd MMM yyyy HH:mm");
    }

    function resolvePath(path) {
        const text = String(path || "");

        if (text === "~")
            return Quickshell.env("HOME") || text;

        if (text.indexOf("~/") === 0)
            return (Quickshell.env("HOME") || "") + text.slice(1);

        return text;
    }

    function stringValue(value, fallback) {
        return typeof value === "string" && value.length > 0 ? value : fallback;
    }

    function numberValue(value, fallback) {
        const numeric = Number(value);
        return Number.isFinite(numeric) ? numeric : fallback;
    }
}
