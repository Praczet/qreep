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
    property bool responseVisible: false
    property bool responseRequired: true
    property bool requestActive: false
    property bool realRequestActive: false
    property bool terminalLogged: false
    property string requestCaller: ""
    property int failedAttempts: 0
    property string artworkSource: ""
    property bool agentRegistered: false
    property var activeFlow: null
    property bool previousFailed: false

    readonly property Core.Log fallbackLog: Core.Log {}
    readonly property string projectRoot: localPath(Qt.resolvedUrl("../.."))
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
        responseVisible = false;
        responseRequired = true;
        requestActive = true;
        realRequestActive = false;
        terminalLogged = false;
        requestCaller = String(caller || "unknown");
        failedAttempts = 0;
        activeFlow = null;
        previousFailed = false;

        chooseFallbackArtwork();
        refreshArtwork();
        info("Polkit request called:", auditFields());
    }

    function loadFlow(flow, caller) {
        if (!flow)
            return;

        if (activeFlow === flow && requestActive) {
            syncFlow();
            return;
        }

        activeFlow = flow;
        realRequestActive = true;
        requestActive = true;
        terminalLogged = false;
        requestCaller = String(caller || "polkit-agent");
        failedAttempts = 0;
        previousFailed = !!flow.failed;
        authenticated = false;
        responseVisible = false;
        responseRequired = false;

        chooseFallbackArtwork();
        refreshArtwork();
        syncFlow();
        info("Polkit request called:", auditFields(), flowStateFields(), identityDebugFields());
    }

    function submitResponse(password) {
        if (realRequestActive)
            return submitFlow(password);

        return submitDemo(password);
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

    function submitFlow(password) {
        if (!activeFlow) {
            recordFailedAttempt("missing-flow");
            statusText = "Authentication request disappeared.";
            return false;
        }

        if (!activeFlow.isResponseRequired) {
            statusText = "Waiting for Polkit prompt.";
            info("Polkit response blocked:", "reason=response-not-required", flowStateFields());
            return false;
        }

        if (String(password || "").length === 0) {
            statusText = "Password required.";
            recordFailedAttempt("empty-password");
            return false;
        }

        statusText = "";
        info("Polkit response submitted:", flowStateFields());
        activeFlow.submit(password);
        return false;
    }

    function fail(reason) {
        finish("failed", reason || "authentication-failed");
    }

    function cancel(reason) {
        if (realRequestActive && activeFlow && !terminalLogged)
            activeFlow.cancelAuthenticationRequest();

        finish("cancel", reason || "cancel");
    }

    function clear() {
        statusText = "";
        authenticated = false;
        responseVisible = false;
        responseRequired = false;
        requestActive = false;
        realRequestActive = false;
        terminalLogged = false;
        requestCaller = "";
        failedAttempts = 0;
        activeFlow = null;
        previousFailed = false;
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

    function syncFlow() {
        const flow = activeFlow;

        if (!flow)
            return;

        title = titleForFlow(flow);
        sourceLabel = agentRegistered ? "System policy" : "System policy (not registered)";
        iconName = stringValue(flow.iconName, "dialog-password-symbolic");
        userName = identityLabel(flow.selectedIdentity);
        message = stringValue(flow.message, "Authentication is required to perform a privileged action.");
        actionId = stringValue(flow.actionId, "");
        inputPrompt = stringValue(flow.inputPrompt, "Password");
        authenticated = !!flow.isSuccessful;
        responseVisible = !!flow.responseVisible;
        responseRequired = !!flow.isResponseRequired;

        if (flow.supplementaryIsError) {
            statusText = stringValue(flow.supplementaryMessage, flow.failed ? "Authentication failed." : "");
            detailText = "";
        } else {
            statusText = "";
            detailText = stringValue(flow.supplementaryMessage, "");
        }

        if (flow.failed && !previousFailed) {
            recordFailedAttempt("polkit-flow");
            previousFailed = true;
        } else if (!flow.failed) {
            previousFailed = false;
        }
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
        realRequestActive = false;
        info("Polkit request ended:", "outcome=" + outcome, "reason=" + String(reason || outcome), "failedAttempts=" + failedAttempts, auditFields(), flowStateFields(), identityDebugFields());
    }

    function auditFields() {
        return "caller=" + requestCaller
            + " source=" + sourceLabel
            + " action=" + actionId
            + " user=" + userName
            + " title=" + title;
    }

    function flowStateFields() {
        if (!activeFlow)
            return "flow=missing";

        return "responseRequired=" + activeFlow.isResponseRequired
            + " prompt=" + stringValue(activeFlow.inputPrompt, "")
            + " responseVisible=" + activeFlow.responseVisible
            + " completed=" + activeFlow.isCompleted
            + " successful=" + activeFlow.isSuccessful
            + " cancelled=" + activeFlow.isCancelled
            + " failed=" + activeFlow.failed
            + " supplementaryIsError=" + activeFlow.supplementaryIsError
            + " supplementary=" + compactLogValue(activeFlow.supplementaryMessage)
            + " action=" + actionId
            + " user=" + userName;
    }

    function flowCompletedCleanly() {
        return activeFlow
            && activeFlow.isCompleted
            && !activeFlow.isCancelled
            && !activeFlow.failed
            && !activeFlow.supplementaryIsError;
    }

    function identityDebugFields() {
        if (!activeFlow)
            return "identity=missing";

        const identities = activeFlow.identities || [];

        return "identity=" + compactLogValue(identityObjectFields(activeFlow.selectedIdentity))
            + " identities=" + identities.length;
    }

    function logFlowEvent(prefix) {
        info(prefix, flowStateFields(), identityDebugFields());
    }

    function info() {
        (log || fallbackLog).info.apply(null, arguments);
    }

    function setRegistrationState(registered) {
        if (agentRegistered === !!registered)
            return;

        agentRegistered = !!registered;
        info("Polkit agent registration:", agentRegistered ? "registered" : "not-registered");
    }

    function logCommand() {
        return "quickshell --path " + shellQuote(projectRoot) + " log --tail 120";
    }

    function logPathCommand() {
        return "find \"/run/user/$UID/quickshell/by-id\" -name log.qslog -print | xargs -r ls -t | head -n 1";
    }

    function titleForFlow(flow) {
        const action = stringValue(flow.actionId, "");
        const text = stringValue(flow.message, "");

        if (action.indexOf("package") !== -1 || action.indexOf("pacman") !== -1 || text.toLowerCase().indexOf("package") !== -1)
            return "Install System Updates";

        if (action.length > 0)
            return "Authorize System Action";

        return "System Authentication";
    }

    function identityLabel(identity) {
        if (identity === null || identity === undefined)
            return "selected user";

        if (typeof identity === "string")
            return identity;

        const fields = ["name", "userName", "username", "displayName", "label", "toString"];

        for (let index = 0; index < fields.length; index++) {
            const field = fields[index];
            const value = identity[field];

            if (typeof value === "function" && field === "toString") {
                const label = String(value.call(identity) || "");
                if (label.length > 0 && label !== "[object Object]")
                    return label;
            } else if (value !== undefined && value !== null && String(value).length > 0) {
                return String(value);
            }
        }

        return "selected user";
    }

    function identityObjectFields(identity) {
        if (identity === null || identity === undefined)
            return "null";

        const fields = ["name", "userName", "username", "displayName", "label", "uid", "gid"];
        const parts = [];

        for (let index = 0; index < fields.length; index++) {
            const field = fields[index];
            const value = identity[field];

            if (value !== undefined && value !== null && String(value).length > 0)
                parts.push(field + "=" + String(value));
        }

        const label = identityLabel(identity);
        if (label.length > 0)
            parts.push("label=" + label);

        return parts.length > 0 ? parts.join(",") : String(identity);
    }

    function stringValue(value, fallback) {
        const text = String(value === undefined || value === null ? "" : value);

        return text.length > 0 ? text : fallback;
    }

    function compactLogValue(value) {
        return "\"" + String(value === undefined || value === null ? "" : value).replace(/\s+/g, " ").trim() + "\"";
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

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\\''") + "'";
    }
}
