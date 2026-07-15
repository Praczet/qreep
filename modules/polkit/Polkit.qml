import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit as PolkitApi

Scope {
    id: rootPolkit

    required property QtObject theme
    property bool open: false
    readonly property bool panelLoaded: open || closeTimer.running
    readonly property alias service: polkitService

    PolkitService {
        id: polkitService
    }

    PolkitApi.PolkitAgent {
        id: polkitAgent

        path: "/org/qreep/Polkit"
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-polkit"

        function toggle() {
            rootPolkit.toggle("ipc:toggle");
        }

        function showMe() {
            rootPolkit.show("ipc:showMe");
        }

        function hideMe() {
            rootPolkit.hide("ipc:hideMe");
        }

        function demo() {
            rootPolkit.show("ipc:demo");
        }

        function registrationState(): string {
            return polkitAgent.isRegistered ? "registered" : "not registered";
        }

        function showLog(): string {
            return polkitService.logCommand();
        }

        function logPath(): string {
            return polkitService.logPathCommand();
        }
    }

    Connections {
        target: polkitAgent

        function onIsRegisteredChanged() {
            polkitService.setRegistrationState(polkitAgent.isRegistered);
        }

        function onIsActiveChanged() {
            rootPolkit.handleAgentStateChanged();
        }

        function onFlowChanged() {
            rootPolkit.handleAgentStateChanged();
        }
    }

    Connections {
        target: polkitAgent.flow
        ignoreUnknownSignals: true

        function onMessageChanged() {
            polkitService.syncFlow();
        }

        function onSupplementaryMessageChanged() {
            polkitService.syncFlow();
        }

        function onSupplementaryIsErrorChanged() {
            polkitService.syncFlow();
        }

        function onIsResponseRequiredChanged() {
            polkitService.syncFlow();
        }

        function onInputPromptChanged() {
            polkitService.syncFlow();
        }

        function onResponseVisibleChanged() {
            polkitService.syncFlow();
        }

        function onFailedChanged() {
            polkitService.syncFlow();
        }

        function onAuthenticationFailed() {
            polkitService.logFlowEvent("Polkit authentication failed signal:");
            polkitService.recordFailedAttempt("polkit-authentication-failed");
            polkitService.syncFlow();
        }

        function onAuthenticationSucceeded() {
            polkitService.logFlowEvent("Polkit authentication succeeded signal:");
            rootPolkit.handleFlowCompleted();
        }

        function onAuthenticationRequestCancelled() {
            polkitService.logFlowEvent("Polkit authentication cancelled signal:");
            rootPolkit.handleFlowCompleted();
        }

        function onIsCompletedChanged() {
            rootPolkit.handleFlowCompleted();
        }

        function onIsCancelledChanged() {
            rootPolkit.handleFlowCompleted();
        }

        function onIsSuccessfulChanged() {
            rootPolkit.handleFlowCompleted();
        }
    }

    LazyLoader {
        id: panelLoader

        active: rootPolkit.panelLoaded

        PolkitPanel {
            theme: rootPolkit.theme
            service: polkitService
            panelOpen: rootPolkit.open

            onCloseRequested: reason => rootPolkit.hide(reason)
            onAuthenticated: rootPolkit.hide("success")
        }
    }

    Timer {
        id: closeTimer

        interval: rootPolkit.theme.modules.polkit.animationDuration + 40
        repeat: false
    }

    function show(caller) {
        closeTimer.stop();
        polkitService.loadDemo(caller || "internal");
        open = true;
    }

    function hide(reason) {
        if (!open)
            return;

        const outcomeReason = String(reason || "cancel");
        if (outcomeReason !== "success")
            polkitService.cancel(outcomeReason);

        closeTimer.restart();
        open = false;
    }

    function toggle(caller) {
        if (open)
            hide("toggle");
        else
            show(caller || "internal:toggle");
    }

    function handleAgentStateChanged() {
        polkitService.setRegistrationState(polkitAgent.isRegistered);

        if (polkitAgent.isActive && polkitAgent.flow) {
            closeTimer.stop();
            polkitService.loadFlow(polkitAgent.flow, "polkit-agent");
            open = true;
            return;
        }

        if (!polkitAgent.isActive && polkitService.realRequestActive)
            rootPolkit.hide("agent-inactive");
    }

    function handleFlowCompleted() {
        const flow = polkitAgent.flow;

        if (!flow)
            return;

        polkitService.syncFlow();

        if (!flow.isCompleted && !flow.isCancelled)
            return;

        if (flow.isSuccessful || polkitService.flowCompletedCleanly())
            polkitService.finish("success", "polkit-flow");
        else if (flow.isCancelled)
            polkitService.finish("cancel", "polkit-flow-cancelled");
        else
            polkitService.finish("failed", "polkit-flow-failed");

        closeTimer.restart();
        open = false;
    }

    Component.onCompleted: polkitService.setRegistrationState(polkitAgent.isRegistered)
}
