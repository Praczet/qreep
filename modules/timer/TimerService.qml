import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: rootTimerService

    readonly property string statePath: Quickshell.env("HOME") + "/.cache/qreep/timer/state.json"

    property var osd: null
    property string mode: "idle"
    property string label: ""
    property string notificationMode: "notify"
    property bool running: false
    property bool notified: false
    property real startedAt: 0
    property real targetAt: 0
    property real elapsedBeforePause: 0
    property int durationSeconds: 0
    property date currentTime: new Date()
    property string lastError: ""

    signal started

    readonly property bool hasState: mode === "timer" || mode === "countdown"
    readonly property bool isCountdown: mode === "countdown"
    readonly property bool done: isCountdown && hasState && remainingSeconds <= 0
    readonly property int elapsedSeconds: calculateElapsedSeconds()
    readonly property int remainingSeconds: calculateRemainingSeconds()
    readonly property real progress: calculateProgress()
    readonly property string displayText: hasState ? (isCountdown ? formatSeconds(Math.max(0, remainingSeconds)) : formatSeconds(elapsedSeconds)) : "00:00"
    readonly property string stateText: statusText()
    readonly property string labelText: label.length > 0 ? label : (isCountdown ? "Countdown" : "Timer")

    readonly property Process notifier: Process {}
    readonly property Process stateWriter: Process {
        stderr: StdioCollector {
            id: stateWriteStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                rootTimerService.lastError = "Timer state write failed: " + stateWriteStderr.text.trim();
        }
    }

    readonly property FileView stateFile: FileView {
        path: rootTimerService.statePath
        preload: true
        watchChanges: true

        onLoaded: rootTimerService.loadState()
        onTextChanged: rootTimerService.loadState()
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                rootTimerService.lastError = "Timer state load failed: " + FileViewError.toString(error);
        }
    }

    readonly property Timer tickTimer: Timer {
        interval: 1000
        repeat: true
        running: rootTimerService.hasState
        triggeredOnStart: true
        onTriggered: rootTimerService.tick()
    }

    function tick() {
        currentTime = new Date();

        if (isCountdown && remainingSeconds <= 0 && !notified) {
            running = false;
            notified = true;
            persistState();
            notifyDone();
        }
    }

    function startTimer(nextLabel): string {
        const now = Date.now();

        mode = "timer";
        label = cleanLabel(nextLabel, "Timer");
        running = true;
        notified = false;
        startedAt = now;
        targetAt = 0;
        elapsedBeforePause = 0;
        durationSeconds = 0;
        lastError = "";
        currentTime = new Date();
        persistState();
        started();
        return "started timer";
    }

    function startCountdown(durationText, nextLabel): string {
        const seconds = parseDuration(durationText);

        if (seconds <= 0) {
            lastError = "Use a duration like 25, 25m, 1h30m, or 45s.";
            return lastError;
        }

        const now = Date.now();

        mode = "countdown";
        label = cleanLabel(nextLabel, "Countdown");
        running = true;
        notified = false;
        startedAt = now;
        targetAt = now + seconds * 1000;
        elapsedBeforePause = 0;
        durationSeconds = seconds;
        lastError = "";
        currentTime = new Date();
        persistState();
        started();
        return "started countdown";
    }

    function startCountdownUntil(finishText, nextLabel): string {
        const finishAt = parseFinishAt(finishText);

        if (finishAt <= 0) {
            lastError = "Use finish-at time like 15:03 or 7:30.";
            return lastError;
        }

        const now = Date.now();
        const seconds = Math.max(1, Math.ceil((finishAt - now) / 1000));

        mode = "countdown";
        label = cleanLabel(nextLabel, "Countdown");
        running = true;
        notified = false;
        startedAt = now;
        targetAt = finishAt;
        elapsedBeforePause = 0;
        durationSeconds = seconds;
        lastError = "";
        currentTime = new Date();
        persistState();
        started();
        return "started countdown until " + finishText;
    }

    function pause(): string {
        if (!hasState || !running)
            return "not running";

        elapsedBeforePause = elapsedSeconds;
        running = false;
        currentTime = new Date();
        persistState();
        return "paused";
    }

    function resume(): string {
        if (!hasState || running || done)
            return "not paused";

        const now = Date.now();

        if (isCountdown)
            targetAt = now + Math.max(0, durationSeconds - elapsedBeforePause) * 1000;
        else
            startedAt = now;

        running = true;
        currentTime = new Date();
        persistState();
        return "resumed";
    }

    function toggleRunning(): string {
        if (!hasState)
            return "no timer";

        return running ? pause() : resume();
    }

    function stop(): string {
        mode = "idle";
        label = "";
        running = false;
        notified = false;
        startedAt = 0;
        targetAt = 0;
        elapsedBeforePause = 0;
        durationSeconds = 0;
        lastError = "";
        currentTime = new Date();
        persistState();
        return "stopped";
    }

    function setNotificationMode(nextMode): string {
        const normalized = normalizeNotificationMode(nextMode);

        notificationMode = normalized;
        persistState();
        return "notification mode: " + normalized;
    }

    function calculateElapsedSeconds() {
        if (!hasState)
            return 0;

        if (!running)
            return Math.max(0, Math.floor(elapsedBeforePause));

        return Math.max(0, Math.floor(elapsedBeforePause + (currentTime.getTime() - startedAt) / 1000));
    }

    function calculateRemainingSeconds() {
        if (!isCountdown)
            return 0;

        if (!running)
            return Math.max(0, durationSeconds - Math.floor(elapsedBeforePause));

        return Math.max(0, Math.ceil((targetAt - currentTime.getTime()) / 1000));
    }

    function calculateProgress() {
        if (!isCountdown || durationSeconds <= 0)
            return hasState ? 1 : 0;

        return Math.max(0, Math.min(1, elapsedSeconds / durationSeconds));
    }

    function statusText() {
        if (!hasState)
            return "idle";

        if (done)
            return "done";

        return running ? "running" : "paused";
    }

    function parseDuration(input) {
        const value = String(input || "").toLowerCase().replace(/\s+/g, "");

        if (value.length === 0)
            return -1;

        if (/^\d+$/.test(value))
            return Math.max(0, parseInt(value, 10) * 60);

        let total = 0;
        let index = 0;
        const token = /(\d+)([hms])/g;
        let match = token.exec(value);

        while (match) {
            if (match.index !== index)
                return -1;

            const amount = parseInt(match[1], 10);
            switch (match[2]) {
            case "h":
                total += amount * 3600;
                break;
            case "m":
                total += amount * 60;
                break;
            case "s":
                total += amount;
                break;
            }

            index = token.lastIndex;
            match = token.exec(value);
        }

        return index === value.length ? total : -1;
    }

    function parseFinishAt(input) {
        const value = String(input || "").trim();
        const match = /^(\d{1,2}):(\d{2})$/.exec(value);

        if (!match)
            return -1;

        const hours = parseInt(match[1], 10);
        const minutes = parseInt(match[2], 10);

        if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59)
            return -1;

        const now = new Date();
        const target = new Date(now.getTime());
        target.setHours(hours, minutes, 0, 0);

        if (target.getTime() <= now.getTime())
            target.setDate(target.getDate() + 1);

        return target.getTime();
    }

    function formatSeconds(totalSeconds) {
        const total = Math.max(0, Math.floor(totalSeconds));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        const seconds = total % 60;

        if (hours > 0)
            return pad2(hours) + ":" + pad2(minutes) + ":" + pad2(seconds);

        return pad2(minutes) + ":" + pad2(seconds);
    }

    function pad2(value) {
        return String(value).padStart(2, "0");
    }

    function cleanLabel(value, fallback) {
        const text = String(value || "").trim();
        return text.length > 0 ? text : fallback;
    }

    function notifyDone() {
        if (notificationMode === "osd" && osd) {
            osd.showMessage(labelText, 10000, "bottom", "Time's up", "alarm-symbolic", 128, -1);
            return;
        }

        notifier.running = false;
        notifier.command = [
            "notify-send",
            "--app-name=Qreep Timer",
            "--urgency=normal",
            "Timer done",
            labelText
        ];
        notifier.startDetached();
    }

    function loadState() {
        const contents = stateFile.text().trim();

        if (contents.length === 0)
            return;

        try {
            applyState(JSON.parse(contents));
            lastError = "";
        } catch (error) {
            lastError = "Timer state JSON error: " + error;
        }
    }

    function applyState(payload) {
        if (!payload || typeof payload !== "object")
            return;

        const nextMode = String(payload.mode || "idle");

        if (nextMode !== "timer" && nextMode !== "countdown" && nextMode !== "idle")
            return;

        mode = nextMode;
        label = String(payload.label || "");
        notificationMode = normalizeNotificationMode(payload.notificationMode || "notify");
        running = !!payload.running;
        notified = !!payload.notified;
        startedAt = numberValue(payload.startedAt, 0);
        targetAt = numberValue(payload.targetAt, 0);
        elapsedBeforePause = numberValue(payload.elapsedBeforePause, 0);
        durationSeconds = Math.max(0, Math.floor(numberValue(payload.durationSeconds, 0)));
        currentTime = new Date();
    }

    function persistState() {
        const state = {
            version: 1,
            mode: mode,
            label: label,
            notificationMode: notificationMode,
            running: running,
            notified: notified,
            startedAt: startedAt,
            targetAt: targetAt,
            elapsedBeforePause: elapsedBeforePause,
            durationSeconds: durationSeconds,
            savedAt: Date.now()
        };

        stateWriter.running = false;
        stateWriter.command = [
            "python3",
            "-c",
            "import json, os, sys\npath = sys.argv[1]\npayload = json.loads(sys.argv[2])\nos.makedirs(os.path.dirname(path), exist_ok=True)\nwith open(path, 'w', encoding='utf-8') as handle:\n    json.dump(payload, handle, indent=2)\n    handle.write('\\n')",
            statePath,
            JSON.stringify(state)
        ];
        stateWriter.running = true;
    }

    function numberValue(value, fallback) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function normalizeNotificationMode(value) {
        const text = String(value || "notify").trim().toLowerCase();
        return text === "osd" ? "osd" : "notify";
    }
}
