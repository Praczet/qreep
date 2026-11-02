import QtQuick
import Quickshell
import Quickshell.Io

// /ask-claude: one question through `claude -p` (KipTheme.claudeCommand), on
// the Claude plan's login and limits, which Claude Code shares. Same surface as
// the other answer services, so the panel renders it like any other answer.
//
// Web search is the only tool it gets, so it cannot read or change local files.
// An ANTHROPIC_API_KEY in the environment would silently switch `claude -p` to
// API billing, so the process never sees one.
Item {
    id: rootKipClaudeService

    required property QtObject theme

    readonly property bool mock: false
    readonly property string providerLabel: "Claude"
    readonly property QtObject kt: theme.modules.kip

    // idle | generating | done | error
    property string status: "idle"
    property string kind: ""
    property string query: ""
    readonly property var results: []
    readonly property var rawSources: []
    readonly property bool explain: false
    property string answer: ""
    property string errorText: ""
    // limit | auth | malformed | claude | claude-missing
    property string errorKind: ""
    property string eventKey: ""
    property string model: ""
    property int requestId: 0
    property bool backendAvailable: true

    readonly property bool busy: status === "generating"

    property var activeProcess: null
    property int malformedLines: 0

    Component {
        id: streamProcessComponent

        Process {
            id: streamProcess

            property int ownerId: -1

            workingDirectory: "/tmp"
            environment: ({
                    ANTHROPIC_API_KEY: null,
                    ANTHROPIC_AUTH_TOKEN: null
                })

            stdout: SplitParser {
                onRead: data => rootKipClaudeService.handleStreamLine(streamProcess.ownerId, data)
            }

            stderr: StdioCollector {
                id: streamStderr

                waitForEnd: true
            }

            onExited: exitCode => rootKipClaudeService.finishStream(streamProcess.ownerId, exitCode, streamStderr.text)
        }
    }

    Process {
        id: availabilityProcess

        command: ["/usr/bin/which", rootKipClaudeService.kt.claudeCommand[0]]
        running: true

        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: exitCode => rootKipClaudeService.backendAvailable = exitCode === 0
    }

    function general(text) {
        reset();
        kind = "claude";
        query = text;
        status = "generating";
        eventKey = "general.generating";

        if (!backendAvailable) {
            fail("claude-missing", "'" + kt.claudeCommand[0] + "' is not on PATH for Quickshell.");
            availabilityProcess.running = true;
            return;
        }

        const process = streamProcessComponent.createObject(rootKipClaudeService, {
            ownerId: requestId,
            command: kt.claudeCommand.concat([text])
        });

        activeProcess = process;
        process.running = true;
    }

    function cancel() {
        requestId++;

        if (activeProcess) {
            const process = activeProcess;

            activeProcess = null;
            process.running = false;
            process.destroy();
        }
    }

    function reset() {
        cancel();
        status = "idle";
        kind = "";
        query = "";
        answer = "";
        errorText = "";
        errorKind = "";
        eventKey = "";
        model = "";
        malformedLines = 0;
    }

    function handleStreamLine(ownerId, line) {
        if (ownerId !== requestId)
            return;

        const trimmed = String(line).trim();

        if (trimmed.length === 0)
            return;

        let event = null;

        try {
            event = JSON.parse(trimmed);
        } catch (error) {
            malformedLines++;
            return;
        }

        if (event.type === "system" && event.subtype === "init")
            model = event.model || "";
        else if (event.type === "stream_event" && !event.parent_tool_use_id)
            handlePartial(event.event || {});
        else if (event.type === "result")
            finishResult(event);
        // Everything else is ignored on purpose: newer claude, older KIP.
    }

    function handlePartial(partial) {
        if (partial.type === "content_block_delta" && partial.delta && partial.delta.type === "text_delta")
            answer += partial.delta.text || "";
        // Text before a tool call is "let me search", not the answer.
        else if (partial.type === "content_block_start" && partial.content_block && partial.content_block.type === "tool_use")
            answer = "";
    }

    function finishResult(event) {
        if (event.is_error || event.subtype !== "success") {
            const detail = String(event.result || (Array.isArray(event.errors) ? event.errors.join(" ") : "") || "Claude reported an error.");

            if (/limit/i.test(detail))
                fail("limit", detail);
            else if (/log.?in/i.test(detail))
                fail("auth", detail + " Run claude in a terminal to sign in.");
            else
                fail("claude", detail);
            return;
        }

        const finalAnswer = String(event.result || "");

        if (finalAnswer.length === 0) {
            fail("malformed", "Claude finished without an answer.");
            return;
        }

        // The result is the whole final message; deltas were only the preview.
        answer = finalAnswer;
        status = "done";
        eventKey = "general.completed";
    }

    function finishStream(ownerId, exitCode, stderrText) {
        if (ownerId !== requestId)
            return;

        if (activeProcess) {
            const process = activeProcess;

            activeProcess = null;
            process.destroy();
        }

        // A result already arrived; the exit is just the process leaving.
        if (!busy)
            return;

        const lines = String(stderrText || "").trim().split("\n");
        const detail = lines[lines.length - 1].slice(0, 300);

        if (malformedLines > 0)
            fail("malformed", "claude printed something that is not JSON." + (detail ? " stderr: " + detail : ""));
        else if (exitCode !== 0)
            fail("claude", "claude exited with code " + exitCode + "." + (detail ? " " + detail : ""));
        else
            fail("malformed", "claude finished without a result.");
    }

    function fail(nextKind, message) {
        status = "error";
        errorKind = nextKind;
        errorText = message;
        eventKey = nextKind === "malformed" ? "error.malformed" : "error.backend";
    }

    function citedAnswer(text) {
        return text;
    }
}
