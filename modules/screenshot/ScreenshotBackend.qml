import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: rootScreenshotBackend

    readonly property bool running: workflowProcess.running
    readonly property string helperPath: Quickshell.shellDir + "/scripts/qreep-region-screenshot-delay_v0.0.1"

    readonly property Process workflowProcess: Process {
        stderr: StdioCollector {
            id: workflowStderr
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && exitCode !== 130)
                console.warn("Qreep screenshot workflow failed:", workflowStderr.text.trim());
        }
    }

    function start(delaySeconds, backend) {
        if (workflowProcess.running)
            return false;

        const normalizedBackend = String(backend || "flameshot").toLowerCase() === "grim" ? "grim" : "flameshot";
        const normalizedDelay = Math.max(0, Math.min(30, Math.round(Number(delaySeconds))));

        workflowProcess.command = [
            helperPath,
            "--backend",
            normalizedBackend,
            String(normalizedDelay)
        ];
        workflowProcess.running = true;
        return true;
    }

    function cancel() {
        if (workflowProcess.running)
            workflowProcess.running = false;
    }
}
