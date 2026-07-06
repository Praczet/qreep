import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootDashboard

    required property QtObject theme
    property QtObject aegisService
    property bool open: false
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: dashboardService

    DashboardService {
        id: dashboardService

        theme: rootDashboard.theme
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-dashboard"

        function toggle() {
            rootDashboard.toggle();
        }

        function showMe() {
            rootDashboard.show();
        }

        function hideMe() {
            rootDashboard.hide();
        }

        function refresh() {
            rootDashboard.refresh();
        }
    }

    LazyLoader {
        id: panelLoader

        active: rootDashboard.panelLoaded

        DashboardPanel {
            theme: rootDashboard.theme
            service: dashboardService
            aegisService: rootDashboard.aegisService
            panelOpen: rootDashboard.open

            onCloseRequested: rootDashboard.hide()
        }
    }

    Timer {
        id: closeTimer

        interval: rootDashboard.theme.modules.dashboard.animationDuration + 40
        repeat: false
    }

    function show() {
        closeTimer.stop();
        dashboardService.reload();
        if (aegisService)
            aegisService.setActive("dashboard", true);
        open = true;
    }

    function hide() {
        if (!open)
            return;

        closeTimer.restart();
        open = false;
        if (aegisService)
            aegisService.setActive("dashboard", false);
    }

    function toggle() {
        if (open)
            hide();
        else
            show();
    }

    function refresh() {
        dashboardService.reload();
    }
}
