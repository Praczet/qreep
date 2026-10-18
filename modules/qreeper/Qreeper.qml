import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootQreeper

    required property QtObject theme
    // Qreeper is a play-time feature: asleep until a session starts (start,
    // or opening the minimap/Atlas), so the snapshot is not watched and the
    // bar pill stays hidden while nobody is playing.
    property bool active: false
    property bool minimapOpen: false
    property bool atlasOpen: false
    readonly property alias service: qreeperService

    QreeperService {
        id: qreeperService
        theme: rootQreeper.theme
        active: rootQreeper.active
    }

    // One layout for both views, so the minimap and the Atlas always agree.
    QreeperLayout {
        id: qreeperLayout
        theme: rootQreeper.theme
        service: qreeperService
        active: rootQreeper.minimapOpen || rootQreeper.atlasOpen
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-qreeper"

        function start() { rootQreeper.start(); }
        function stop() { rootQreeper.stop(); }
        function toggleMinimap() { rootQreeper.toggleMinimap(); }
        function showMinimap() { rootQreeper.showMinimap(); }
        function hideMinimap() { rootQreeper.hideMinimap(); }
        function toggleAtlas() { rootQreeper.toggleAtlas(); }
        function showAtlas() { rootQreeper.showAtlas(); }
        function hideAtlas() { rootQreeper.hideAtlas(); }
        function refresh() { rootQreeper.refresh(); }
        function recenter() { rootQreeper.recenter(); }
        function rearrange() { qreeperLayout.rearrange(); }
        function resetLayout() { qreeperLayout.reset(); }
        function state(): string { return rootQreeper.state(); }
        function fontBigger() { rootQreeper.stepFontScale(1); }
        function fontSmaller() { rootQreeper.stepFontScale(-1); }
        function setFontScale(scale: real) { rootQreeper.setFontScale(scale); }
        function resetFontScale() { rootQreeper.setFontScale(1); }
        function fontScale(): string { return String(rootQreeper.theme.modules.qreeper.fontScale); }
    }

    LazyLoader {
        id: minimapLoader
        active: rootQreeper.minimapOpen

        QreeperMinimap {
            theme: rootQreeper.theme
            service: qreeperService
            layout: qreeperLayout
            onCloseRequested: rootQreeper.hideMinimap()
            onAtlasRequested: rootQreeper.showAtlas()
        }
    }

    LazyLoader {
        id: atlasLoader
        active: rootQreeper.atlasOpen

        QreeperAtlas {
            theme: rootQreeper.theme
            service: qreeperService
            layout: qreeperLayout
            onCloseRequested: rootQreeper.hideAtlas()
            onFontScaleStepRequested: direction => rootQreeper.stepFontScale(direction)
        }
    }

    function start() { active = true; qreeperService.refresh(); }
    function stop() { minimapOpen = false; atlasOpen = false; active = false; }
    function toggleMinimap() { minimapOpen ? hideMinimap() : showMinimap(); }
    function showMinimap() { start(); minimapOpen = true; }
    function hideMinimap() { minimapOpen = false; }
    function toggleAtlas() { atlasOpen ? hideAtlas() : showAtlas(); }
    function showAtlas() { start(); atlasOpen = true; }
    function hideAtlas() { atlasOpen = false; }
    function refresh() { qreeperService.refresh(); }
    function recenter() {
        if (minimapLoader.item)
            minimapLoader.item.recenter();
    }
    // Runtime only. The startup value is `fontScale` in QreeperTheme.qml.
    function setFontScale(scale) {
        const qreeperTheme = theme.modules.qreeper;
        const clamped = Math.max(qreeperTheme.fontScaleMinimum, Math.min(qreeperTheme.fontScaleMaximum, Number(scale) || 1));
        qreeperTheme.fontScale = Math.round(clamped * 100) / 100;
    }
    function stepFontScale(direction) {
        setFontScale(theme.modules.qreeper.fontScale + direction * theme.modules.qreeper.fontScaleStep);
    }
    function state() {
        return "active=" + active
            + " snapshot=" + qreeperService.displayState
            + " revision=" + qreeperService.revision
            + " room=" + qreeperService.currentRoomId
            + " minimap=" + minimapOpen
            + " atlas=" + atlasOpen
            + " fontScale=" + theme.modules.qreeper.fontScale
            + " atlasLoaded=" + (atlasLoader.item !== null)
            + (atlasLoader.item ? " atlasVisible=" + atlasLoader.item.visible + " atlasSize=" + atlasLoader.item.width + "x" + atlasLoader.item.height : "");
    }
}
