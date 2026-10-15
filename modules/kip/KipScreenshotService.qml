import QtQuick
import Quickshell.Io

// /last: newest files in the screenshot folder, by modification time.
// Local only, no Jarvis. Lists with find(1) as plain argv.
Item {
    id: rootKipScreenshotService

    required property QtObject theme

    readonly property QtObject kt: theme.modules.kip

    // idle | loading | done | empty | error
    property string status: "idle"
    property int requested: 1
    property var shots: []
    property string errorText: ""
    property string eventKey: ""
    property int requestId: 0

    readonly property var imageTypes: ({
            png: "image/png",
            jpg: "image/jpeg",
            jpeg: "image/jpeg",
            webp: "image/webp"
        })

    property var activeProcess: null

    // One Process per listing, so a refresh while typing never has to restart
    // a running one; stale exits are ignored by request id.
    Component {
        id: listProcessComponent

        Process {
            id: listProcess

            property int ownerId: -1

            stdout: StdioCollector {
                id: listStdout

                waitForEnd: true
            }

            stderr: StdioCollector {
                id: listStderr

                waitForEnd: true
            }

            onExited: exitCode => rootKipScreenshotService.finish(listProcess.ownerId, exitCode, listStdout.text, listStderr.text)
        }
    }

    function load(count) {
        reset();
        eventKey = "last.loading";
        refresh(count);
    }

    // Re-list without clearing what is shown: the old shots stay until the new
    // list lands, and an unchanged eventKey does not reroll KIP's comment.
    function refresh(count) {
        cancel();
        requested = count;
        status = "loading";

        // %T@ = mtime as epoch seconds, then the path; one file per line.
        const process = listProcessComponent.createObject(rootKipScreenshotService, {
            ownerId: requestId,
            command: ["find", kt.screenshotDir, "-maxdepth", "1", "-type", "f", "-printf", "%T@\t%p\n"]
        });

        activeProcess = process;
        process.running = true;
    }

    function cancel() {
        requestId++;
        releaseProcess();
    }

    function releaseProcess() {
        if (!activeProcess)
            return;

        const process = activeProcess;

        activeProcess = null;
        process.running = false;
        process.destroy();
    }

    function reset() {
        cancel();
        status = "idle";
        shots = [];
        errorText = "";
        eventKey = "";
    }

    function finish(ownerId, exitCode, stdoutText, stderrText) {
        if (ownerId !== requestId)
            return;

        releaseProcess();

        if (exitCode !== 0) {
            status = "error";
            errorText = String(stderrText).trim().split("\n").pop() || ("find exited with code " + exitCode);
            eventKey = "last.error";
            return;
        }

        const files = [];

        for (const line of String(stdoutText).split("\n")) {
            const tab = line.indexOf("\t");

            if (tab <= 0)
                continue;

            const path = line.slice(tab + 1);
            const extension = path.slice(path.lastIndexOf(".") + 1).toLowerCase();

            if (!imageTypes[extension])
                continue;

            files.push({
                absolutePath: path,
                file: path.slice(path.lastIndexOf("/") + 1),
                mime: imageTypes[extension],
                modified: Number(line.slice(0, tab)) * 1000
            });
        }

        files.sort((left, right) => right.modified - left.modified);
        shots = files.slice(0, requested);

        status = shots.length > 0 ? "done" : "empty";
        eventKey = shots.length > 0 ? "last.found" : "last.empty";
    }

    function age(modified) {
        const seconds = Math.max(0, Math.round((Date.now() - modified) / 1000));

        if (seconds < 60)
            return seconds + " s ago";
        if (seconds < 3600)
            return Math.round(seconds / 60) + " min ago";
        if (seconds < 86400)
            return Math.round(seconds / 3600) + " h ago";
        return Math.round(seconds / 86400) + " d ago";
    }
}
