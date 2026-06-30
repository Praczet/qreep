import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Scope {
    id: rootSoundService

    property QtObject log
    property real volumeStep: 0.05
    property real maxVolume: 1.5
    property bool unmuteOnVolumeChange: true

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinkAudio: sink?.audio ?? null
    readonly property var sourceAudio: source?.audio ?? null
    readonly property bool ready: Pipewire.ready

    readonly property bool sinkAvailable: ready && sink !== null && sinkAudio !== null
    readonly property bool sourceAvailable: ready && source !== null && sourceAudio !== null

    readonly property real sinkVolume: sinkAvailable ? clampVolume(sinkAudio.volume) : 0
    readonly property int sinkPercent: volumePercent(sinkVolume)
    readonly property bool sinkMuted: sinkAvailable ? sinkAudio.muted : false
    readonly property string sinkName: nodeLabel(sink, "Volume")
    readonly property string sinkIcon: volumeIcon(sinkPercent, sinkMuted)
    readonly property string sinkText: percentText(sinkPercent)
    readonly property string sinkTooltip: sinkAvailable ? sinkName + " - " + sinkText + (sinkMuted ? " (muted)" : "") : "Audio output unavailable"

    readonly property real sourceVolume: sourceAvailable ? clampVolume(sourceAudio.volume) : 0
    readonly property int sourcePercent: volumePercent(sourceVolume)
    readonly property bool sourceMuted: sourceAvailable ? sourceAudio.muted : false
    readonly property string sourceName: nodeLabel(source, "Microphone")
    readonly property string sourceIcon: sourceMuted ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic"
    readonly property string sourceText: percentText(sourcePercent)
    readonly property string sourceTooltip: sourceAvailable ? sourceName + " - " + sourceText + (sourceMuted ? " (muted)" : "") : "Microphone unavailable"

    readonly property var trackedObjects: {
        const objects = [];

        if (sink !== null)
            objects.push(sink);

        if (source !== null)
            objects.push(source);

        return objects;
    }

    signal sinkFeedbackRequested(int percent, bool muted)
    signal sourceFeedbackRequested(int percent, bool muted)

    PwObjectTracker {
        objects: rootSoundService.trackedObjects
    }

    function increaseVolume(step) {
        increaseSinkVolume(step);
    }

    function decreaseVolume(step) {
        decreaseSinkVolume(step);
    }

    function setVolume(value) {
        setSinkVolume(value);
    }

    function toggleMute() {
        toggleSinkMute();
    }

    function increaseSinkVolume(step) {
        setSinkVolume(sinkVolume + normalizedStep(step));
    }

    function decreaseSinkVolume(step) {
        setSinkVolume(sinkVolume - normalizedStep(step));
    }

    function setSinkVolume(value) {
        if (!sinkAvailable) {
            warn("Cannot set output volume: no default audio sink");
            return;
        }

        const nextVolume = clampVolume(value);
        sinkAudio.volume = nextVolume;

        if (unmuteOnVolumeChange && nextVolume > 0)
            sinkAudio.muted = false;

        sinkFeedbackRequested(volumePercent(nextVolume), sinkAudio.muted);
    }

    function setSinkMuted(muted) {
        if (!sinkAvailable) {
            warn("Cannot set output mute: no default audio sink");
            return;
        }

        sinkAudio.muted = muted;
        sinkFeedbackRequested(sinkPercent, sinkAudio.muted);
    }

    function toggleSinkMute() {
        setSinkMuted(!sinkMuted);
    }

    function increaseSourceVolume(step) {
        setSourceVolume(sourceVolume + normalizedStep(step));
    }

    function decreaseSourceVolume(step) {
        setSourceVolume(sourceVolume - normalizedStep(step));
    }

    function setSourceVolume(value) {
        if (!sourceAvailable) {
            warn("Cannot set microphone volume: no default audio source");
            return;
        }

        const nextVolume = clampVolume(value);
        sourceAudio.volume = nextVolume;

        if (unmuteOnVolumeChange && nextVolume > 0)
            sourceAudio.muted = false;

        sourceFeedbackRequested(volumePercent(nextVolume), sourceAudio.muted);
    }

    function setSourceMuted(muted) {
        if (!sourceAvailable) {
            warn("Cannot set microphone mute: no default audio source");
            return;
        }

        sourceAudio.muted = muted;
        sourceFeedbackRequested(sourcePercent, sourceAudio.muted);
    }

    function toggleSourceMute() {
        setSourceMuted(!sourceMuted);
    }

    function normalizedStep(step) {
        const parsed = Number(step);

        return Number.isFinite(parsed) && parsed > 0 ? parsed : volumeStep;
    }

    function clampVolume(value) {
        const parsed = Number(value);

        if (!Number.isFinite(parsed))
            return 0;

        return Math.max(0, Math.min(maxVolume, parsed));
    }

    function volumePercent(value) {
        return Math.round(clampVolume(value) * 100);
    }

    function percentText(value) {
        return Math.round(value) + "%";
    }

    function nodeLabel(node, fallback) {
        if (node === null)
            return fallback;

        return node.description || node.nickname || node.name || fallback;
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

    function warn() {
        if (log && log.warn) {
            log.warn.apply(log, arguments);
            return;
        }

        console.warn.apply(console, arguments);
    }
}
