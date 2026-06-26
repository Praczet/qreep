import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: rootOsd

    required property QtObject theme

    property string icon
    property string title
    property string message
    property bool active: false
    property string position: theme.osd.defaultPosition
    property int iconSize: theme.osd.iconSize
    property real progress: -1
    property string pendingAudioKind
    property string pendingPlayerAction
    readonly property string normalizedPosition: normalizePosition(position)
    readonly property bool isBottomPosition: normalizedPosition.indexOf("bottom") === 0
    readonly property bool isLeftPosition: normalizedPosition.indexOf("left") !== -1
    readonly property bool isRightPosition: normalizedPosition.indexOf("right") !== -1
    readonly property bool hasIcon: icon.length > 0
    readonly property bool hasTitle: title.length > 0
    readonly property bool hasProgress: progress >= 0
    readonly property real clampedProgress: Math.max(0, Math.min(1, progress))
    readonly property int activeIconSize: hasProgress ? theme.osd.progressIconSize : iconSize
    readonly property int maxTextWidth: Math.max(1, width - theme.osd.screenPadding * 2 - theme.osd.horizontalPadding * 2 - (hasIcon ? activeIconSize + theme.osd.contentSpacing : 0))

    IpcHandler {
        target: "osd"

        function showMessage(message: string, durationMs: string) {
            rootOsd.showMessage(message, durationMs);
        }

        function showJSON(payload: string) {
            try {
                const request = JSON.parse(payload);

                if (!request.message) {
                    throw new Error("Missing required fields");
                }

                rootOsd.showMessage(request.message, request.durationMs || rootOsd.theme.osd.defaultDuration, request.position || rootOsd.theme.osd.defaultPosition, request.title || "", request.icon || "", request.iconSize || rootOsd.theme.osd.iconSize, request.progress);
            } catch (e) {
                rootOsd.showMessage("Invalid JSON payload", rootOsd.theme.osd.defaultDuration);
            }
        }

        function hideMessage() {
            rootOsd.hideMessage();
        }

        function osdVolume(value: string, muted: string) {
            rootOsd.showVolume(value, muted);
        }

        function osdMic(value: string, muted: string) {
            rootOsd.showMic(value, muted);
        }

        function osdBrightness(value: string) {
            rootOsd.showBrightness(value);
        }

        function osdPlayer(action: string) {
            rootOsd.showPlayer(action);
        }

        function osdPlayerCtl(action: string) {
            rootOsd.showPlayer(action);
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

        onExited: (exitCode, exitStatus) => rootOsd.applyAudioOutput(audioStdout.text, audioStderr.text, exitCode)
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

        onExited: (exitCode, exitStatus) => rootOsd.applyPlayerOutput(playerStdout.text, playerStderr.text, exitCode)
    }

    Timer {
        id: playerQueryDelay

        interval: rootOsd.theme.osd.playerQueryDelay
        repeat: false
        onTriggered: rootOsd.queryPlayer()
    }

    function normalizePosition(position) {
        const requestedPosition = String(position || rootOsd.theme.osd.defaultPosition).toLowerCase();
        const allowedPositions = ["top", "top-left", "top-right", "bottom", "bottom-left", "bottom-right"];

        return allowedPositions.indexOf(requestedPosition) >= 0 ? requestedPosition : rootOsd.theme.osd.defaultPosition;
    }

    function showMessage(message, durationMs, position, title, icon, iconSize, progress) {
        const parsedDuration = Number(durationMs);
        const parsedIconSize = Number(iconSize);
        const parsedProgress = Number(progress);

        rootOsd.icon = icon || "";
        rootOsd.title = title || "";
        rootOsd.message = message;
        rootOsd.position = normalizePosition(position);
        rootOsd.active = true;
        rootOsd.iconSize = Number.isFinite(parsedIconSize) && parsedIconSize > 0 ? parsedIconSize : rootOsd.theme.osd.iconSize;
        rootOsd.progress = Number.isFinite(parsedProgress) ? parsedProgress : -1;
        hideTimer.interval = Number.isFinite(parsedDuration) && parsedDuration > 0 ? parsedDuration : rootOsd.theme.osd.defaultDuration;
        hideTimer.restart();
    }

    function hideMessage() {
        hideTimer.stop();
        active = false;
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
            showMessage("Brightness unavailable", theme.osd.defaultDuration, theme.osd.defaultPosition, "Brightness", brightnessIcon(0), theme.osd.progressIconSize);
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
        showMessage(message, theme.osd.defaultDuration, theme.osd.defaultPosition, title, icon, theme.osd.progressIconSize, progress);
    }

    function queryAudio(kind, target) {
        pendingAudioKind = kind;
        audioRunner.running = false;
        audioRunner.command = ["wpctl", "get-volume", target];
        audioRunner.running = true;
    }

    function applyAudioOutput(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0) {
            showMessage(audioTitle(pendingAudioKind) + " unavailable", theme.osd.defaultDuration, theme.osd.defaultPosition, audioTitle(pendingAudioKind), audioIcon(pendingAudioKind, 0, false), theme.osd.progressIconSize);
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
            showMessage(playerActionTitle(pendingPlayerAction), theme.osd.defaultDuration, theme.osd.defaultPosition, "Player", fallbackIcon, theme.osd.progressIconSize);
            return;
        }

        const meta = parsePlayerMetadata(stdoutText);
        const title = meta.title || playerActionTitle(pendingPlayerAction);
        const artist = meta.artist || meta.player || "";
        const status = meta.status || "";
        const icon = playerActionIcon(pendingPlayerAction, status);

        showMessage(artist, theme.osd.defaultDuration, theme.osd.defaultPosition, title, icon, theme.osd.progressIconSize);
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

    anchors {
        top: !rootOsd.isBottomPosition
        bottom: rootOsd.isBottomPosition
        left: true
        right: true
    }

    implicitHeight: Math.max(osdCard.height + rootOsd.theme.osd.topMargin * 2, rootOsd.theme.osd.panelHeight)
    visible: active
    color: "transparent"
    mask: Region {
        item: osdCard
    }

    WlrLayershell.namespace: "qreep-popup-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    Rectangle {
        id: osdCard

        width: rootOsd.hasProgress ? Math.min(rootOsd.theme.osd.progressCardWidth, rootOsd.width - rootOsd.theme.osd.screenPadding * 2) : Math.min(osdContent.implicitWidth + rootOsd.theme.osd.horizontalPadding * 2, rootOsd.width - rootOsd.theme.osd.screenPadding * 2)
        height: osdLayout.implicitHeight + rootOsd.theme.osd.verticalPadding * 2
        x: {
            if (rootOsd.isLeftPosition)
                return rootOsd.theme.osd.screenPadding;

            if (rootOsd.isRightPosition)
                return rootOsd.width - width - rootOsd.theme.osd.screenPadding;

            return (rootOsd.width - width) / 2;
        }
        y: rootOsd.isBottomPosition ? rootOsd.height - height - rootOsd.theme.osd.topMargin : rootOsd.theme.osd.topMargin
        radius: rootOsd.theme.osd.radius
        color: Qt.rgba(rootOsd.theme.calendarBackground.r, rootOsd.theme.calendarBackground.g, rootOsd.theme.calendarBackground.b, rootOsd.theme.osd.opacity)
        border.width: rootOsd.theme.osd.borderWidth
        border.color: rootOsd.theme.moduleHoverBackground

        Column {
            id: osdLayout

            anchors.centerIn: parent
            width: parent.width - rootOsd.theme.osd.horizontalPadding * 2
            spacing: rootOsd.hasProgress ? rootOsd.theme.osd.progressSpacing : 0

            Row {
                id: osdContent

                width: rootOsd.hasProgress ? parent.width : implicitWidth
                height: Math.max(rootOsd.hasIcon ? rootOsd.activeIconSize : 0, osdTextLayout.implicitHeight)
                spacing: rootOsd.theme.osd.contentSpacing

                Item {
                    width: rootOsd.activeIconSize
                    height: rootOsd.activeIconSize
                    implicitWidth: width
                    implicitHeight: height
                    anchors.verticalCenter: parent.verticalCenter
                    visible: rootOsd.hasIcon

                    IconImage {
                        id: osdIcon

                        anchors.fill: parent
                        source: rootOsd.hasIcon ? Quickshell.iconPath(rootOsd.icon, rootOsd.icon) : ""
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: osdIcon
                        colorization: rootOsd.theme.power.actionIconColorization
                        brightness: rootOsd.theme.power.actionIconBrightness
                        colorizationColor: rootOsd.theme.powerActionIconColor
                    }
                }

                Column {
                    id: osdTextLayout

                    width: Math.min(implicitWidth, rootOsd.maxTextWidth)
                    spacing: rootOsd.theme.osd.textSpacing
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: osdTitle

                        width: rootOsd.hasProgress ? implicitWidth : Math.min(implicitWidth, rootOsd.maxTextWidth)
                        visible: rootOsd.hasTitle
                        text: rootOsd.title
                        color: rootOsd.theme.calendarHeaderText
                        font.pixelSize: rootOsd.hasProgress ? rootOsd.theme.osd.progressTitleTextPixelSize : rootOsd.theme.osd.titleTextPixelSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        id: osdMessage

                        width: rootOsd.hasProgress ? implicitWidth : Math.min(implicitWidth, rootOsd.maxTextWidth)
                        text: rootOsd.message
                        color: rootOsd.hasTitle ? rootOsd.theme.calendarDayText : rootOsd.theme.calendarHeaderText
                        font.pixelSize: rootOsd.hasProgress ? rootOsd.theme.osd.progressMessageTextPixelSize : rootOsd.theme.osd.messageTextPixelSize
                        font.weight: rootOsd.hasTitle ? Font.Normal : Font.DemiBold
                        wrapMode: Text.Wrap
                        horizontalAlignment: rootOsd.hasProgress ? Text.AlignHCenter : Text.AlignLeft
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: rootOsd.theme.osd.progressHeight
                visible: rootOsd.hasProgress
                radius: height / 2
                color: rootOsd.theme.moduleHoverBackground

                Rectangle {
                    width: parent.width * rootOsd.clampedProgress
                    height: parent.height
                    radius: parent.radius
                    color: rootOsd.theme.primaryText
                }
            }
        }
    }

    Timer {
        id: hideTimer

        repeat: false
        onTriggered: rootOsd.active = false
    }
}
