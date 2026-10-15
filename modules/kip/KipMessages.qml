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
                dry: ["Ah. You've returned. I was enjoying the silence.", "Your favourite intelligence has arrived. You're welcome.", "Oh good. We're making decisions again.", "I was contemplating existence. Yours, mostly.", "There you are. I nearly started being productive.", "Yes, yes. I'm here. Try to contain your excitement."]
            },
            "kip.ready": {
                neutral: ["Ready for the next one.", "Type a question, or / for commands."],
                dry: ["Next victim. I mean, request.", "Anything else you'd like me to rescue?", "Still here. Against all reasonable expectations.", "Go on. Surprise me. It would be a first.", "Another adventure into the mundane?", "Your continued dependence is touching."]
            },
            "kip.palette": {
                neutral: ["Pick a command. Tab completes."],
                dry: ["Behold. Choices. Your ancient enemy.", "Pick one. I have prepared several excellent options.", "A menu! Civilization truly has peaked.", "Choose wisely. Or press Tab and pretend you did.", "So many commands. So little judgment.", "The power of choice. A terrible responsibility."]
            },
            "last.ready": {
                neutral: ["Screenshots, newest first. Add a number for more."],
                dry: ["Ah, the gallery of things you might remember.", "Your visual memories. Stored because actual memory failed.", "Let's inspect the evidence of your recent activities.", "Screenshots. Because apparently seeing once isn't enough.", "How delightful. A collection of captured rectangles.", "Another expedition into your photographic past."]
            },
            "last.loading": {
                neutral: ["Looking in the screenshot folder."],
                dry: ["Opening the archives of questionable decisions.", "Inspecting your collection of frozen moments.", "Consulting the sacred directory of screenshots.", "Looking for evidence. Don't look nervous.", "Sifting through your carefully accumulated pixels."]
            },
            "last.found": {
                neutral: ["{count} newest. Arrows move, Enter acts."],
                dry: ["{count} captured moments. Not a single explanation.", "Behold. Visual evidence. Interpretation sold separately.", "There. I assume this meant something to you.", "Recovered your pixels. My heroism continues.", "Found {count}. I remain indispensable.", "An excellent capture. Probably. I wasn't consulted."]
            },
            "last.empty": {
                neutral: ["No screenshots in that folder."],
                dry: ["Nothing. Your photographic career is off to a slow start.", "An empty gallery. Bold artistic statement.", "No screenshots. Finally, a mystery with no evidence.", "Apparently nothing was worth remembering.", "The archive is empty. I admire its restraint."]
            },
            "last.error": {
                neutral: ["Could not read the screenshot folder."],
                dry: ["The screenshot archive resists my brilliance.", "The folder is inaccessible. How unnecessarily dramatic.", "I cannot read that directory. Even genius has permissions.", "Your screenshot folder has chosen secrecy.", "A locked door. In a filesystem. How quaint."]
            },
            "fd.ready": {
                neutral: ["Find files and folders. Every word must appear in the path."],
                dry: ["Lost something again? How wonderfully predictable.", "Tell me what you've misplaced this time.", "Ah, a treasure hunt. Except the treasure is probably config.", "Describe the missing artifact. Vaguely, as tradition demands.", "Your filesystem is a labyrinth. Fortunately, I am magnificent.", "Somewhere in that chaos lies a file. Allegedly."]
            },
            "fd.searching": {
                neutral: ["Searching."],
                dry: ["Consulting the labyrinth.", "Hunting through your digital possessions.", "Let us see what you've buried this time.", "Searching. Try not to move the files.", "Following the trail of poor naming decisions.", "The hunt begins. Try to look impressed."]
            },
            "fd.root": {
                neutral: ["Searching all of /. This takes a moment."],
                dry: ["The entire filesystem? Ambitious. Reckless. I approve.", "Every directory. Every corner. What could go wrong?", "Ah, the grand expedition. Into absolutely everything.", "All of /. You've mistaken me for an archaeologist.", "We're searching the kingdom now. Naturally.", "A full expedition. I expect a statue afterward."]
            },
            "fd.found": {
                neutral: ["Matches below. Arrows move, Enter acts."],
                dry: ["Found them. Naturally. Applause is optional.", "Your lost treasures. Please misplace them more responsibly.", "There. Another mystery solved by superior intellect.", "Behold the results of my entirely predictable brilliance.", "Found something. Whether it's useful is your department.", "I have narrowed the chaos. You're welcome."]
            },
            "fd.empty": {
                neutral: ["Nothing matched every word."],
                dry: ["Nothing. Have you considered that the file is imaginary?", "A magnificent search for something that apparently isn't there.", "No matches. The filesystem denies your accusations.", "Try fewer words. Or more realistic expectations.", "Perhaps it's hidden. Perhaps it's elsewhere. Perhaps it's folklore.", "Nothing found. Even I cannot locate a bad memory."]
            },
            "fd.error": {
                neutral: ["fd could not search there."],
                dry: ["The search failed. The filesystem has opinions.", "Even my brilliance cannot negotiate with that directory.", "A technical obstacle. How insultingly ordinary.", "The search collapsed. I blame permissions or architecture.", "Well. That path has declined our invitation."]
            },
            "help.ready": {
                neutral: ["Commands and keys, all of them. It is a short list."],
                dry: ["Instructions! An unexpected display of wisdom.", "Ah, asking for help. Character development.", "The ancient manual. Mercifully short.", "You seek knowledge. Finally, we have something in common.", "Behold my capabilities. Try not to be overwhelmed.", "A guide to operating me. An ambitious undertaking."]
            },
            "command.unknown": {
                neutral: ["That is not a command I know. These are."],
                dry: ["An intriguing command. Entirely fictional, unfortunately.", "I admire your confidence. Not your syntax.", "You invented a command. Shall we notify the historians?", "Unknown command. A bold attempt at communication.", "I understand many things. That isn't one of them.", "Creative. Wrong, but creative."]
            },
            "general.ready": {
                neutral: ["General question. Enter sends it."],
                dry: ["A question for my magnificent intellect? Proceed.", "No notes? Just raw intelligence? How flattering.", "Ask, mortal. I have a reputation to maintain.", "A question without context. My favourite kind of peril.", "You bring curiosity. I bring unreasonable confidence.", "Very well. Let's pretend I know everything."]
            },
            "general.generating": {
                neutral: ["Writing an answer."],
                dry: ["Assembling wisdom from an alarming number of possibilities.", "Thinking. A rare activity in this household.", "One moment. Brilliance requires punctuation.", "Constructing an answer worthy of my reputation.", "Consulting the vast emptiness between certainty and knowledge.", "Arranging thoughts into something socially acceptable."]
            },
            "general.completed": {
                neutral: ["Done."],
                dry: ["There. Wisdom dispensed. Warranty not included.", "An answer. Whether it's right remains an exciting subplot.", "Behold my contribution to civilization.", "Done. You may begin the applause.", "Another question vanquished. Probably.", "I have spoken. Verification is still encouraged."]
            },
            "ask.ready": {
                neutral: ["Ask a question. I'll search your indexed notes for context."],
                dry: ["A question? Let me consult your former selves.", "Your notes await. Some may even be relevant.", "Ask. I shall interrogate the archives.", "Ah, knowledge retrieval. My less glamorous superpower.", "Let's see whether past you was more organized.", "A question for the archives. How delightfully scholarly."]
            },
            "ask.submitted": {
                neutral: ["Question received."],
                dry: ["Question received. Summoning your past wisdom.", "Very well. The archives have been disturbed.", "A worthy inquiry. Or at least an inquiry.", "Your request has entered the machinery of enlightenment.", "The question is mine now. No refunds."]
            },
            "ask.generating": {
                neutral: ["Writing an answer from the sources above."],
                dry: ["Sources acquired. Converting fragments into apparent wisdom.", "Reading your notes. Someone has to.", "Building an answer from the ruins of your organization.", "The evidence has spoken. I am translating.", "Organizing your thoughts. Again, you're welcome.", "Assembling conclusions. With citations, because apparently trust is dead."]
            },
            "ask.completed": {
                neutral: ["Done. Check the sources if it matters."],
                dry: ["Answered. The sources are there to restrain my imagination.", "There. Evidence-backed brilliance. A rare luxury.", "The archives have yielded their secrets. Mostly.", "Done. Please admire the citations.", "Your past self contributed. I did the interesting part.", "An answer, complete with witnesses. How responsible."]
            },
            "notes.ready": {
                neutral: ["Semantic search across ~/Notes. Describe it; exact words are optional."],
                dry: ["Searching your external memory? Sensible. Yours is unreliable.", "Describe the memory. I'll find where you imprisoned it.", "Let's ask the notes what you once considered important.", "Past you left clues. Present you requires assistance.", "The archives await. Organization remains theoretical.", "Tell me what you've forgotten. No judgment. Well, some."]
            },
            "notes.searching": {
                neutral: ["Searching notes."],
                dry: ["Disturbing the ancient records.", "Excavating the ruins of your previous thoughts.", "Consulting the archive spirits. Uncooperative creatures.", "Digging through recorded brilliance. And other material.", "Following semantic footprints through the chaos."]
            },
            "notes.found": {
                neutral: ["{count} matches. Up/Down to move."],
                dry: ["{count} matches. Past you was surprisingly verbose.", "Found {count}. The archives remember what you don't.", "Behold! Evidence that you once had a thought.", "{count} recovered fragments of your intellectual legacy.", "A successful excavation. {count} artifacts recovered.", "Look at that. You actually wrote something useful."]
            },
            "notes.weak": {
                neutral: ["No strong matches. These are the closest guesses."],
                dry: ["The archives whisper. Unfortunately, they're mumbling.", "Weak matches. Even the notes seem uncertain.", "I found echoes. Actual answers remain elusive.", "Not convincing. But these fragments looked lonely.", "A tenuous connection. I present it without enthusiasm.", "Closest matches only. Try describing it differently."]
            },
            "notes.empty": {
                neutral: ["No matches. Try different words."],
                dry: ["Nothing. Even your past self has abandoned this question.", "The archives are silent. Unusually considerate of them.", "No trace. Perhaps the thought escaped before you wrote it.", "An impressive absence of relevant knowledge.", "Nothing found. I refuse responsibility for your filing habits.", "Apparently you never wrote that down. Tragic."]
            },
            "error.backend": {
                neutral: ["The backend did not answer. Nothing was lost; try again."],
                dry: ["The backend is silent. I suspect cowardice.", "My lesser half has stopped responding.", "The machinery refuses to cooperate. Typical.", "The backend appears to be contemplating its failures.", "No response. I remain operational, naturally."]
            },
            "error.ollama": {
                neutral: ["Ollama is not reachable. Start it, then Enter retries."],
                dry: ["My borrowed brain is missing. Start Ollama.", "Ollama sleeps. Wake the beast and press Enter.", "The thinking engine is unavailable. How inconvenient.", "No Ollama. I am reduced to personality alone.", "My intellectual assistant has abandoned its duties.", "Ollama is unreachable. Even genius needs infrastructure."]
            },
            "error.index": {
                neutral: ["The notes index needs attention. Run jarvis -index-notes in a terminal."],
                dry: ["The archives lack an index. Run jarvis -index-notes.", "I cannot consult a library with no catalogue. Index it.", "Your notes exist. Their organization does not. Reindex.", "An unindexed archive. A monument to optimism.", "Run jarvis -index-notes. Even magic needs preparation."]
            },
            "error.malformed": {
                neutral: ["Jarvis answered in something other than JSON."],
                dry: ["Jarvis has forgotten how JSON works. Embarrassing.", "My colleague speaks nonsense. Again.", "That wasn't JSON. It was a cry for help.", "Jarvis returned something creative. Unfortunately, I needed JSON.", "A malformed response. Someone has been improvising."]
            },
            "error.generic": {
                neutral: ["Something went wrong. Try again."],
                dry: ["Something broke. How refreshingly unexpected.", "A failure. I shall pretend this was part of the plan.", "Well. That was beneath both of us.", "An unexpected setback. The universe grows tiresome.", "Something failed. I am choosing to be offended.", "A minor catastrophe. Naturally, I survived."]
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
