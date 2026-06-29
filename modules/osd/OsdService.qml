import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: rootOsdService

    required property QtObject theme

    signal messageRequested(var message, var durationMs, var position, var title, var icon, var iconSize, var progress)
    signal hideRequested()

    property string pendingAudioKind
    property string pendingPlayerAction

    readonly property IpcHandler ipcHandler: IpcHandler {
        target: "osd"

        function showMessage(message: string, durationMs: string) {
            rootOsdService.showMessage(message, durationMs);
        }

        function showJSON(payload: string) {
            rootOsdService.showJSON(payload);
        }

        function hideMessage() {
            rootOsdService.hideRequested();
        }

        function osdVolume(value: string, muted: string) {
            rootOsdService.showVolume(value, muted);
        }

        function osdMic(value: string, muted: string) {
            rootOsdService.showMic(value, muted);
        }

        function osdBrightness(value: string) {
            rootOsdService.showBrightness(value);
        }

        function osdPlayer(action: string) {
            rootOsdService.showPlayer(action);
        }

        function osdPlayerCtl(action: string) {
            rootOsdService.showPlayer(action);
        }
    }

    readonly property Process audioRunner: Process {
        id: audioRunner

        stdout: StdioCollector {
            id: audioStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: audioStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootOsdService.applyAudioOutput(audioStdout.text, audioStderr.text, exitCode)
    }

    readonly property Process playerRunner: Process {
        id: playerRunner

        stdout: StdioCollector {
            id: playerStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: playerStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootOsdService.applyPlayerOutput(playerStdout.text, playerStderr.text, exitCode)
    }

    readonly property Timer playerQueryDelay: Timer {
        id: playerQueryDelay

        interval: rootOsdService.theme.modules.osd.playerQueryDelay
        repeat: false
        onTriggered: rootOsdService.queryPlayer()
    }

    function showMessage(message, durationMs, position, title, icon, iconSize, progress) {
        rootOsdService.messageRequested(message, durationMs, position, title, icon, iconSize, progress);
    }

    function showJSON(payload) {
        try {
            const request = JSON.parse(payload);

            if (!request.message) {
                throw new Error("Missing required fields");
            }

            showMessage(request.message, request.durationMs || theme.modules.osd.defaultDuration, request.position || theme.modules.osd.defaultPosition, request.title || "", request.icon || "", request.iconSize || theme.modules.osd.iconSize, request.progress);
        } catch (e) {
            showMessage("Invalid JSON payload", theme.modules.osd.defaultDuration);
        }
    }

    function showVolume(value, muted) {
        const parsedValue = parseOptionalPercent(value);

        if (parsedValue !== null) {
            applyAudioState("volume", parsedValue, parseMuted(muted));
            return;
        }

        queryAudio("volume", "@DEFAULT_AUDIO_SINK@");
    }

    function showMic(value, muted) {
        const parsedValue = parseOptionalPercent(value);

        if (parsedValue !== null) {
            applyAudioState("mic", parsedValue, parseMuted(muted));
            return;
        }

        queryAudio("mic", "@DEFAULT_AUDIO_SOURCE@");
    }

    function showBrightness(value) {
        const parsedValue = parseOptionalPercent(value);

        if (parsedValue === null) {
            showMessage("Brightness unavailable", theme.modules.osd.defaultDuration, theme.modules.osd.defaultPosition, "Brightness", brightnessIcon(0), theme.modules.osd.progressIconSize);
            return;
        }

        showProgressMessage("Brightness", percentText(parsedValue), brightnessIcon(parsedValue), parsedValue / 100);
    }

    function showPlayer(action) {
        pendingPlayerAction = normalizePlayerAction(action);

        if (pendingPlayerAction === "next" || pendingPlayerAction === "prev") {
            playerQueryDelay.restart();
            return;
        }

        queryPlayer();
    }

    function showProgressMessage(title, message, icon, progress) {
        showMessage(message, theme.modules.osd.defaultDuration, theme.modules.osd.defaultPosition, title, icon, theme.modules.osd.progressIconSize, progress);
    }

    function queryAudio(kind, target) {
        pendingAudioKind = kind;
        audioRunner.running = false;
        audioRunner.command = ["wpctl", "get-volume", target];
        audioRunner.running = true;
    }

    function applyAudioOutput(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0) {
            showMessage(audioTitle(pendingAudioKind) + " unavailable", theme.modules.osd.defaultDuration, theme.modules.osd.defaultPosition, audioTitle(pendingAudioKind), audioIcon(pendingAudioKind, 0, false), theme.modules.osd.progressIconSize);
            return;
        }

        const parsed = parseWpctlVolume(stdoutText);
        applyAudioState(pendingAudioKind, parsed.value, parsed.muted);
    }

    function applyAudioState(kind, value, muted) {
        const title = audioTitle(kind) + (muted ? " (Muted)" : "");

        showProgressMessage(title, percentText(value), audioIcon(kind, value, muted), value / 100);
    }

    function queryPlayer() {
        playerRunner.running = false;
        playerRunner.command = ["playerctl", "metadata", "--format", "{{playerName}}\n{{status}}\n{{title}}\n{{artist}}\n{{album}}"];
        playerRunner.running = true;
    }

    function applyPlayerOutput(stdoutText, stderrText, exitCode) {
        const fallbackIcon = playerActionIcon(pendingPlayerAction, "");

        if (exitCode !== 0) {
            showMessage(playerActionTitle(pendingPlayerAction), theme.modules.osd.defaultDuration, theme.modules.osd.defaultPosition, "Player", fallbackIcon, theme.modules.osd.progressIconSize);
            return;
        }

        const meta = parsePlayerMetadata(stdoutText);
        const title = meta.title || playerActionTitle(pendingPlayerAction);
        const artist = meta.artist || meta.player || "";
        const status = meta.status || "";
        const icon = playerActionIcon(pendingPlayerAction, status);

        showMessage(artist, theme.modules.osd.defaultDuration, theme.modules.osd.defaultPosition, title, icon, theme.modules.osd.progressIconSize);
    }

    function parseOptionalPercent(value) {
        const text = String(value || "").trim().replace("%", "");

        if (text.length === 0)
            return null;

        const parsed = Number(text);

        if (!Number.isFinite(parsed))
            return null;

        return Math.max(0, Math.min(150, Math.round(parsed)));
    }

    function parseWpctlVolume(output) {
        const text = String(output || "");
        const match = text.match(/([0-9]+(?:\.[0-9]+)?)/);
        const value = match ? Math.max(0, Math.min(150, Math.round(Number(match[1]) * 100))) : 0;

        return {
            value: value,
            muted: /\bMUTED\b/i.test(text)
        };
    }

    function parseMuted(value) {
        const text = String(value || "").trim().toLowerCase();

        return text === "true" || text === "1" || text === "muted" || text === "yes";
    }

    function parsePlayerMetadata(output) {
        const lines = String(output || "").split(/\r?\n/);

        return {
            player: lines[0] || "",
            status: lines[1] || "",
            title: lines[2] || "",
            artist: normalizePlayerArray(lines[3] || ""),
            album: lines[4] || ""
        };
    }

    function normalizePlayerArray(value) {
        const text = String(value || "").trim();

        if (!text.startsWith("["))
            return text;

        try {
            const parsed = JSON.parse(text.replace(/'/g, "\""));

            if (Array.isArray(parsed))
                return parsed.join(", ");
        } catch (e) {
            return text;
        }

        return text;
    }

    function percentText(value) {
        return Math.round(value) + "%";
    }

    function audioTitle(kind) {
        return kind === "mic" ? "Microphone" : "Volume";
    }

    function audioIcon(kind, value, muted) {
        if (kind === "mic")
            return muted ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic";

        return volumeIcon(value, muted);
    }

    function volumeIcon(value, muted) {
        if (muted || value <= 0)
            return "audio-volume-muted-symbolic";

        if (value >= 85)
            return "audio-volume-overamplified-symbolic";

        if (value >= 67)
            return "audio-volume-high-symbolic";

        if (value >= 34)
            return "audio-volume-medium-symbolic";

        return "audio-volume-low-symbolic";
    }

    function brightnessIcon(value) {
        return value >= 85 ? "weather-clear-symbolic" : "display-brightness-symbolic";
    }

    function normalizePlayerAction(action) {
        const text = String(action || "play-pause").trim().toLowerCase();

        if (text === "previous")
            return "prev";

        if (text === "pause" || text === "play" || text === "play-pause" || text === "next" || text === "prev")
            return text;

        return "play-pause";
    }

    function playerActionIcon(action, status) {
        if (action === "next")
            return "media-skip-forward-symbolic";

        if (action === "prev")
            return "media-skip-backward-symbolic";

        return String(status || "").toLowerCase() === "playing" ? "media-playback-start-symbolic" : "media-playback-pause-symbolic";
    }

    function playerActionTitle(action) {
        if (action === "next")
            return "Next track";

        if (action === "prev")
            return "Previous track";

        if (action === "pause")
            return "Paused";

        if (action === "play")
            return "Playing";

        return "Play pause";
    }
}
