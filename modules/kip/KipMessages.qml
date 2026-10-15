import QtQuick

// Event-keyed microcopy. A line is picked when a state is entered, never per
// keystroke. Lines must describe what is true right now: no "Searching..."
// before a search exists, no counts before results exist.
QtObject {
    id: rootKipMessages

    property string tone: "dry"
    property var lastPicks: ({})

    readonly property var sets: ({
            "kip.open": {
                neutral: ["Ready when you are.", "Type a question, or / for commands."],
                dry: ["Present. Mostly.", "You rang?", "Listening. Judging quietly, but listening.", "I am here. The notes are... somewhere nearby."]
            },
            "kip.ready": {
                neutral: ["Ready for the next one.", "Type a question, or / for commands."],
                dry: ["Next.", "Go on, then.", "Still here. Still unimpressed by the filing system."]
            },
            "kip.palette": {
                neutral: ["Pick a command. Tab completes."],
                dry: ["A command. How decisive.", "Choose wisely. Or Tab, which is faster."]
            },
            "last.ready": {
                neutral: ["Screenshots, newest first. Add a number for more."],
                dry: ["Evidence from your screen. Admissible, mostly.", "The last thing you thought worth capturing. Let's see if it was.", "Screenshots: proof something happened, rarely proof of what."]
            },
            "last.loading": {
                neutral: ["Looking in the screenshot folder."],
                dry: ["Checking the folder of things you meant to look at later."]
            },
            "last.found": {
                neutral: ["{count} newest. Arrows move, Enter acts."],
                dry: ["Here. Fresh from the screen, still warm.", "{count} captured moments. Context not included.", "There it is. You were apparently looking at this."]
            },
            "last.empty": {
                neutral: ["No screenshots in that folder."],
                dry: ["No screenshots. Either a clean desk or the wrong folder.", "Nothing here. Suspiciously tidy."]
            },
            "last.error": {
                neutral: ["Could not read the screenshot folder."],
                dry: ["The screenshot folder is not where I was told it would be.", "Can't read the folder. Check screenshotDir in KipTheme.qml."]
            },
            "help.ready": {
                neutral: ["Commands and keys, all of them. It is a short list."],
                dry: ["The full manual. Brace yourself, it has three entries.", "Help, abridged. Very abridged."]
            },
            "command.unknown": {
                neutral: ["That is not a command I know. These are."],
                dry: ["Not a command. Ambitious, though.", "I do not know that one, and I refuse to guess with confidence."]
            },
            "general.ready": {
                neutral: ["General question. Enter sends it."],
                dry: ["A general question. No notes involved, just opinions.", "Free-form. My favourite kind of risk."]
            },
            "general.generating": {
                neutral: ["Writing an answer."],
                dry: ["Composing. Do not rush genius.", "Thinking out loud, in text."]
            },
            "general.completed": {
                neutral: ["Done."],
                dry: ["There. Verify anything that matters.", "Answer delivered. Confidence not guaranteed."]
            },
            "ask.ready": {
                neutral: ["Ask a question. I'll search your indexed notes for context."],
                dry: ["A question? Splendid. I was running out of things to judge.", "Go ahead. I'll consult the notes before consulting my imagination.", "Ask away. I have an alarming amount of confidence.", "Your question, please. The archives are pretending to be organized."]
            },
            "ask.submitted": {
                neutral: ["Question received."],
                dry: ["Received. Rummaging begins."]
            },
            "ask.generating": {
                neutral: ["Writing an answer from the sources above."],
                dry: ["Sources found. Now turning them into sentences.", "Reading your notes so you don't have to. Again."]
            },
            "ask.completed": {
                neutral: ["Done. Check the sources if it matters."],
                dry: ["Done. The sources are above, in case I got creative.", "Answered. Footnotes included, trust optional."]
            },
            "notes.ready": {
                neutral: ["Semantic search across ~/Notes. Describe it; exact words are optional."],
                dry: ["Describe it badly. Semantic search is used to that.", "What did past Adam write down and then forget?", "Search the notes. Logseq and the toreview pile both count."]
            },
            "notes.searching": {
                neutral: ["Searching notes."],
                dry: ["Searching. The index is old but honest.", "Digging."]
            },
            "notes.found": {
                neutral: ["{count} matches. Up/Down to move."],
                dry: ["{count} matches. At least one is probably the one.", "Found {count}. Past Adam did write things down."]
            },
            "notes.weak": {
                neutral: ["No strong matches. These are the closest guesses."],
                dry: ["Nothing convincing. Here are my closest guesses, dimmed for honesty.", "Weak matches only. Either it isn't written down, or it is written down strangely."]
            },
            "notes.empty": {
                neutral: ["No matches. Try different words."],
                dry: ["Nothing. Either it was never written, or it was written creatively.", "Empty. Try describing it the way you'd complain about it."]
            },
            "error.backend": {
                neutral: ["The backend did not answer. Nothing was lost; try again."],
                dry: ["The backend is unavailable. I would blame it, but it can't hear me.", "No answer from the backend. Your question survives; retry when it wakes."]
            },
            "error.ollama": {
                neutral: ["Ollama is not reachable. Start it, then Enter retries."],
                dry: ["Ollama is not answering. Possibly asleep, possibly sulking. Enter retries.", "No Ollama, no thoughts. Start it and press Enter."]
            },
            "error.index": {
                neutral: ["The notes index needs attention. Run jarvis -index-notes in a terminal."],
                dry: ["The index is missing or stale. jarvis -index-notes, then try again.", "I can't search an index that isn't there. jarvis -index-notes."]
            },
            "error.malformed": {
                neutral: ["Jarvis answered in something other than JSON."],
                dry: ["Jarvis replied, just not in a language I parse.", "Malformed reply. Someone printed to stdout."]
            },
            "error.generic": {
                neutral: ["Something went wrong. Try again."],
                dry: ["Something broke. It wasn't you. Probably."]
            }
        })

    function linesFor(eventKey) {
        const entry = sets[eventKey];

        if (!entry)
            return [];

        const toned = entry[tone];
        return toned && toned.length > 0 ? toned : (entry.neutral || []);
    }

    // Picks a line for eventKey, avoiding an immediate repeat of the last pick.
    function pick(eventKey, values) {
        const lines = linesFor(eventKey);

        if (lines.length === 0)
            return "";

        const last = lastPicks[eventKey];
        let index = Math.floor(Math.random() * lines.length);

        if (lines.length > 1 && index === last)
            index = (index + 1) % lines.length;

        const picks = lastPicks;
        picks[eventKey] = index;
        lastPicks = picks;

        return format(lines[index], values || {});
    }

    function format(line, values) {
        return line.replace(/\{(\w+)\}/g, (match, key) => values[key] !== undefined ? String(values[key]) : match);
    }
}
