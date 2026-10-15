import QtQuick

// Phase 1 stand-in for Jarvis. It walks through the same event shapes the real
// adapter will receive (start → sources → delta… → done), so the panel does
// not care which one it is talking to. Every result here is fake and says so.
Item {
    id: rootKipMockService

    readonly property bool mock: true

    // idle | searching | generating | done | empty | error
    property string status: "idle"
    // search | ask | general
    property string kind: ""
    property string query: ""
    property var results: []
    property string answer: ""
    property string errorText: ""
    property string errorKind: ""
    property string eventKey: ""
    property string model: "mock"
    property var rawSources: []
    readonly property bool backendAvailable: true
    property int requestId: 0

    readonly property bool busy: status === "searching" || status === "generating"

    property var steps: []

    readonly property var mockNotes: [
        {
            folder: "~/Notes/Logseq/pages/",
            file: "mariadb___permissions.md",
            line: 12,
            endLine: 31,
            origin: "logseq",
            score: 0.82,
            excerpt: "SHOW GRANTS FOR 'app'@'localhost'; then compare with information_schema.USER_PRIVILEGES before blaming the app."
        },
        {
            folder: "~/Notes/toreview/db/",
            file: "mysql-users-old.txt",
            line: 4,
            endLine: 19,
            origin: "legacy",
            score: 0.77,
            excerpt: "GRANT SELECT, INSERT ON shop.* TO 'shop'@'%'; FLUSH PRIVILEGES is not needed after GRANT, stop doing it."
        },
        {
            folder: "~/Notes/Logseq/journals/",
            file: "2026_03_14.md",
            line: 40,
            endLine: 46,
            origin: "logseq",
            score: 0.64,
            excerpt: "Spent an hour on a missing host wildcard. 'user'@'localhost' and 'user'@'%' are two different people."
        },
        {
            folder: "~/Notes/Logseq/pages/",
            file: "hyprland___layer rules.md",
            line: 3,
            endLine: 22,
            origin: "logseq",
            score: 0.41,
            excerpt: "layerrule blur + ignore_alpha keeps transparent overlay surfaces from blurring the whole screen."
        },
        {
            folder: "~/Notes/Logseq/pages/",
            file: "borg___restore.md",
            line: 8,
            endLine: 27,
            origin: "logseq",
            score: 0.38,
            excerpt: "borg extract --dry-run --list first. Restoring into / at midnight is a personality test you will fail."
        },
        {
            folder: "~/Notes/toreview/",
            file: "quickshell-ideas.md",
            line: 1,
            endLine: 14,
            origin: "legacy",
            score: 0.33,
            excerpt: "A prompt that appears as a line and unfolds. Probably overkill. Definitely doing it."
        }
    ]

    readonly property string mockAskAnswer: "This is a mock answer, rehearsing the streaming path. In Phase 2 Jarvis writes the real one from the sources above. "
        + "For MariaDB privileges the notes point at SHOW GRANTS FOR 'user'@'host'; and the reminder that 'user'@'localhost' "
        + "and 'user'@'%' are different accounts, which explains most of the lost evenings."

    readonly property string mockGeneralAnswer: "Mock general answer. Plain text will eventually go to the general Jarvis chat, "
        + "without notes as context. For now this paragraph exists to prove that streamed text grows in place instead of spawning bubbles."

    Timer {
        id: stepTimer

        repeat: false
        onTriggered: rootKipMockService.runNextStep()
    }

    function search(text) {
        begin("search", text);
        status = "searching";
        eventKey = "notes.searching";

        const lowered = text.toLowerCase();

        if (lowered.indexOf("fail") >= 0) {
            queue(650, () => fail("Mock backend refused, as requested by the word 'fail'."));
            return;
        }

        if (lowered.indexOf("nothing") >= 0) {
            queue(650, () => {
                results = [];
                status = "empty";
                eventKey = "notes.empty";
            });
            return;
        }

        queue(750, () => {
            results = rank(text);
            status = "done";
            eventKey = "notes.found";
        });
    }

    function ask(text) {
        begin("ask", text);
        status = "searching";
        eventKey = "ask.submitted";

        if (text.toLowerCase().indexOf("fail") >= 0) {
            queue(600, () => fail("Mock backend refused, as requested by the word 'fail'."));
            return;
        }

        queue(600, () => {
            results = rank(text).slice(0, 3);
            status = "generating";
            eventKey = "ask.generating";
        });
        queueDeltas(mockAskAnswer);
        queue(120, () => {
            status = "done";
            eventKey = "ask.completed";
        });
    }

    function general(text) {
        begin("general", text);
        status = "generating";
        eventKey = "general.generating";
        queue(350, () => {});
        queueDeltas(mockGeneralAnswer);
        queue(120, () => {
            status = "done";
            eventKey = "general.completed";
        });
    }

    function cancel() {
        stepTimer.stop();
        steps = [];
        requestId++;
    }

    function reset() {
        cancel();
        status = "idle";
        kind = "";
        query = "";
        results = [];
        answer = "";
        errorText = "";
        errorKind = "";
        eventKey = "";
    }

    function begin(nextKind, text) {
        reset();
        kind = nextKind;
        query = text;
    }

    function fail(message) {
        status = "error";
        errorKind = "backend";
        errorText = message;
        eventKey = "error.backend";
    }

    // Chunks of 2-4 words, like a model that has had coffee.
    function queueDeltas(text) {
        const words = text.split(" ");
        let index = 0;

        while (index < words.length) {
            const size = 2 + Math.floor(Math.random() * 3);
            const chunk = words.slice(index, index + size).join(" ") + " ";

            index += size;
            queue(45 + Math.floor(Math.random() * 50), () => answer += chunk);
        }
    }

    function queue(delay, action) {
        const pending = steps;
        const ownerId = requestId;

        pending.push({
            delay: delay,
            ownerId: ownerId,
            action: action
        });
        steps = pending;

        if (!stepTimer.running)
            scheduleNext();
    }

    function scheduleNext() {
        if (steps.length === 0)
            return;

        stepTimer.interval = steps[0].delay;
        stepTimer.restart();
    }

    function runNextStep() {
        const pending = steps;
        const step = pending.shift();

        steps = pending;

        // Stale steps from a cancelled request never touch current state.
        if (step && step.ownerId === requestId)
            step.action();

        scheduleNext();
    }

    function citedAnswer(text) {
        return text;
    }

    function rank(text) {
        const words = text.toLowerCase().split(/\s+/).filter(word => word.length > 2);

        return mockNotes.map(note => {
            const haystack = (note.file + " " + note.excerpt).toLowerCase();
            const hits = words.filter(word => haystack.indexOf(word) >= 0).length;

            return Object.assign({}, note, {
                score: Math.min(0.99, note.score + hits * 0.05),
                ranges: [{
                        start: note.line,
                        end: note.endLine
                    }],
                weak: false,
                snippet: note.excerpt
            });
        }).sort((left, right) => right.score - left.score);
    }
}
