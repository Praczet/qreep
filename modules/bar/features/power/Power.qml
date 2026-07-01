import QtQuick
import Quickshell

Scope {
    id: rootPower

    required property QtObject theme
    required property QtObject log
    property bool open: false
    readonly property alias service: powerService

    PowerService {
        id: powerService

        log: rootPower.log
    }

    LazyLoader {
        id: panelLoader

        active: rootPower.open

        PowerPanel {
            theme: rootPower.theme
            service: powerService
            panelOpen: rootPower.open

            onActionRequested: action => powerService.request(action)
            onCloseRequested: rootPower.hide()
        }
    }

    Connections {
        target: powerService

        function onToggleRequested() {
            rootPower.toggle();
        }
    }

    function show() {
        open = true;
    }

    function hide() {
        open = false;
    }

    function toggle() {
        open = !open;
    }
}
