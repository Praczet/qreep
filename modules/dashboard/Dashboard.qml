import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootDashboard

    required property QtObject theme
    property bool open: false
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

        function show() {
            rootDashboard.show();
        }

        function hide() {
            rootDashboard.hide();
        }

        function refresh() {
            rootDashboard.refresh();
        }
    }

    LazyLoader {
        id: panelLoader

        active: rootDashboard.open

        DashboardPanel {
            theme: rootDashboard.theme
            service: dashboardService

            onCloseRequested: rootDashboard.hide()
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

    function refresh() {
        dashboardService.reload();
    }
}
