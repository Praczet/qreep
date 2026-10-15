import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: rootKip

    required property QtObject theme
    property bool open: false
    // Stays true through the closing animation; the panel reports when it is done.
    property bool panelLoaded: false
    property var targetScreen: null
    // Dragged body height cap (0 = theme default). Runtime only, like the
    // rest of KIP's state; a Quickshell restart forgets it.
    property real bodyLimit: 0
    // "jarvis" or "mock"; starts from the theme, switchable over IPC for testing.
    property string backend: theme.modules.kip.backend
    readonly property QtObject service: backend === "mock" ? mockService : jarvisService
    readonly property string phase: panelLoader.item ? panelLoader.item.phase : "hidden"

    KipCommands {
        id: kipCommands
    }

    KipMessages {
        id: kipMessages

        tone: rootKip.theme.modules.kip.tone
    }

    KipMockService {
        id: mockService
    }

    KipJarvisService {
        id: jarvisService

        theme: rootKip.theme
    }

    KipScreenshotService {
        id: shotService

        theme: rootKip.theme
    }

    KipFileSearchService {
        id: fileService

        theme: rootKip.theme
    }

    // Opener and clipboard copy run detached: closing KIP must not kill nvim.
    Process {
        id: openRunner
    }

    Process {
        id: copyRunner
    }

    // Cold-start Logseq handling; see logseqColdStartResendDelays in KipTheme.
    property var pendingLogseqCommand: []
    property var pendingLogseqDelays: []
    property real logseqWaitStartedAt: 0

    Timer {
        id: logseqWindowWatch

        interval: 250
        repeat: true
        onTriggered: rootKip.checkLogseqWindow()
    }

    Timer {
        id: logseqResendTimer

        repeat: false
        onTriggered: rootKip.resendLogseqLink()
    }

    // Reads a page's title:: property for Logseq URLs. Small files, read on Enter only.
    FileView {
        id: titleReader

        blockLoading: true
        printErrors: false
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-kip"

        function toggle() {
            rootKip.toggle();
        }

        function showMe() {
            rootKip.show();
        }

        function hideMe() {
            rootKip.hide();
        }

        function state(): string {
            return "open=" + rootKip.open
                + " phase=" + rootKip.phase
                + " service=" + rootKip.service.status
                + " kind=" + (rootKip.service.kind || "-")
                + " results=" + rootKip.service.results.length
                + " answerChars=" + rootKip.service.answer.length
                + " files=" + fileService.status + ":" + fileService.results.slice(0, 5).map(hit => hit.file).join(",")
                + " shots=" + shotService.status + ":" + shotService.shots.map(shot => shot.file).join(",")
                + " error=" + (rootKip.service.errorKind || "-")
                + " backend=" + rootKip.backend
                + " screen=" + (rootKip.targetScreen ? rootKip.targetScreen.name : "none");
        }

        function setBackend(name: string): string {
            if (name !== "jarvis" && name !== "mock")
                return "unknown backend: " + name + " (use jarvis or mock)";

            rootKip.service.reset();
            rootKip.backend = name;
            return "backend=" + name;
        }

        // Headless testing: run a request without the panel, then poll state.
        function run(text: string): string {
            rootKip.submitText(text);
            return "submitted " + rootKip.service.kind;
        }
    }

    LazyLoader {
        id: panelLoader

        active: rootKip.panelLoaded

        KipPanel {
            screen: rootKip.targetScreen
            theme: rootKip.theme
            commands: kipCommands
            messages: kipMessages
            service: rootKip.service
            shots: shotService
            userBodyLimit: rootKip.bodyLimit
            files: fileService
            panelOpen: rootKip.open

            onCloseRequested: rootKip.hide()
            onBodyLimitRequested: limit => rootKip.bodyLimit = limit
            onActionRequested: (item, option) => rootKip.runAction(item, option)
            onCopyRequested: text => rootKip.copyText(text)
            onCloseFinished: {
                if (!rootKip.open)
                    rootKip.panelLoaded = false;
            }
        }
    }

    // Belt and braces: if the panel never reports closed, unload it anyway.
    // A ghost overlay holding the screen is worse than a skipped animation frame.
    Timer {
        id: unloadGuard

        interval: rootKip.theme.modules.kip.closeDuration + 300
        repeat: false
        onTriggered: {
            if (!rootKip.open)
                rootKip.panelLoaded = false;
        }
    }

    function show() {
        unloadGuard.stop();

        // Only pick a monitor for a fresh panel; a reopen mid-close stays put.
        if (!panelLoaded) {
            targetScreen = screenForFocusedMonitor();
            panelLoaded = true;
        }

        open = true;
    }

    function hide() {
        if (!open)
            return;

        open = false;
        service.cancel();
        shotService.cancel();
        fileService.cancel();
        unloadGuard.restart();
    }

    function toggle() {
        if (open)
            hide();
        else
            show();
    }

    // Runs one chooser option (markdownOpeners, screenshotActions, or the plain
    // default opener) for a note hit or a screenshot, then closes KIP.
    function runAction(item, option) {
        const kipTheme = theme.modules.kip;
        const values = {
            path: item.absolutePath,
            line: String(item.line || 1),
            mime: item.mime || "",
            dir: String(item.absolutePath || "").replace(/\/[^\/]*$/, "") || "/"
        };

        if (option.id === "logseq") {
            values.graph = encodeURIComponent(kipTheme.logseqGraph);
            values.page = encodeURIComponent(logseqPageName(item));
        }

        const command = fill(option.command, values);

        if (option.id === "logseq" && !logseqRunning())
            waitForLogseq(command);

        launch(command);
        hide();
    }

    function launch(command) {
        openRunner.command = command;
        openRunner.startDetached();
    }

    function logseqRunning() {
        const appId = theme.modules.kip.logseqAppId.toLowerCase();
        const toplevels = ToplevelManager.toplevels ? ToplevelManager.toplevels.values : [];

        return toplevels.some(toplevel => String(toplevel.appId || "").toLowerCase() === appId);
    }

    // The first launch starts Logseq; the link itself is resent once the window
    // exists and the graph has had a moment to load.
    function waitForLogseq(command) {
        logseqResendTimer.stop();
        pendingLogseqCommand = command;
        pendingLogseqDelays = theme.modules.kip.logseqColdStartResendDelays.slice();
        logseqWaitStartedAt = Date.now();
        logseqWindowWatch.restart();
    }

    function checkLogseqWindow() {
        if (logseqRunning()) {
            logseqWindowWatch.stop();
            scheduleLogseqResend();
            return;
        }

        if (Date.now() - logseqWaitStartedAt > theme.modules.kip.logseqColdStartTimeout) {
            logseqWindowWatch.stop();
            pendingLogseqCommand = [];
        }
    }

    function scheduleLogseqResend() {
        if (pendingLogseqDelays.length === 0) {
            pendingLogseqCommand = [];
            return;
        }

        const delays = pendingLogseqDelays;
        const previous = theme.modules.kip.logseqColdStartResendDelays.length - delays.length;
        const elapsed = previous > 0 ? theme.modules.kip.logseqColdStartResendDelays[previous - 1] : 0;

        // Delays are measured from the window appearing, not from each other.
        logseqResendTimer.interval = Math.max(1, delays.shift() - elapsed);
        pendingLogseqDelays = delays;
        logseqResendTimer.restart();
    }

    function resendLogseqLink() {
        if (pendingLogseqCommand.length === 0)
            return;

        launch(pendingLogseqCommand);
        scheduleLogseqResend();
    }

    // Logseq page name for a file, the way Logseq 0.10 (file graph) names it:
    //   journals/2026_10_14.md         → "Oct 14th, 2026" (default title format)
    //   pages with a title:: property  → that title
    //   pages/Me___Capsule.md          → "Me/Capsule" (:triple-lowbar format)
    function logseqPageName(hit) {
        const journal = /(?:^|\/)journals\/(\d{4})_(\d{2})_(\d{2})\.md$/.exec(hit.path);

        if (journal)
            return journalTitle(Number(journal[1]), Number(journal[2]), Number(journal[3]));

        titleReader.path = hit.absolutePath;
        // A path change starts a new load; wait for it or text() is the previous file.
        titleReader.waitForJob();
        const title = /^title::\s*(.+?)\s*$/m.exec(String(titleReader.text()).split("\n").slice(0, 40).join("\n"));

        if (title)
            return title[1];

        const stem = hit.file.replace(/\.md$/i, "").replace(/___/g, "/");

        try {
            return decodeURIComponent(stem);
        } catch (error) {
            return stem;
        }
    }

    // Logseq's default :journal/page-title-format, "MMM do, yyyy".
    function journalTitle(year, month, day) {
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        const teen = day % 100 >= 11 && day % 100 <= 13;
        const suffix = teen ? "th" : ({
                1: "st",
                2: "nd",
                3: "rd"
            })[day % 10] || "th";

        return months[month - 1] + " " + day + suffix + ", " + year;
    }

    function copyText(text) {
        copyRunner.command = fill(theme.modules.kip.copyCommand, {
            text: text
        });
        copyRunner.startDetached();
    }

    // Substitutes {name} inside each argv item. Values never pass through a shell.
    function fill(template, values) {
        return template.map(part => String(part).replace(/\{(\w+)\}/g, (match, key) => values[key] !== undefined ? values[key] : match));
    }

    // Same routing as Enter in the panel, for IPC tests.
    function submitText(text) {
        const parsed = kipCommands.parse(text);

        if (parsed.mode === "plain")
            service.general(parsed.argument);
        else if (parsed.mode === "ready" && parsed.command.kind === "search" && parsed.argument.length > 0)
            service.search(parsed.argument);
        else if (parsed.mode === "ready" && parsed.command.kind === "ask" && parsed.argument.length > 0)
            service.ask(parsed.argument);
        else if (parsed.mode === "ready" && parsed.command.kind === "files" && parsed.argument.length > 0)
            fileService.search(parsed.argument, parsed.flags.from || "", parsed.flags.hidden === true, false);
        else if (parsed.mode === "ready" && parsed.command.kind === "screenshots")
            shotService.load(Math.max(1, Math.min(theme.modules.kip.maxScreenshots, Number(parsed.argument) || 1)));
    }

    function screenForFocusedMonitor() {
        const monitor = Hyprland.focusedMonitor;

        if (monitor) {
            for (let index = 0; index < Quickshell.screens.length; index++) {
                const candidate = Quickshell.screens[index];

                if (candidate && candidate.name === monitor.name)
                    return candidate;
            }
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }
}
