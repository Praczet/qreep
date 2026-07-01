import QtQuick
import Quickshell.Io
import "../../../../core" as Core

QtObject {
    id: rootPowerService

    property QtObject log
    readonly property Process commandRunner: Process {}
    readonly property Core.Log fallbackLog: Core.Log {}
    signal toggleRequested

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-power"

        function toggle() {
            rootPowerService.toggleRequested();
        }
    }

    function request(action) {
        switch (action) {
        case "lock":
            run("Lock", ["loginctl", "lock-session"]);
            break;
        case "logout":
            run("Logout", ["hyprctl", "dispatch", "exit"]);
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
        commandRunner.command = command;
        commandRunner.running = true;
    }

    function info(message) {
        (log || fallbackLog).info(message);
    }

    function warn(message) {
        (log || fallbackLog).warn(message);
    }
}
