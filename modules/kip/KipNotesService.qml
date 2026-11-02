import QtQuick
import Quickshell
import Quickshell.Io

// /kip: runs the kip command. One request at a time, argv only, no shell.
QtObject {
    id: rootKipNotesService

    property string binary: "kip"
    property string status: "idle" // idle | running | done | error
    property string error: ""
    property var document: null
    property bool saving: false

    signal saved()
    signal listed()
    signal failed(string message)

    function save(args) {
        start(args, true);
    }

    function list(args) {
        start(args, false);
    }

    function start(args, isSave) {
        if (runner.running)
            runner.running = false;
        saving = isSave;
        status = "running";
        error = "";
        runner.command = [binary].concat(args);
        runner.running = true;
    }

    function finish(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0) {
            const reason = String(stderrText || "").trim();
            fail(reason.length > 0 ? reason : "kip exited with " + exitCode + ". Nothing was saved.");
            return;
        }
        status = "done";
        if (saving) {
            saved();
            return;
        }
        try {
            document = JSON.parse(String(stdoutText || ""));
            listed();
        } catch (parseError) {
            fail("kip did not return JSON.");
        }
    }

    function fail(message) {
        status = "error";
        error = message;
        failed(message);
    }

    readonly property Process runner: Process {
        stdout: StdioCollector {
            id: runnerStdout

            waitForEnd: true
        }
        stderr: StdioCollector {
            id: runnerStderr

            waitForEnd: true
        }
        onExited: (exitCode, exitStatus) => rootKipNotesService.finish(runnerStdout.text, runnerStderr.text, exitCode)
    }
}
