import QtQuick
import Quickshell.Io
import "../../core" as Core

QtObject {
    id: rootPolkitService

    property QtObject log
    property string title: "System Authentication"
    property string sourceLabel: "System policy"
    property string iconName: "dialog-password-symbolic"
    property string userName: "adam"
    property string message: "Authentication is required to perform a privileged action."
    property string detailText: ""
    property string actionId: ""
    property string inputPrompt: "Password"
    property string statusText: ""
    property bool authenticated: false
    property bool requestActive: false
    property bool terminalLogged: false
    property string requestCaller: ""
    property int failedAttempts: 0
    property string artworkSource: ""

    readonly property Core.Log fallbackLog: Core.Log {}
    readonly property string assetDirUrl: Qt.resolvedUrl("../../assets")
    readonly property string assetDir: localPath(assetDirUrl)
    readonly property var fallbackArtworkSources: [
        Qt.resolvedUrl("../../assets/icon_dragon.webp"),
        Qt.resolvedUrl("../../assets/icon_gorilla.webp"),
        Qt.resolvedUrl("../../assets/icon_cookie.webp"),
        Qt.resolvedUrl("../../assets/icon_turtle_blue_sad.webp"),
        Qt.resolvedUrl("../../assets/icon_woman_city.webp"),
        Qt.resolvedUrl("../../assets/icon_woman_reading_pinker.webp"),
        Qt.resolvedUrl("../../assets/icon_woman_wall.webp")
    ]

    readonly property Process artworkReader: Process {
        stdout: StdioCollector {
            id: artworkStdout
        }

        stderr: StdioCollector {
            id: artworkStderr
        }

        onExited: (exitCode, exitStatus) => rootPolkitService.applyArtworkOutput(artworkStdout.text, artworkStderr.text, exitCode)
    }

    function loadDemo(caller) {
        title = "Install System Updates";
        sourceLabel = "System policy preview";
        iconName = "dialog-password-symbolic";
        userName = "adam";
        message = "Authentication is required to install system packages.";
        detailText = "Preview mode. Qreep is not the active Polkit agent yet, and no privileged command will run.";
        actionId = "org.qreep.demo.install-updates";
        inputPrompt = "Password";
        statusText = "";
        authenticated = false;
        requestActive = true;
        terminalLogged = false;
        requestCaller = String(caller || "unknown");
        failedAttempts = 0;

        chooseFallbackArtwork();
        refreshArtwork();
        info("Polkit request called:", auditFields());
    }

    function submitDemo(password) {
        if (String(password || "").length === 0) {
            statusText = "Password required.";
            authenticated = false;
            recordFailedAttempt("empty-password");
            return false;
        }

        statusText = "Demo accepted. No privileged action was run.";
        authenticated = true;
        finish("success", "demo-submit");
        return true;
    }

    function fail(reason) {
        finish("failed", reason || "authentication-failed");
    }

    function cancel(reason) {
        finish("cancel", reason || "cancel");
    }

    function clear() {
        statusText = "";
        authenticated = false;
        requestActive = false;
        terminalLogged = false;
        requestCaller = "";
        failedAttempts = 0;
    }

    function recordFailedAttempt(reason) {
        if (!requestActive || terminalLogged)
            return;

        failedAttempts += 1;
        info("Polkit authentication failed:", "attempts=" + failedAttempts, "reason=" + String(reason || "failed"), auditFields());
    }

    function refreshArtwork() {
        if (assetDir.length === 0)
            return;

        artworkReader.running = false;
        artworkReader.command = ["find", assetDir, "-maxdepth", "1", "-type", "f"];
        artworkReader.running = true;
    }

    function applyArtworkOutput(stdout, stderr, exitCode) {
        if (exitCode !== 0) {
            info("Polkit artwork lookup failed:", String(stderr || "").trim());
            return;
        }

        const imagePaths = String(stdout || "").split("\n")
            .map(path => path.trim())
            .filter(path => /^icon_.*\.(webp|png|jpe?g)$/i.test(fileName(path)));

        if (imagePaths.length === 0) {
            artworkSource = "";
            return;
        }

        artworkSource = "file://" + imagePaths[Math.floor(Math.random() * imagePaths.length)];
    }

    function chooseFallbackArtwork() {
        if (fallbackArtworkSources.length === 0)
            return;

        artworkSource = fallbackArtworkSources[Math.floor(Math.random() * fallbackArtworkSources.length)];
    }

    function finish(outcome, reason) {
        if (!requestActive || terminalLogged)
            return;

        terminalLogged = true;
        requestActive = false;
        info("Polkit request ended:", "outcome=" + outcome, "reason=" + String(reason || outcome), "failedAttempts=" + failedAttempts, auditFields());
    }

    function auditFields() {
        return "caller=" + requestCaller
            + " source=" + sourceLabel
            + " action=" + actionId
            + " user=" + userName
            + " title=" + title;
    }

    function info() {
        (log || fallbackLog).info.apply(null, arguments);
    }

    function localPath(url) {
        const value = String(url || "");

        if (value.indexOf("file://") === 0)
            return decodeURIComponent(value.slice(7));

        return value;
    }

    function fileName(path) {
        const value = String(path || "");
        const slashIndex = value.lastIndexOf("/");

        return slashIndex === -1 ? value : value.slice(slashIndex + 1);
    }
}
