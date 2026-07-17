import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "../../../../core" as Core

QtObject {
    id: rootPowerService

    property QtObject log
    property string runningLabel: ""
    readonly property Process commandRunner: Process {
        stdout: StdioCollector {
            id: commandStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: commandStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootPowerService.applyCommandOutput(commandStdout.text, commandStderr.text, exitCode, exitStatus)
    }
    readonly property Core.Log fallbackLog: Core.Log {}
    signal toggleRequested
    property bool isFullscreen: false

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-power"

        function toggle() {
            rootPowerService.isFullscreen = false;
            rootPowerService.toggleRequested();
        }
        function toggleFullscreen() {
            rootPowerService.isFullscreen = true;
            rootPowerService.toggleRequested();
        }
    }

    function request(action) {
        switch (action) {
        case "lock":
            run("Lock", ["loginctl", "lock-session"]);
            break;
        case "logout":
            run("Logout", hyprlandDispatchCommand("exit"));
            break;
        case "suspend":
            run("Suspend", ["systemctl", "suspend"]);
            break;
        case "reboot":
            run("Reboot", ["systemctl", "reboot"]);
            break;
        case "poweroff":
            run("Power off", ["systemctl", "poweroff"]);
            break;
        default:
            warn("Unknown power action requested: " + action);
        }
    }

    function run(label, command) {
        info(label + " requested");

        commandRunner.running = false;
        runningLabel = label;
        commandRunner.command = command;
        commandRunner.running = true;
    }

    function hyprlandDispatchCommand(dispatcher, argument) {
        if (!Hyprland.usingLua)
            return argument !== undefined ? ["hyprctl", "dispatch", dispatcher, argument] : ["hyprctl", "dispatch", dispatcher];

        return ["hyprctl", "dispatch", luaDispatch(dispatcher, argument)];
    }

    function luaDispatch(dispatcher, argument) {
        if (argument === undefined || argument === null || String(argument).length === 0)
            return "hl.dsp." + dispatcher + "()";

        return "hl.dsp." + dispatcher + "(" + luaString(argument) + ")";
    }

    function luaString(value) {
        return "\"" + String(value || "").replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\"";
    }

    function applyCommandOutput(stdoutText, stderrText, exitCode, exitStatus) {
        const label = runningLabel.length > 0 ? runningLabel : "Power command";
        const stderrOutput = String(stderrText || "").trim();
        const stdoutOutput = String(stdoutText || "").trim();

        if (exitCode !== 0) {
            const detail = stderrOutput.length > 0 ? stderrOutput : (stdoutOutput.length > 0 ? stdoutOutput : "exit code " + exitCode + ", status " + exitStatus);

            warn(label + " failed: " + detail);
            return;
        }

        if (stdoutOutput.length > 0)
            info(label + " output: " + stdoutOutput);
    }

    function info(message) {
        (log || fallbackLog).info(message);
    }

    function warn(message) {
        (log || fallbackLog).warn(message);
    }
}
