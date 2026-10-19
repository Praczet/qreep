import QtQuick
import Quickshell
import Quickshell.Io

// /calc: qalc does the maths, KIP shows what qalc understood next to the
// result. qalc will interpret nearly anything ("foo bar" is 1 femtobar·B²),
// so the interpretation is the honest part of the answer.
// -nocurrencies keeps it offline: no exchange-rate fetches, ever.
Item {
    id: rootKipCalcService

    required property QtObject theme

    readonly property QtObject kt: theme.modules.kip

    // idle | busy | done | error
    property string status: "idle"
    property string expression: ""
    property string interpretation: ""
    property string result: ""
    property string errorText: ""
    property string eventKey: ""
    property string markdown: ""
    property int requestId: 0
    property var activeProcess: null

    // History: [{ expression, interpretation, result, time }], newest first,
    // one entry per expression (a repeat moves to the top), capped. Saved on
    // Enter, KIP's own file; rofi-calc's history is left alone.
    readonly property string historyPath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/qreep/kip/calc-history.json"
    readonly property int historyLimit: 200
    property var history: []

    FileView {
        id: historyFile

        path: rootKipCalcService.historyPath
        preload: true
        printErrors: false

        onLoaded: {
            try {
                const parsed = JSON.parse(text() || "[]");
                rootKipCalcService.history = Array.isArray(parsed) ? parsed : [];
            } catch (error) {
                rootKipCalcService.history = [];
            }
        }
    }

    // Shift+Enter on a history row: qalc again, off the live path (the input
    // and the shown result stay as they are). done(fresh | null).
    Component {
        id: recalcComponent

        Process {
            id: recalcProcess

            property var entry: null
            property var done: null

            stdout: StdioCollector {
                id: recalcStdout

                waitForEnd: true
            }

            onExited: exitCode => rootKipCalcService.finishRecalc(recalcProcess, exitCode, recalcStdout.text)
        }
    }

    function recalculate(entry, done) {
        const process = recalcComponent.createObject(rootKipCalcService, {
            entry: entry,
            done: done,
            command: [kt.calcCommand].concat(kt.calcArguments, [entry.expression])
        });

        process.running = true;
    }

    function finishRecalc(process, exitCode, stdoutText) {
        const entry = process.entry;
        const done = process.done;
        const split = splitAnswer(stdoutText).split;

        process.destroy();
        if (exitCode !== 0 || !split || split[1].trim() === split[3].trim()) {
            done(null);
            return;
        }

        const fresh = {
            expression: entry.expression,
            interpretation: split[1].trim(),
            result: split[3].trim().replace(/^approx\.\s*/, "")
        };

        remember(fresh);
        done(fresh);
    }

    // Results that depend on the clock go stale: these get a ↻ chip.
    function timeDependent(entry) {
        return /\b(now|today|yesterday|tomorrow)\b/i.test(entry.expression);
    }

    function remember(entry) {
        const next = [{
                expression: entry.expression,
                interpretation: entry.interpretation || "",
                result: entry.result,
                time: Date.now()
            }].concat(history.filter(item => item.expression !== entry.expression)).slice(0, historyLimit);

        history = next;
        historyFile.setText(JSON.stringify(next, null, 2) + "\n");
    }

    // Every typed word must appear in the expression or the result.
    function filterHistory(text) {
        const words = String(text || "").toLowerCase().split(/\s+/).filter(word => word.length > 0);

        if (words.length === 0)
            return history;
        return history.filter(item => {
            const haystack = (item.expression + " " + item.result).toLowerCase();
            return words.every(word => haystack.indexOf(word) >= 0);
        });
    }

    function ago(time) {
        const minutes = Math.floor((Date.now() - time) / 60000);

        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return minutes + "m";
        if (minutes < 1440)
            return Math.floor(minutes / 60) + "h";
        return Math.floor(minutes / 1440) + "d";
    }

    Component {
        id: qalcComponent

        Process {
            id: qalcProcess

            property int ownerId: -1

            stdout: StdioCollector {
                id: qalcStdout

                waitForEnd: true
            }

            stderr: StdioCollector {
                id: qalcStderr

                waitForEnd: true
            }

            onExited: exitCode => rootKipCalcService.finish(qalcProcess.ownerId, exitCode, qalcStdout.text, qalcStderr.text)
        }
    }

    function evaluate(text) {
        cancel();
        expression = String(text || "").trim();
        interpretation = "";
        result = "";
        errorText = "";

        if (expression.length === 0) {
            status = "idle";
            return;
        }

        status = "busy";

        // One argv item; "--" is not needed, qalc takes the rest as the expression.
        const process = qalcComponent.createObject(rootKipCalcService, {
            ownerId: requestId,
            command: [kt.calcCommand].concat(kt.calcArguments, [expression])
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
        expression = "";
        interpretation = "";
        result = "";
        errorText = "";
        eventKey = "";
        markdown = "";
    }

    // qalc puts "warning: …" / "error: …" lines before the answer line.
    // split: "(2^10) * 3 = 3072", "sqrt(2) = approx. 1.414213562", or "≈".
    function splitAnswer(stdoutText) {
        const lines = String(stdoutText).trim().split("\n");
        const output = lines.filter(line => !/^(warning|error):/i.test(line.trim())).join(" ").trim();

        return {
            warnings: lines.filter(line => /^(warning|error):/i.test(line.trim())),
            output: output,
            split: /^([\s\S]*?)\s(=|≈)\s([\s\S]*)$/.exec(output)
        };
    }

    function finish(ownerId, exitCode, stdoutText, stderrText) {
        if (ownerId !== requestId)
            return;

        const process = activeProcess;

        activeProcess = null;
        if (process)
            process.destroy();

        const answer = splitAnswer(stdoutText);
        const warnings = answer.warnings;
        const output = answer.output;
        const split = answer.split;

        if (exitCode !== 0 || output.length === 0) {
            status = "error";
            errorText = String(stderrText).trim() || output || "qalc returned nothing.";
            eventKey = "calc.error";
            markdown = "qalc could not evaluate `" + expression + "`.\n\n" + errorText;
            return;
        }

        // No "=", or "x = x": qalc could not reduce it (1/0, plain words).
        if (!split || split[1].trim() === split[3].trim()) {
            status = "error";
            errorText = warnings.length > 0 ? warnings.join(" ") : output;
            eventKey = "calc.error";
            markdown = "qalc did not reduce it to a value; it read it as `" + (split ? split[1].trim() : output) + "`."
                + (warnings.length > 0 ? "\n\n" + warnings.map(line => "- " + line.trim()).join("\n") : "");
            return;
        }

        const approximate = split[2] === "≈" || /^approx\.\s*/.test(split[3].trim());

        interpretation = split[1].trim();
        result = split[3].trim().replace(/^approx\.\s*/, "");
        status = "done";
        eventKey = "calc.found";
        markdown = "## " + (approximate ? "≈ " : "") + result + "\n\nqalc read it as `" + interpretation + "`" + (approximate ? ", approximate." : ".")
            + (warnings.length > 0 ? "\n\n" + warnings.map(line => "- " + line.trim()).join("\n") : "");
    }
}
