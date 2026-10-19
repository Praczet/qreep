import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Places controller: IPC, open state, the service, and a lazy overlay panel
// on whichever monitor has focus when it opens.
Scope {
    id: rootPlaces

    required property QtObject theme
    // KIP controller: todos open through Kip.runAction (Logseq page naming,
    // cold-start handling) instead of a second copy of that logic.
    property QtObject kipController: null
    property bool open: false
    property var targetScreen: null
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: placesService

    PlacesService {
        id: placesService

        theme: rootPlaces.theme
        panelActive: rootPlaces.open
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-places"

        function toggle() {
            rootPlaces.toggle();
        }

        function showMe() {
            rootPlaces.show();
        }

        function hideMe() {
            rootPlaces.hide();
        }

        function refresh() {
            placesService.refresh();
        }

        // Open with the filter typed, e.g. "eos".
        function showWith(text: string) {
            rootPlaces.show();
            placesService.setQuery(text);
        }

        // Open with one project selected, by its config id.
        function showProject(id: string) {
            rootPlaces.showProject(id);
        }

        function state(): string {
            const selected = placesService.selected;

            return "open=" + rootPlaces.open
                + " projects=" + placesService.projects.length
                + " shown=" + placesService.filtered.length
                + " selected=" + (selected ? selected.id : "-")
                + " config=" + (placesService.configError || "ok");
        }
    }

    LazyLoader {
        active: rootPlaces.panelLoaded

        PlacesPanel {
            screen: rootPlaces.targetScreen
            theme: rootPlaces.theme
            service: placesService
            panelOpen: rootPlaces.open
            kipController: rootPlaces.kipController

            onCloseRequested: rootPlaces.hide()
        }
    }

    Timer {
        id: closeTimer

        interval: rootPlaces.theme.modules.places.animationDuration + 40
        repeat: false
    }

    function show() {
        if (!panelLoaded)
            targetScreen = screenForFocusedMonitor();

        closeTimer.stop();
        placesService.setQuery("");
        placesService.refresh();
        open = true;
    }

    function showProject(id) {
        show();
        placesService.selectProject(id);
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
