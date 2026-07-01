import QtQuick
import Quickshell

Scope {
    id: rootUpchecker

    required property QtObject theme
    required property QtObject log
    property bool open: false
    readonly property alias service: upcheckerService

    UpcheckerService {
        id: upcheckerService

        log: rootUpchecker.log
        updateTerminalCommand: rootUpchecker.theme.modules.bar.upchecker.updateTerminalCommand
        updateCommand: rootUpchecker.theme.modules.bar.upchecker.updateCommand
        restartCheckCommand: rootUpchecker.theme.modules.bar.upchecker.restartCheckCommand
        restartCheckTimezone: rootUpchecker.theme.modules.bar.upchecker.restartCheckTimezone
        restartSessionPackages: rootUpchecker.theme.modules.bar.upchecker.restartSessionPackages
        restartRebootPackages: rootUpchecker.theme.modules.bar.upchecker.restartRebootPackages
    }

    LazyLoader {
        id: panelLoader

        active: rootUpchecker.open

        UpcheckerPanel {
            theme: rootUpchecker.theme
            service: upcheckerService
            panelOpen: rootUpchecker.open

            onCloseRequested: rootUpchecker.hide()
        }
    }

    Connections {
        target: upcheckerService

        function onToggleRequested() {
            rootUpchecker.toggle();
        }

        function onUpdateRequested() {
            rootUpchecker.hide();
        }
    }

    function show() {
        if (open)
            return;

        upcheckerService.refresh();
        open = true;
    }

    function hide() {
        open = false;
    }

    function toggle() {
        if (open)
            hide();
        else
            show();
    }

    function refresh() {
        upcheckerService.refresh();
    }
}
