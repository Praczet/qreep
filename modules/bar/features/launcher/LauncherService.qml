import QtQuick
import Quickshell
import Quickshell.Io
import "../../../core" as Core

QtObject {
    id: rootLauncherService

    property QtObject log
    readonly property Core.Log fallbackLog: Core.Log {}
    readonly property var launcherCommand: ["launcher"]
    readonly property Process commandRunner: Process {
        id: commandRunner

        stdout: StdioCollector {
            id: stdoutCollector

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: stderrCollector

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            info("Launcher command exited with code", exitCode, "and status", exitStatus);
            info("stdout:", stdoutCollector.text);
            info("stderr:", stderrCollector.text);
        }
    }

    function launchLauncher() {
        info("Launching launcher.");

        commandRunner.running = false;
        commandRunner.command = launcherCommand;
        commandRunner.startDetached();
    }

    function info() {
        (log || fallbackLog).info.apply(log || fallbackLog, arguments);
    }

    function warn() {
        (log || fallbackLog).warn.apply(log || fallbackLog, arguments);
    }
}
