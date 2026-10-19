import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Prism controller: IPC, open state, the service (which also runs the
// colour picker and watches the clipboard), and a lazy overlay panel on
// whichever monitor has focus when it opens.
Scope {
    id: rootPrism

    required property QtObject theme
    property bool open: false
    property var targetScreen: null
    // Section to show on the next open: "favorites", "history" or "palette:<id>".
    property string requestedSection: ""
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: prismService

    PrismService {
        id: prismService

        theme: rootPrism.theme
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-prism"

        function toggle() {
            rootPrism.toggle();
        }

        function showMe() {
            rootPrism.show();
        }

        function hideMe() {
            rootPrism.hide();
        }

        // hyprpicker, then the colour lands in history (and the clipboard).
        function pick() {
            prismService.pick();
        }

        // "favorites", "history", or a palette name.
        function showSection(name: string) {
            const palette = prismService.palettes.find(item => item.name.toLowerCase() === name.toLowerCase());

            rootPrism.requestedSection = palette ? "palette:" + palette.id : name;
            rootPrism.show();
        }

        // A combo from the shell, into a palette (made if missing). Colours
        // space separated, each "#hex" or "#hex=Name"; names may contain
        // spaces, the next "#" ends them.
        //   addCombo "Color combos" "#d6ccd0=Timberwolf #763948=American Brown"
        function addCombo(palette: string, colors: string): string {
            const found = prismService.palettes.find(item => item.name.toLowerCase() === palette.toLowerCase());
            const paletteId = found ? found.id : prismService.createPalette(palette);
            const comboId = prismService.createCombo(paletteId, "");

            for (const part of colors.split(/\s+(?=#)/)) {
                const pieces = part.split("=");
                const hex = prismService.parseColor(pieces[0]);
                if (hex)
                    prismService.addToCombo(paletteId, comboId, hex, (pieces[1] || "").trim());
            }
            const combo = prismService.comboById(paletteId, comboId);
            return palette + " / " + combo.name + ": " + combo.colors.length + " colours";
        }

        function state(): string {
            return "open=" + rootPrism.open
                + " loaded=" + prismService.loaded
                + " history=" + prismService.history.length
                + " favorites=" + prismService.favorites.length
                + " palettes=" + prismService.palettes.map(palette => palette.name + ":" + palette.combos.map(combo => combo.colors.length).join("+")).join(",")
                + " latest=" + (prismService.history.length > 0 ? prismService.history[0].hex + " " + prismService.history[0].name : "-")
                + " error=" + (prismService.lastError || "-");
        }
    }

    LazyLoader {
        active: rootPrism.panelLoaded

        PrismPanel {
            screen: rootPrism.targetScreen
            theme: rootPrism.theme
            service: prismService
            panelOpen: rootPrism.open
            requestedSection: rootPrism.requestedSection

            onCloseRequested: rootPrism.hide()
        }
    }

    Timer {
        id: closeTimer

        interval: rootPrism.theme.modules.prism.animationDuration + 40
        repeat: false
    }

    function show() {
        if (!panelLoaded)
            targetScreen = screenForFocusedMonitor();

        closeTimer.stop();
        open = true;
    }

    function hide() {
        if (!open)
            return;

        closeTimer.restart();
        open = false;
        requestedSection = "";
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
