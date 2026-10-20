import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Wallpaper controller: IPC, open state, the service, and a lazy overlay
// panel on whichever monitor has focus when it opens. Replaces wallset's
// rofi picker; applying still goes through wallset (Unclaimed Bloom).
Scope {
    id: rootWallpaper

    required property QtObject theme
    property bool open: false
    property var targetScreen: null
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: wallpaperService

    WallpaperService {
        id: wallpaperService

        theme: rootWallpaper.theme
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-wallpaper"

        function toggle() {
            rootWallpaper.toggle();
        }

        function showMe() {
            rootWallpaper.show();
        }

        function hideMe() {
            rootWallpaper.hide();
        }

        function refresh() {
            wallpaperService.refresh();
        }

        // Open with the filter typed, e.g. "city".
        function showWith(text: string) {
            rootWallpaper.show();
            wallpaperService.setQuery(text);
        }

        // view: grid | list; size: s | m | l | xl (empty keeps it).
        function setView(view: string, size: string) {
            wallpaperService.setView(view);
            if (size.length > 0 && rootWallpaper.theme.modules.wallpaper.sizeOrder.indexOf(size) >= 0) {
                wallpaperService.size = size;
                wallpaperService.saveState();
            }
        }

        function state(): string {
            return "open=" + rootWallpaper.open
                + " wallpapers=" + wallpaperService.wallpapers.length
                + " shown=" + wallpaperService.filtered.length
                + " view=" + wallpaperService.view + "/" + wallpaperService.size
                + " building=" + (wallpaperService.building ? wallpaperService.buildDone + "/" + wallpaperService.buildTotal : "no")
                + " selected=" + (wallpaperService.selectedName || "-")
                + " current=" + (wallpaperService.current || "-")
                + " profile=" + (wallpaperService.chosenProfile || "-") + "/" + (wallpaperService.currentProfile || "-")
                + " profiles=" + wallpaperService.profiles.length
                + " error=" + (wallpaperService.errorText || "-");
        }
    }

    LazyLoader {
        active: rootWallpaper.panelLoaded

        WallpaperPanel {
            screen: rootWallpaper.targetScreen
            theme: rootWallpaper.theme
            service: wallpaperService
            panelOpen: rootWallpaper.open

            onCloseRequested: rootWallpaper.hide()
            onApplyRequested: item => {
                wallpaperService.apply(item);
                rootWallpaper.hide();
            }
        }
    }

    Timer {
        id: closeTimer

        interval: rootWallpaper.theme.modules.wallpaper.animationDuration + 40
        repeat: false
    }

    function show() {
        if (!panelLoaded)
            targetScreen = screenForFocusedMonitor();

        closeTimer.stop();
        wallpaperService.setQuery("");
        wallpaperService.refresh();
        open = true;
    }

    function hide() {
        if (!open)
            return;

        closeTimer.restart();
        open = false;
    }

    function toggle() {
        if (open)
            hide();
        else
            show();
    }

    function screenForFocusedMonitor() {
        const monitor = Hyprland.focusedMonitor;

        if (monitor) {
            for (let index = 0; index < Quickshell.screens.length; index++) {
                const candidate = Quickshell.screens[index];

                if (candidate && candidate.name === monitor.name)
                    return candidate;
            }
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }
}
