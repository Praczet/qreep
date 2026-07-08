import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: rootBloomStatusService

    property string cacheDir: resolvePath("~/.cache/unclaimed-bloom")
    property string profile: ""
    property string wallpaper: ""
    property string activeStage: ""
    property string overallStatus: "idle"
    property string error: ""
    property bool visibleRequested: false
    property string lastTerminalKey: ""
    property var stages: ({
        sow: emptyStage("sow"),
        grow: emptyStage("grow"),
        plant: emptyStage("plant")
    })

    readonly property string statePath: cacheDir + "/state.json"
    readonly property string sowPath: cacheDir + "/state-sow.json"
    readonly property string growPath: cacheDir + "/state-grow.json"
    readonly property string plantPath: cacheDir + "/state-plant.json"
    readonly property string wallpaperPath: cacheDir + "/current-wallpaper"
    readonly property string profilePath: cacheDir + "/current-profile"
    readonly property bool running: overallStatus === "running"
    readonly property bool terminal: overallStatus === "done" || overallStatus === "error"
    readonly property string updatedAt: latestUpdatedAt()

    signal terminalStateReached

    readonly property FileView stateFile: FileView {
        path: rootBloomStatusService.statePath
        preload: true
        watchChanges: true

        onLoaded: rootBloomStatusService.loadState()
        onTextChanged: rootBloomStatusService.loadState()
        onLoadFailed: error => rootBloomStatusService.error = "Bloom state load failed: " + FileViewError.toString(error)
    }

    readonly property FileView sowFile: FileView {
        path: rootBloomStatusService.sowPath
        preload: true
        watchChanges: true

        onLoaded: rootBloomStatusService.loadStage("sow", text())
        onTextChanged: rootBloomStatusService.loadStage("sow", text())
    }

    readonly property FileView growFile: FileView {
        path: rootBloomStatusService.growPath
        preload: true
        watchChanges: true

        onLoaded: rootBloomStatusService.loadStage("grow", text())
        onTextChanged: rootBloomStatusService.loadStage("grow", text())
    }

    readonly property FileView plantFile: FileView {
        path: rootBloomStatusService.plantPath
        preload: true
        watchChanges: true

        onLoaded: rootBloomStatusService.loadStage("plant", text())
        onTextChanged: rootBloomStatusService.loadStage("plant", text())
    }

    readonly property FileView wallpaperFile: FileView {
        path: rootBloomStatusService.wallpaperPath
        preload: true
        watchChanges: true

        onLoaded: rootBloomStatusService.loadWallpaper()
        onTextChanged: rootBloomStatusService.loadWallpaper()
    }

    readonly property FileView profileFile: FileView {
        path: rootBloomStatusService.profilePath
        preload: true
        watchChanges: true

        onLoaded: rootBloomStatusService.loadCurrentProfile()
        onTextChanged: rootBloomStatusService.loadCurrentProfile()
    }

    function reload() {
        stateFile.reload();
        sowFile.reload();
        growFile.reload();
        plantFile.reload();
        wallpaperFile.reload();
        profileFile.reload();
    }

    function show(profileName, wallpaperPath) {
        if (profileName && String(profileName).length > 0)
            profile = String(profileName);

        if (wallpaperPath && String(wallpaperPath).length > 0)
            wallpaper = String(wallpaperPath);

        visibleRequested = true;
        lastTerminalKey = "";
        reload();
    }

    function done() {
        overallStatus = "done";
        visibleRequested = true;
        terminalStateReached();
    }

    function hide() {
        visibleRequested = false;
    }

    function recover() {
        reload();
        visibleRequested = running || recentlyUpdated(updatedAt);
    }

    function loadState() {
        const contents = stateFile.text().trim();

        if (contents.length === 0)
            return;

        try {
            applyRunState(JSON.parse(contents), true);
            error = "";
        } catch (loadError) {
            error = "Bloom state JSON error: " + loadError;
        }
    }

    function loadStage(stage, contents) {
        const text = String(contents || "").trim();

        if (text.length === 0)
            return;

        try {
            applyRunState(JSON.parse(text), false);
        } catch (loadError) {
            // Stage snapshots are best-effort progress memory. Ignore half-written old junk.
        }
    }

    function applyRunState(payload, isCurrent) {
        const stage = String(payload && payload.stage || "");

        if (stage !== "sow" && stage !== "grow" && stage !== "plant")
            return;

        const normalizedStage = normalizeStage(stage, payload);
        const nextStages = Object.assign({}, stages);
        nextStages[stage] = normalizedStage;
        stages = nextStages;

        if (!isCurrent)
            return;

        const nextStatus = String(payload.status || "");
        const shouldShowTerminal = visibleRequested || recentlyUpdated(payload.updated_at);

        profile = stringValue(payload.profile, profile);
        activeStage = normalizedStage.status === "running" ? stage : activeStage;
        overallStatus = nextStatus === "running" || normalizedStage.status === "running" ? "running"
            : (nextStatus === "error" ? "error" : "done");
        visibleRequested = running || (terminal && shouldShowTerminal);

        if (running)
            lastTerminalKey = "";

        const terminalKey = String(payload.run_id || "") + ":" + stage + ":" + overallStatus + ":" + stringValue(payload.updated_at, "");
        if (terminal && visibleRequested && terminalKey !== lastTerminalKey) {
            lastTerminalKey = terminalKey;
            terminalStateReached();
        }
    }

    function loadWallpaper() {
        const text = wallpaperFile.text().trim();

        if (text.length > 0)
            wallpaper = text;
    }

    function loadCurrentProfile() {
        if (profile.length > 0)
            return;

        const text = profileFile.text().trim();

        if (text.length > 0)
            profile = text;
    }

    function normalizeStage(stage, payload) {
        const targets = payload && payload.targets ? payload.targets : ({});
        const hasRunningTarget = targetIsRunning(targets);

        return {
            name: stage,
            status: payload.status === "running" || hasRunningTarget ? "running" : (payload.status === "error" ? "error" : "done"),
            startedAt: stringValue(payload.started_at, ""),
            updatedAt: stringValue(payload.updated_at, ""),
            targets: targets,
            targetCount: Object.keys(targets).length,
            doneCount: countDoneTargets(targets),
            currentTarget: currentTarget(targets),
            worker: activeWorker(targets)
        };
    }

    function emptyStage(stage) {
        return {
            name: stage,
            status: "pending",
            startedAt: "",
            updatedAt: "",
            targets: ({}),
            targetCount: 0,
            doneCount: 0,
            currentTarget: "",
            worker: null
        };
    }

    function countDoneTargets(targets) {
        let count = 0;

        for (const target of Object.values(targets)) {
            if (target.status === "done" || target.status === "skipped" || target.status === "error")
                count++;
        }

        return count;
    }

    function targetIsRunning(targets) {
        for (const target of Object.values(targets)) {
            if (target.status === "running")
                return true;

            if (target.worker) {
                const pct = Number(target.worker.pct);

                if (!Number.isFinite(pct) || pct < 1)
                    return true;
            }
        }

        return false;
    }

    function currentTarget(targets) {
        for (const [name, target] of Object.entries(targets)) {
            if (target.status === "running")
                return name;
        }

        return "";
    }

    function activeWorker(targets) {
        for (const target of Object.values(targets)) {
            if (target.worker)
                return target.worker;
        }

        return null;
    }

    function latestUpdatedAt() {
        let latest = "";

        for (const stage of ["sow", "grow", "plant"]) {
            const value = stages[stage].updatedAt || "";
            if (value.length > 0 && (latest.length === 0 || new Date(value).getTime() > new Date(latest).getTime()))
                latest = value;
        }

        return latest;
    }

    function recentlyUpdated(value) {
        const date = new Date(String(value || ""));

        if (Number.isNaN(date.getTime()))
            return false;

        return Date.now() - date.getTime() < 120000;
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

    Component.onCompleted: recover()
}
