import QtQuick
import Quickshell.Io

// /keys: Hyprland keybindings from `hyprctl binds -j`, read once when /keys is
// entered and filtered locally while typing. Descriptions come from the binds
// themselves (A.bind passes one for every bind), so there is no second list to
// keep in sync. Read-only: with the Lua config every bind reports dispatcher
// "__lua", so there is nothing honest to replay here.
Item {
    id: rootKipBindsService

    // idle | loading | ready | error
    property string status: "idle"
    property var binds: []
    property var results: []
    property string query: ""
    property string errorText: ""
    property string eventKey: ""

    Process {
        id: bindsProcess

        stdout: StdioCollector {
            id: bindsStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: bindsStderr

            waitForEnd: true
        }

        onExited: exitCode => rootKipBindsService.finish(exitCode, bindsStdout.text, bindsStderr.text)
    }

    function load() {
        if (bindsProcess.running)
            return;

        status = "loading";
        bindsProcess.command = ["hyprctl", "binds", "-j"];
        bindsProcess.running = true;
    }

    function reset() {
        bindsProcess.running = false;
        status = "idle";
        binds = [];
        results = [];
        query = "";
        errorText = "";
        eventKey = "";
    }

    function finish(exitCode, stdoutText, stderrText) {
        let parsed = null;

        try {
            parsed = JSON.parse(stdoutText);
        } catch (error) {
            parsed = null;
        }

        if (exitCode !== 0 || !Array.isArray(parsed)) {
            status = "error";
            errorText = String(stderrText).trim() || "hyprctl binds -j did not return a list.";
            eventKey = "keys.empty";
            return;
        }

        // Config order: it already groups related binds better than sorting would.
        binds = parsed.map(bind => {
            const combo = comboFor(bind);
            const submap = String(bind.submap || "");
            const description = String(bind.description || "") || String(bind.dispatcher || "") + " " + String(bind.arg || "");

            return {
                combo: combo,
                description: description,
                submap: submap,
                // KipResultList row: the combo in the chip, the description bold.
                origin: combo,
                folder: submap.length > 0 ? submap + " · " : "",
                file: description,
                excerpt: ""
            };
        });
        status = "ready";
        filter(query);
    }

    // Modifier bits as Hyprland reports them.
    function comboFor(bind) {
        const mask = Number(bind.modmask || 0);
        const mods = [];

        if (mask & 64)
            mods.push("SUPER");
        if (mask & 4)
            mods.push("CTRL");
        if (mask & 8)
            mods.push("ALT");
        if (mask & 1)
            mods.push("SHIFT");

        return mods.concat([String(bind.key || "")]).join("+");
    }

    // Every word must appear in the combo, description or submap; binds whose
    // combo matches come first, then config order.
    function filter(text) {
        query = String(text || "");

        const words = query.toLowerCase().split(/\s+/).filter(word => word.length > 0);
        const matched = [];

        binds.forEach((bind, order) => {
            const combo = bind.combo.toLowerCase();
            const haystack = combo + " " + bind.description.toLowerCase() + " " + bind.submap.toLowerCase();

            if (!words.every(word => haystack.indexOf(word) >= 0))
                return;

            matched.push(Object.assign({}, bind, {
                rank: -words.filter(word => combo.indexOf(word) >= 0).length,
                order: order
            }));
        });

        matched.sort((left, right) => left.rank - right.rank || left.order - right.order);
        results = matched;

        if (status === "ready")
            eventKey = matched.length > 0 ? "keys.found" : "keys.empty";
    }
}
