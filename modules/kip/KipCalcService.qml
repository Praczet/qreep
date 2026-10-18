import QtQuick
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

    function finish(ownerId, exitCode, stdoutText, stderrText) {
        if (ownerId !== requestId)
            return;

        const process = activeProcess;

        activeProcess = null;
        if (process)
            process.destroy();

        // qalc puts "warning: …" / "error: …" lines before the answer line.
        const lines = String(stdoutText).trim().split("\n");
        const warnings = lines.filter(line => /^(warning|error):/i.test(line.trim()));
        const output = lines.filter(line => !/^(warning|error):/i.test(line.trim())).join(" ").trim();
        // "(2^10) * 3 = 3072", "sqrt(2) = approx. 1.414213562", or "≈".
        const split = /^([\s\S]*?)\s(=|≈)\s([\s\S]*)$/.exec(output);

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
