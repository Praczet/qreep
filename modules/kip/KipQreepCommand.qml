import QtQuick

// /qreep as the panel sees it: the filtered IPC list, Tab completion, and
// calling. KipQreepService talks to quickshell ipc; this keeps the selection
// and decides what Enter/Tab mean. host is KipPanel.
Item {
    id: rootKipQreepCommand

    required property QtObject host
    required property QtObject qreep

    readonly property bool active: host.contentState === "qreep"
    property int index: 0
    readonly property bool listVisible: active && qreep.results.length > 0
    readonly property var hit: listVisible ? qreep.results[Math.min(index, qreep.results.length - 1)] : null
    readonly property string eventKey: qreep.eventKey || "qreep.ready"

    function reset() {
        qreep.reset();
        index = 0;
    }

    function show() {
        if (!active) {
            host.backToCompose();
            host.contentState = "qreep";
            qreep.load();
        }
        // New typing, new question: the last call's answer goes.
        qreep.callStatus = "idle";
        qreep.callOutput = "";
        qreep.callLabel = "";
        qreep.filter(host.parsed.argument);
        index = 0;
    }

    // Tab on "target function partial": complete the argument from the
    // catalog's choices, cycling when the partial matches several.
    function completeChoice() {
        const exact = qreep.exact;

        if (!exact || exact.entry.choices.length === 0)
            return false;

        const typed = exact.args.length > 0 ? exact.args[exact.args.length - 1] : "";
        const choices = exact.entry.choices;
        const current = choices.indexOf(typed);
        const next = current >= 0 ? choices[(current + 1) % choices.length] : (choices.find(choice => choice.startsWith(typed.toLowerCase())) || choices[0]);

        host.setInput("/" + host.parsed.token + " " + exact.entry.shortName + " " + exact.entry.name + " " + next);
        return true;
    }

    function complete(entry) {
        host.setInput("/" + host.parsed.token + " " + entry.shortName + " " + entry.name + (entry.params.length > 0 ? " " : ""));
    }

    // Exact "target function args": call when the arguments are there.
    // Otherwise the selected row: call it, or fill it in to take arguments.
    function submit() {
        const exact = qreep.exact;

        if (exact) {
            if (exact.ready && exact.entry.choices.length > 0) {
                // Choices are known: take a unique prefix, refuse a typo.
                const last = exact.args.length - 1;
                const choice = qreep.matchChoice(exact.entry, exact.args[last]);

                if (choice === null) {
                    host.notice = "Pick one of: " + exact.entry.choices.join(", ") + ".";
                    return;
                }
                call(exact.entry, exact.args.slice(0, last).concat([choice]));
            } else if (exact.ready)
                call(exact.entry, exact.args);
            else
                host.notice = "Needs " + exact.entry.params.slice(exact.args.length).map(param => "<" + param.name + ">").join(" ") + ".";
            return;
        }

        if (qreep.status === "error") {
            qreep.load();
            return;
        }

        if (!hit)
            return;

        if (hit.params.length > 0)
            complete(hit);
        else
            call(hit, []);
    }

    function call(entry, args) {
        // Void: done, close, let the panel it opened have the focus.
        if (!qreep.call(entry, args))
            host.closeRequested();
    }

    // True when the key was /qreep's: Up/Down, Tab completion, Ctrl+H.
    function handleKey(event) {
        if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && listVisible) {
            index = host.clampIndex(index + (event.key === Qt.Key_Down ? 1 : -1), qreep.results.length);
            event.accepted = true;
            return true;
        }

        if (event.key === Qt.Key_Tab) {
            if (completeChoice()) {
                event.accepted = true;
                return true;
            }
            if (hit !== null) {
                event.accepted = true;
                complete(hit);
                return true;
            }
            return false;
        }

        if (event.key === Qt.Key_H && (event.modifiers & Qt.ControlModifier)) {
            event.accepted = true;
            qreep.toggleShowAll();
            index = 0;
            return true;
        }

        return false;
    }

    function status() {
        if (qreep.status === "error")
            return qreep.errorText;
        if (qreep.status === "loading")
            return "reading quickshell ipc show";
        if (qreep.callStatus === "running")
            return "calling " + qreep.callLabel;
        if (qreep.callStatus === "error")
            return qreep.callLabel + " failed";
        if (qreep.callStatus === "done" && qreep.callLabel.length > 0)
            return qreep.callLabel + (qreep.callOutput.length > 0 ? " returned:" : " returned nothing");

        const exact = qreep.exact;

        if (exact)
            return exact.ready ? "Enter calls " + exact.entry.target + " " + exact.entry.name + (exact.args.length > 0 ? " " + exact.args.map(arg => JSON.stringify(arg)).join(" ") : "") : qreep.signature(exact.entry);

        const listed = qreep.listedEntries().length;

        return (qreep.results.length === listed ? listed + " actions" : qreep.results.length + " of " + listed + " actions")
            + (qreep.showAll ? " · everything, Ctrl+H to tidy" : " · Ctrl+H shows all " + qreep.entries.length);
    }

    function enterLabel() {
        if (qreep.exact)
            return qreep.exact.ready ? "call" : "";
        return hit === null ? (qreep.status === "error" ? "retry" : "") : (hit.params.length > 0 ? "arguments" : "call");
    }

    function keyHints() {
        return "↑↓ move · Enter call (or fill in arguments) · Tab complete · Esc back · keep typing to filter";
    }
}
