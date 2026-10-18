import QtQuick

// /run as the panel sees it: history picking, the preview text, the danger
// arm, and what Enter means. KipRunService does the actual inspecting and
// running. host is KipPanel: contentState, parsed, notice and the answer
// viewer stay there; this file only reads and sets them.
Item {
    id: rootKipRunCommand

    required property QtObject host
    required property QtObject runner

    readonly property bool active: host.contentState === "run"
    property int index: 0
    // Up/Down moved through history: the next Enter fills the input, not runs.
    property bool picking: false
    // Dangerous command: first Enter arms, the second runs it.
    property string armedFor: ""

    readonly property string eventKey: armedFor.length > 0 ? "run.danger" : (runner.eventKey || "run.ready")

    // Inspects the command word after a pause, not per keystroke.
    Timer {
        id: inspectTimer

        interval: rootKipRunCommand.host.kt.runDebounce
        repeat: false
        onTriggered: {
            if (rootKipRunCommand.active)
                rootKipRunCommand.runner.inspect(rootKipRunCommand.host.parsed.argument);
        }
    }

    Connections {
        target: rootKipRunCommand.runner

        function onInspectStatusChanged() {
            if (rootKipRunCommand.active)
                rootKipRunCommand.refreshPreview();
        }

        function onRunStatusChanged() {
            if (!rootKipRunCommand.active)
                return;
            // Background run still going after 2 s: it started, KIP is done.
            if (rootKipRunCommand.runner.runStatus === "started" || (rootKipRunCommand.runner.runStatus === "exited" && rootKipRunCommand.runner.output.length === 0))
                rootKipRunCommand.host.closeRequested();
            else
                rootKipRunCommand.refreshPreview();
        }
    }

    function reset() {
        runner.reset();
        picking = false;
        armedFor = "";
    }

    // Typing in /run: history narrows, the command word is inspected after a
    // pause, and any armed danger confirmation is dropped.
    function show() {
        if (!active) {
            host.backToCompose();
            host.contentState = "run";
        }
        picking = false;
        armedFor = "";
        if (runner.runStatus !== "running")
            runner.runStatus = "idle";
        runner.filter(host.parsed.argument);
        index = 0;
        inspectTimer.restart();
        refreshPreview();
    }

    function refreshPreview() {
        host.docMarkdown = previewMarkdown();
        host.renderAnswer();
    }

    function previewMarkdown() {
        const text = host.parsed.argument;
        const word = runner.commandWord(text);

        if (runner.runStatus === "failed" || runner.runStatus === "exited") {
            const heading = runner.runStatus === "failed" ? "## Exited with code " + runner.exitCode : "## Finished";

            return heading + "\n\n`" + text + "`" + (runner.output.length > 0 ? "\n\n```text\n" + runner.output + "\n```" : "\n\nNo output.");
        }

        if (word.length === 0)
            return "Type a command. History matches appear above as you type.";
        if (runner.inspectStatus !== "done" || runner.inspectedWord !== word)
            return "Checking `" + word + "`…";
        if (runner.commandType.length === 0)
            return "## Not found: `" + word + "`\n\nNot a command, alias or function in your shell. Enter does nothing.";

        const lines = [];

        lines.push(runner.mode === "terminal" ? "## Opens in Ghostty" : "## Runs in the background");
        lines.push("", "`" + text + "`", "", "Because " + runner.reason + ".");
        if (runner.dangerous)
            lines.push("", "> **cinfo marks `" + word + "` as dangerous.** Enter arms it, a second Enter runs it.");
        if (runner.info.length > 0)
            lines.push("", "```text", runner.info.slice(0, 6).join("\n"), "```");
        lines.push("", "_Shift+Enter: " + (runner.mode === "terminal" ? "run in the background instead" : "open in Ghostty instead") + ", and remember that for `" + word + "`._");
        return lines.join("\n");
    }

    function pick() {
        const entry = runner.matches[index];

        if (!entry)
            return;

        // Into the input, not straight to a shell: you see its preview first.
        host.setInput("/" + host.parsed.token + " " + entry.command);
    }

    function forget() {
        const entry = runner.matches[index];

        if (!entry)
            return;

        runner.forget(entry.command);
        host.notice = "Removed from history: " + entry.command;
        runner.filter(host.parsed.argument);
        index = host.clampIndex(index, runner.matches.length);
        if (runner.matches.length === 0)
            picking = false;
    }

    function submit(flip) {
        if (picking) {
            picking = false;
            pick();
            return;
        }

        const text = host.parsed.argument;
        const word = runner.commandWord(text);

        if (word.length === 0)
            return;
        if (runner.inspectStatus !== "done" || runner.inspectedWord !== word) {
            host.notice = "Still checking " + word + "; Enter again in a moment.";
            return;
        }
        if (runner.commandType.length === 0) {
            host.notice = word + " is not a command here.";
            return;
        }
        if (runner.dangerous && armedFor !== text) {
            armedFor = text;
            host.notice = "Dangerous per cinfo. Enter again to run: " + text;
            return;
        }

        armedFor = "";
        host.notice = "";
        if (runner.run(text, flip))
            host.closeRequested();
    }

    // True when the key was /run's: Up/Down through history, Ctrl+Delete to
    // forget the picked entry.
    function handleKey(event) {
        if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && runner.matches.length > 0) {
            const step = event.key === Qt.Key_Down ? 1 : -1;

            index = picking ? host.clampIndex(index + step, runner.matches.length) : 0;
            picking = true;
            event.accepted = true;
            return true;
        }

        if (event.key === Qt.Key_Delete && picking && (event.modifiers & Qt.ControlModifier)) {
            event.accepted = true;
            forget();
            return true;
        }

        return false;
    }

    function enterLabel() {
        if (picking)
            return "use";
        if (runner.inspectStatus !== "done" || runner.commandType.length === 0)
            return "";
        return armedFor.length > 0 ? "run anyway" : (runner.mode === "terminal" ? "run in ghostty" : "run");
    }

    function keyHints() {
        if (picking)
            return "↑↓ history · Enter puts it in the input · Ctrl+Delete forgets it · Esc back";
        return "Enter run · Shift+Enter the other way · ↑↓ history · Esc back";
    }
}
