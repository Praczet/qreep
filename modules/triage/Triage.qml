import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootTriage

    required property QtObject theme
    property bool open: false
    property int topReservedHeight: 0
    property var updaterService: null
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: triageService

    TriageService {
        id: triageService

        theme: rootTriage.theme
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-triage"

        function toggle() {
            rootTriage.toggle();
        }

        function showMe() {
            rootTriage.show();
        }

        function hideMe() {
            rootTriage.hide();
        }

        function refresh() {
            rootTriage.refresh();
        }

        function showUpdates() {
            rootTriage.showUpdates();
        }

        function showPackage(packageName: string) {
            rootTriage.showPackage(packageName);
        }

        function update() {
            rootTriage.startUpdates();
        }
    }

    LazyLoader {
        active: rootTriage.panelLoaded

        TriagePanel {
            theme: rootTriage.theme
            service: triageService
            panelOpen: rootTriage.open
            topReservedHeight: rootTriage.topReservedHeight
            canUpdate: rootTriage.updaterService !== null

            onUpdateRequested: rootTriage.startUpdates()

            onCloseRequested: rootTriage.hide()
        }
    }

    Timer {
        id: closeTimer

        interval: rootTriage.theme.modules.triage.animationDuration + 40
        repeat: false
    }

    function show() {
        closeTimer.stop();
        triageService.refresh();
        open = true;
    }

    function showUpdates() {
        closeTimer.stop();
        triageService.activeDecisionFilter = "all";
        triageService.setCategory("updates");
        triageService.loadSummary();
        triageService.loadDecisions();
        triageService.loadEvents();
        open = true;
    }

    function showPackage(packageName) {
        closeTimer.stop();
        triageService.loadSummary();
        triageService.loadDecisions();
        triageService.loadEvents();
        triageService.focusPackage(packageName);
        open = true;
    }

    function startUpdates() {
        if (updaterService && updaterService.update) {
            updaterService.update();
            hide();
            return;
        }

        triageService.status = "updater is not connected";
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

    function refresh() {
        triageService.refresh();
    }
}
