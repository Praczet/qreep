import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: rootMprisService

    readonly property var players: Mpris.players.values
    readonly property var activePlayer: chooseActivePlayer()
    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && activePlayer.isPlaying
    readonly property bool canTogglePlaying: hasPlayer && activePlayer.canTogglePlaying
    readonly property bool canGoNext: hasPlayer && activePlayer.canGoNext
    readonly property bool canGoPrevious: hasPlayer && activePlayer.canGoPrevious
    readonly property bool canStop: hasPlayer && activePlayer.canControl
    readonly property string playbackStateIcon: !hasPlayer ? "" : isPlaying ? "" : activePlayer.playbackState === MprisPlaybackState.Paused ? "" : ""
    readonly property string toggleActionIcon: !hasPlayer ? "" : isPlaying ? "" : ""
    readonly property string statusText: !hasPlayer ? "No player" : isPlaying ? "Playing" : playbackStateText(activePlayer.playbackState)
    readonly property string title: hasPlayer && hasText(activePlayer.trackTitle) ? activePlayer.trackTitle : hasPlayer ? activePlayer.identity : "Nothing playing"
    readonly property string album: hasPlayer ? valueOrFallback(activePlayer.trackAlbum, "Unknown album") : "MPRIS"
    readonly property string artists: hasPlayer ? valueOrFallback(activePlayer.trackArtists || activePlayer.trackArtist, "Unknown artist") : "No active player"
    readonly property string artUrl: hasPlayer ? activePlayer.trackArtUrl : ""
    readonly property string currentTrackKey: hasPlayer ? playerSource + "|" + title + "|" + album + "|" + artists : ""
    readonly property string currentImageSource: imageSource(artUrl)
    readonly property string artSource: currentTrackKey.length > 0 && currentTrackKey === cachedArtTrackKey ? cachedArtSource : currentImageSource
    readonly property string playerName: hasPlayer ? valueOrFallback(activePlayer.identity, "Unknown player") : "No player"
    readonly property string playerSource: hasPlayer ? sourceText(activePlayer) : "No player"
    readonly property string tooltipTitle: hasPlayer ? playerName : "MPRIS"
    readonly property string tooltipSubtitle: hasPlayer ? title : "No active player"
    readonly property string tooltipDetail: hasPlayer ? artists + "\n" + album + "\n" + statusText : "Start a media player and it should appear here."
    readonly property string durationText: hasPlayer && activePlayer.lengthSupported ? timeText(activePlayer.position) + " / " + timeText(activePlayer.length) : ""

    property string cachedArtTrackKey
    property string cachedArtSource

    onCurrentImageSourceChanged: updateCachedArtSource()
    onCurrentTrackKeyChanged: updateCachedArtSource()

    Component.onCompleted: updateCachedArtSource()

    function updateCachedArtSource() {
        if (currentTrackKey.length === 0) {
            cachedArtTrackKey = "";
            cachedArtSource = "";
            return;
        }

        if (currentImageSource.length === 0)
            return;

        cachedArtTrackKey = currentTrackKey;
        cachedArtSource = currentImageSource;
    }

    function chooseActivePlayer() {
        if (!players || players.length === 0)
            return null;

        for (let index = 0; index < players.length; index++) {
            if (players[index].isPlaying)
                return players[index];
        }

        return players[0];
    }

    function togglePlaying() {
        if (!canTogglePlaying)
            return;

        activePlayer.togglePlaying();
    }

    function next() {
        if (canGoNext)
            activePlayer.next();
    }

    function previous() {
        if (canGoPrevious)
            activePlayer.previous();
    }

    function stop() {
        if (canStop)
            activePlayer.stop();
    }

    function hasText(value) {
        return String(value || "").length > 0;
    }

    function valueOrFallback(value, fallback) {
        const text = String(value || "");
        return text.length > 0 ? text : fallback;
    }

    function sourceText(player) {
        const identity = valueOrFallback(player.identity, "Unknown player");
        const desktopEntry = String(player.desktopEntry || "");
        const dbusName = String(player.dbusName || "");

        if (desktopEntry.length > 0)
            return identity + " (" + desktopEntry + ")";

        if (dbusName.length > 0)
            return identity + " (" + dbusName + ")";

        return identity;
    }

    function imageSource(value) {
        const source = String(value || "");

        if (source.length === 0)
            return "";

        if (source.indexOf("://") >= 0)
            return source;

        if (source[0] === "/")
            return "file://" + source;

        return source;
    }

    function playbackStateText(state) {
        switch (state) {
        case MprisPlaybackState.Playing:
            return "Playing";
        case MprisPlaybackState.Paused:
            return "Paused";
        case MprisPlaybackState.Stopped:
            return "Stopped";
        default:
            return "Unknown";
        }
    }

    function timeText(value) {
        const totalSeconds = Math.max(0, Math.floor(Number(value || 0)));
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }
}
