import QtQuick
import Quickshell
import Quickshell.Io

// /run: runs what you typed, rofi-runner style. Shares rofi-runner's history
// file, so F2 and /run see the same commands. Decides terminal vs background
// from (in order): your remembered choice, the script's "# %terminal:" header,
// the .desktop Terminal= line, GUI libraries in an ELF binary. Unknown runs in
// the background, and output/errors from a quick exit are shown.
//
// Only text typed into KIP is ever run. Nothing else in KIP fills this in.
Item {
    id: rootKipRunService

    required property QtObject theme

    readonly property QtObject kt: theme.modules.kip
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME").length > 0 ? Quickshell.env("XDG_STATE_HOME") : Quickshell.env("HOME") + "/.local/state"
    readonly property string historyPath: stateHome + "/rofi-runner/history"
    readonly property string modesPath: stateHome + "/qreep/kip/run-modes.json"

    property var history: []
    property var matches: []
    property var modes: ({})

    // Inspection of the command word: idle | busy | done
    property string inspectStatus: "idle"
    property string inspectedWord: ""
    // alias | function | builtin | file | keyword | "" (not found)
    property string commandType: ""
    // terminal | background
    property string mode: "background"
    property string reason: ""
    property bool remembered: false
    property bool dangerous: false
    property var info: []
    property int inspectId: 0

    // Last run: idle | running | started | exited | failed
    property string runStatus: "idle"
    property int exitCode: 0
    property string output: ""
    property string eventKey: ""

    FileView {
        id: historyFile

        path: rootKipRunService.historyPath
        watchChanges: true
        printErrors: false

        onLoaded: rootKipRunService.history = String(text()).split("\n").map(line => line.trim()).filter(line => line.length > 0)
        onFileChanged: reload()
    }

    FileView {
        id: modesFile

        path: rootKipRunService.modesPath
        printErrors: false

        onLoaded: {
            try {
                rootKipRunService.modes = JSON.parse(text() || "{}");
            } catch (error) {
                rootKipRunService.modes = {};
            }
        }
    }

    // One bash -ic, so aliases and functions from your shell count, exactly
    // like rofi-runner's check. The command word arrives as $1, never inside
    // the script text.
    readonly property string inspectScript: [
        "cmd=$1",
        "t=$(type -t -- \"$cmd\" 2>/dev/null)",
        "echo \"TYPE $t\"",
        "if [ \"$t\" = file ]; then",
        "  p=$(type -P -- \"$cmd\")",
        "  h=$(head -c 4096 -- \"$p\" 2>/dev/null | grep -a -m1 -oE '^# %terminal: *(true|false)' | awk '{print $3}')",
        "  if [ -n \"$h\" ]; then echo \"CLASS header $h\"",
        "  else",
        "    d=$(grep -lsF -e \"Exec=$cmd \" -e \"Exec=$p \" /usr/share/applications/*.desktop \"$HOME\"/.local/share/applications/*.desktop; grep -lsxF -e \"Exec=$cmd\" -e \"Exec=$p\" /usr/share/applications/*.desktop \"$HOME\"/.local/share/applications/*.desktop)",
        "    d=$(printf '%s\\n' \"$d\" | head -1)",
        "    dt=\"\"; [ -n \"$d\" ] && dt=$(grep -m1 -oE '^Terminal=(true|false)' \"$d\" | cut -d= -f2)",
        "    if [ -n \"$dt\" ]; then echo \"CLASS desktop $dt ${d##*/}\"",
        "    elif file -bL -- \"$p\" | grep -q ELF; then",
        "      if ldd -- \"$p\" 2>/dev/null | grep -qiE 'libgtk|libQt[56]|libwayland-client|libX11|libSDL|libgdk'; then echo 'CLASS libs gui'; else echo 'CLASS libs cli'; fi",
        "    else echo 'CLASS unknown'; fi",
        "  fi",
        "fi",
        "echo INFO",
        "cinfo \"$cmd\" 2>/dev/null | sed -E 's/\\x1B\\[[0-9;]*[[:alpha:]]//g' | head -12"
    ].join("\n")

    // Background runs in its own session (setsid), so a Quickshell reload
    // cannot kill it. The wrapper watches for 2 s: a quick exit reports its
    // code and output, anything still running is simply "started".
    readonly property string backgroundScript: [
        "log=$2",
        "setsid bash -ic \"$1\" >\"$log\" 2>&1 </dev/null &",
        "pid=$!",
        "i=0",
        "while [ $i -lt 10 ]; do sleep 0.2; kill -0 \"$pid\" 2>/dev/null || break; i=$((i+1)); done",
        "if kill -0 \"$pid\" 2>/dev/null; then echo RUNNING; exit 0; fi",
        "wait \"$pid\"; code=$?",
        "echo \"EXIT $code\"",
        "tail -c 3000 -- \"$log\"",
        "rm -f -- \"$log\""
    ].join("\n")

    Process {
        id: inspectProcess

        property int ownerId: -1
        property string word: ""

        stdout: StdioCollector {
            id: inspectStdout

            waitForEnd: true
        }

        onExited: rootKipRunService.finishInspect(ownerId, word, inspectStdout.text)
    }

    Process {
        id: runProcess

        property string commandText: ""
        property string commandWord: ""

        stdout: StdioCollector {
            id: runStdout

            waitForEnd: true
        }

        onExited: rootKipRunService.finishRun(commandText, commandWord, runStdout.text)
    }

    Process {
        id: launcher
    }

    // State folders exist before anything is written; rofi-runner normally
    // created its own already, KIP's is new.
    Process {
        id: mkdirProcess

        running: true
        command: ["mkdir", "-p", "--", rootKipRunService.historyPath.replace(/\/[^\/]*$/, ""), rootKipRunService.modesPath.replace(/\/[^\/]*$/, "")]
    }

    // History lines containing every typed word, newest first.
    function filter(text) {
        const words = String(text || "").toLowerCase().split(/\s+/).filter(word => word.length > 0);
        const list = history.slice().reverse().filter(line => words.every(word => line.toLowerCase().indexOf(word) >= 0));

        matches = list.slice(0, kt.runHistoryShown).map(line => ({
                    command: line,
                    origin: "history",
                    folder: "",
                    file: line,
                    excerpt: ""
                }));
    }

    // First word that is not a VAR=value assignment, like rofi-runner.
    function commandWord(text) {
        for (const part of String(text || "").trim().split(/\s+/)) {
            if (!/^[A-Za-z_][A-Za-z0-9_]*=/.test(part))
                return part;
        }
        return "";
    }

    function inspect(text) {
        const word = commandWord(text);

        if (word === inspectedWord && inspectStatus !== "idle")
            return;

        inspectId++;
        inspectedWord = word;
        info = [];
        dangerous = false;
        commandType = "";
        reason = "";

        if (word.length === 0) {
            inspectStatus = "idle";
            return;
        }

        inspectStatus = "busy";
        inspectProcess.running = false;
        inspectProcess.ownerId = inspectId;
        inspectProcess.word = word;
        inspectProcess.command = ["bash", "-ic", inspectScript, "kip-run-inspect", word];
        inspectProcess.running = true;
    }

    function finishInspect(ownerId, word, text) {
        if (ownerId !== inspectId)
            return;

        const lines = String(text).split("\n");
        const typeLine = lines.find(line => line.startsWith("TYPE "));
        const classLine = lines.find(line => line.startsWith("CLASS ")) || "";
        const infoAt = lines.indexOf("INFO");
        const parts = classLine.split(/\s+/);

        commandType = typeLine ? typeLine.slice(5).trim() : "";
        info = infoAt >= 0 ? lines.slice(infoAt + 1).map(line => line.replace(/\s+$/, "")).filter(line => line.trim().length > 0) : [];
        dangerous = info.some(line => /Danger:\s*YES/i.test(line));

        let guessed = "background";
        let why = "";

        if (word === "sudo" || word === "doas") {
            guessed = "terminal";
            why = word + " needs a terminal to ask for your password";
        } else if (parts[1] === "header") {
            guessed = parts[2] === "true" ? "terminal" : "background";
            why = "its script header says # %terminal: " + parts[2];
        } else if (parts[1] === "desktop") {
            guessed = parts[2] === "true" ? "terminal" : "background";
            why = parts[3] + " says Terminal=" + parts[2];
        } else if (parts[1] === "libs") {
            guessed = parts[2] === "gui" ? "background" : "terminal";
            why = parts[2] === "gui" ? "it links GUI libraries" : "it is a program without GUI libraries";
        } else if (commandType === "alias" || commandType === "function" || commandType === "builtin" || commandType === "keyword") {
            guessed = "terminal";
            why = "it is a shell " + commandType;
        } else {
            why = "nothing says otherwise; output shows here if it exits quickly";
        }

        remembered = modes[word] === "terminal" || modes[word] === "background";
        mode = remembered ? modes[word] : guessed;
        reason = remembered ? "you chose this last time (Shift+Enter flips it again)" : why;
        inspectStatus = "done";
    }

    // flip: Shift+Enter, run the other way and remember that for this word.
    function run(text, flip) {
        const word = commandWord(text);
        const chosen = flip ? (mode === "terminal" ? "background" : "terminal") : mode;

        if (flip)
            remember(word, chosen);

        output = "";
        exitCode = 0;

        if (chosen === "terminal") {
            // hold: the window stays after the command, so its output can be read.
            launcher.command = theme.terminalCommand(["bash", "-ic", text], { hold: true });
            launcher.startDetached();
            addToHistory(text);
            runStatus = "started";
            eventKey = "run.started";
            return true;
        }

        const runtime = Quickshell.env("XDG_RUNTIME_DIR").length > 0 ? Quickshell.env("XDG_RUNTIME_DIR") : "/tmp";

        runProcess.running = false;
        runProcess.commandText = text;
        runProcess.commandWord = word;
        runProcess.command = ["bash", "-c", backgroundScript, "kip-run", text, runtime + "/kip-run-" + Date.now() + ".log"];
        runProcess.running = true;
        runStatus = "running";
        eventKey = "run.running";
        return false;
    }

    function finishRun(text, word, stdoutText) {
        const lines = String(stdoutText).split("\n");

        if (lines[0] === "RUNNING") {
            addToHistory(text);
            runStatus = "started";
            eventKey = "run.started";
            return;
        }

        const exit = /^EXIT (\d+)$/.exec(lines[0] || "");

        exitCode = exit ? Number(exit[1]) : -1;
        // Interactive bash without a terminal always says these two; noise.
        output = lines.slice(1).filter(line => !/^bash: (cannot set terminal process group|no job control in this shell)/.test(line)).join("\n").trim();

        if (exitCode === 0) {
            addToHistory(text);
            runStatus = "exited";
            eventKey = output.length > 0 ? "run.output" : "run.started";
        } else {
            runStatus = "failed";
            eventKey = "run.failed";
        }
    }

    function addToHistory(text) {
        if (history.indexOf(text) >= 0)
            return;

        history = history.concat([text]);
        historyFile.setText(history.join("\n") + "\n");
    }

    function forget(text) {
        history = history.filter(line => line !== text);
        historyFile.setText(history.length > 0 ? history.join("\n") + "\n" : "");
    }

    function remember(word, chosen) {
        if (word.length === 0)
            return;

        const next = Object.assign({}, modes);

        next[word] = chosen;
        modes = next;
        modesFile.setText(JSON.stringify(next, null, 2) + "\n");
    }

    function reset() {
        inspectId++;
        inspectProcess.running = false;
        inspectStatus = "idle";
        inspectedWord = "";
        matches = [];
        info = [];
        dangerous = false;
        reason = "";
        runStatus = "idle";
        output = "";
        eventKey = "";
    }
}
