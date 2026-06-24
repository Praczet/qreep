import QtQuick
import Quickshell.Io

QtObject {
    id: rootLog

    property string appName: "Qreep"
    property string notificationBackend: "notify-send"
    property bool notifyWarnings: true
    property bool notifyErrors: true
    property int notificationDuration: 5000
    property string warningColor: "rgb(f9e2af)"
    property string errorColor: "rgb(ffb4ab)"

    readonly property Process notifier: Process {}

    function log() {
        write("log", arguments);
    }

    function info() {
        write("info", arguments);
    }

    function warn() {
        write("warn", arguments);

        if (notifyWarnings)
            notify("normal", messageText(arguments));
    }

    function error() {
        write("error", arguments);

        if (notifyErrors)
            notify("critical", messageText(arguments));
    }

    function write(level, messages) {
        console.log(appName + " " + level + ":", messageText(messages));
    }

    function messageText(messages) {
        const parts = [];

        for (let index = 0; index < messages.length; index++)
            parts.push(String(messages[index]));

        return parts.join(" ");
    }

    function notify(urgency, message) {
        if (notificationBackend === "none")
            return;

        notifier.running = false;

        if (notificationBackend === "hyprctl") {
            notifier.command = [
                "hyprctl",
                "notify",
                urgency === "critical" ? "3" : "2",
                String(notificationDuration),
                urgency === "critical" ? errorColor : warningColor,
                appName + ": " + message
            ];
        } else {
            notifier.command = [
                "notify-send",
                "--urgency=" + urgency,
                "--app-name=" + appName,
                appName,
                message
            ];
        }

        notifier.running = true;
    }
}
