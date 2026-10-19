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
            "tldr.ready": {
                neutral: ["tldr pages: curated examples, read from the local cache."],
                dry: ["Real documentation. A refreshing change from guesswork.", "Name the command. I'll fetch examples written by actual humans.", "tldr: for when you want the answer, not the manual's memoirs."]
            },
            "tldr.found": {
                neutral: ["The tldr page. Copy on any example."],
                dry: ["Straight from the page. I added nothing, for once.", "Curated examples. Placeholders are yours to fill in.", "Here's how it's actually used. Accept no imitations, especially mine."]
            },
            "tldr.missing": {
                neutral: ["No tldr page for that one."],
                dry: ["No page. Even the curators gave up on that one.", "Nothing in the cache. The man page awaits, grimly."]
            },
            "tldr.nocache": {
                neutral: ["The tldr cache is empty. Run tldr --update once."],
                dry: ["The cache is empty. One tldr --update and I'm useful again."]
            },
            "calc.ready": {
                neutral: ["Type an expression. qalc does the maths, offline."],
                dry: ["Arithmetic. Finally, a question with a correct answer.", "Numbers, units, regret. qalc handles the first two.", "Go on. I promise not to round anything dramatically."]
            },
            "calc.found": {
                neutral: ["Result below. Enter copies it."],
                dry: ["Computed. Check how qalc read it before trusting me.", "There. Mathematics remains undefeated.", "An answer that is actually correct. Savour it."]
            },
            "calc.error": {
                neutral: ["qalc could not make a number of that."],
                dry: ["That is not maths. That is a cry for help.", "qalc stared at it and gave up. Rare, but earned."]
            },
            "def.ready": {
                neutral: ["Look up a word in the offline dictionaries."],
                dry: ["A word you don't know. How refreshingly honest.", "Name the word. I'll pretend I knew it all along."]
            },
            "def.found": {
                neutral: ["Definition below. Enter copies it."],
                dry: ["Defined. Use it in a sentence to feel superior.", "There. Your vocabulary grows; your humility does not."]
            },
            "def.empty": {
                neutral: ["No exact entry for that word."],
                dry: ["No entry. Either it's misspelled or it's beyond lexicography."]
            },
            "def.nodict": {
                neutral: ["sdcv has no dictionaries installed yet."],
                dry: ["I have a dictionary reader and no dictionaries. A library of empty shelves."]
            },
            "keys.ready": {
                neutral: ["Hyprland keybindings. Type what it does or the keys."],
                dry: ["The sacred list of things your fingers were supposed to remember.", "Your keybindings. All of them. You configured these, allegedly."]
            },
            "keys.found": {
                neutral: ["Up/Down to choose, Enter copies the keys."],
                dry: ["There it is. Try to remember it this time.", "Found. Your muscle memory sends its apologies."]
            },
            "keys.empty": {
                neutral: ["No keybinding matches."],
                dry: ["No such bind. Perhaps it was only ever a dream."]
            },
            "win.ready": {
                neutral: ["Pick a window. Type to narrow it down."],
                dry: ["Somewhere among your windows is the one you want.", "Your windows, lined up for inspection. Most recent first."]
            },
            "win.found": {
                neutral: ["Up/Down to choose, Enter to switch."],
                dry: ["Candidates assembled. Choose your destination.", "There they are. Try not to open a new one instead."]
            },
            "win.empty": {
                neutral: ["No window matches."],
                dry: ["No such window. Perhaps you closed it in a moment of clarity."]
            },
            "projects.ready": {
                neutral: ["Pick a project. Type to narrow it down."],
                dry: ["Your projects, each one waiting to be finished.", "Choose where to be productive. Or at least present."]
            },
            "projects.found": {
                neutral: ["Enter opens it in Places, Shift+Enter the cockpit, Ctrl+Enter the editor."],
                dry: ["There it is. The uncommitted files missed you.", "Found it. Try not to start a new one instead."]
            },
            "projects.empty": {
                neutral: ["No project matches."],
                dry: ["No such project. Plenty of others are still unfinished, though."]
            },
            "projects.error": {
                neutral: ["Places is not loaded, so there are no projects to show."],
                dry: ["Projects live in Places, and Places is not answering."]
            },
            "ssh.ready": {
                neutral: ["Pick a host. Type to narrow it down."],
                dry: ["Other people's computers, at your service.", "Somewhere out there, a server is waiting to disappoint you."]
            },
            "ssh.found": {
                neutral: ["Enter connects with kitten ssh."],
                dry: ["There it is. The background turns red so you remember where you are.", "Found it. Mind the rm -rf, it is not your machine."]
            },
            "ssh.empty": {
                neutral: ["No host matches."],
                dry: ["No such host. Maybe it lives only in your memory, not in ~/.ssh/config."]
            },
            "ssh.error": {
                neutral: ["Places is not loaded, so there are no ssh hosts to show."],
                dry: ["The hosts live in Places, and Places is not answering."]
            },
            "timer.ready": {
                neutral: ["Duration, clock time, up, pause, resume or stop."],
                dry: ["Time management. Bold of you.", "How long shall we pretend you'll focus?", "Name a duration. I'll hold you to it."]
            },
            "run.ready": {
                neutral: ["Type a command. The preview says where it will run."],
                dry: ["Command me. Within reason. Mostly within reason.", "Your shell, minus the typing of a terminal first.", "What shall we unleash?"]
            },
            "run.running": {
                neutral: ["Starting."],
                dry: ["Launching. Stand back."]
            },
            "run.started": {
                neutral: ["Started."],
                dry: ["Off it goes.", "Launched. Its problems are its own now."]
            },
            "run.output": {
                neutral: ["It finished quickly; output below."],
                dry: ["Done before I could blink. Here's what it said."]
            },
            "run.failed": {
                neutral: ["It exited with an error. Output below."],
                dry: ["That did not go well. Evidence below.", "It failed, loudly. Details below."]
            },
            "run.danger": {
                neutral: ["cinfo marks this command dangerous. Enter again to run it."],
                dry: ["This one has teeth, says cinfo. Enter again if you mean it."]
            },
            "help.ready": {
                neutral: ["Commands and keys, all of them. It is a short list."],
                dry: ["Instructions! An unexpected display of wisdom.", "Ah, asking for help. Character development.", "The ancient manual. Mercifully short.", "You seek knowledge. Finally, we have something in common.", "Behold my capabilities. Try not to be overwhelmed.", "A guide to operating me. An ambitious undertaking."]
            },
            "command.unknown": {
                neutral: ["That is not a command I know. These are."],
                dry: ["An intriguing command. Entirely fictional, unfortunately.", "I admire your confidence. Not your syntax.", "You invented a command. Shall we notify the historians?", "Unknown command. A bold attempt at communication.", "I understand many things. That isn't one of them.", "Creative. Wrong, but creative."]
            },
            "apps.ready": {
                neutral: ["Applications. Type to filter, Enter launches."],
                dry: ["Pick something to run. I'll pretend I'm not judging.", "Your applications, grouped as if by someone organised.", "Launching things. Finally, a job with clear outcomes.", "So many apps. Most of them were installed once, on a Tuesday.", "Choose wisely. Or quickly. Usually it's quickly."]
            },
            // Habit remarks on open. {app} is the app's name; the panel shows
            // its icon and preselects it, so "Enter" in a line is true.
            "apps.nudge.most": {
                neutral: ["Most used: {app}, {count} launches. Enter opens it."],
                dry: ["{app}, {count} launches. At this point it's a relationship.", "You've opened {app} {count} times. I've stopped asking why.", "{app} again? It's selected. I know you.", "{count} times {app}. Shall I just make it the wallpaper?", "{app}. Obviously. Enter, and we can both pretend you considered alternatives."]
            },
            "apps.nudge.hour": {
                neutral: ["Around {hour} you usually open {app}. Enter opens it."],
                dry: ["It's {hour}. Historically, that means {app}. Enter.", "{hour}: the traditional hour of {app}. I've selected it. Don't fight it.", "Around this time you always open {app}. Predictable. Almost endearing.", "{app} o'clock. I've done the hard part."]
            },
            "apps.nudge.recent": {
                neutral: ["Last launched: {app}, {ago}. Enter opens it again."],
                dry: ["{app}, {ago}. Back for more? It's selected.", "You opened {app} {ago}. I sense a pattern forming.", "{app} was {ago}. Again? Enter, then.", "Still {app}? It's been {ago}. Commitment. Rare."]
            },
            "browse.ready": {
                neutral: ["Enter goes into a folder, or shows what to do with a file."],
                dry: ["Your filesystem. I've seen worse. Not often.", "Folders inside folders. Very modern.", "Exploring. Try not to get lost in ~/Downloads.", "Ah, the archaeology of your home directory.", "Somewhere in here is the file you want. Statistically."]
            },
            "browse.empty": {
                neutral: ["This folder is empty. Or everything in it is hidden."],
                dry: ["Empty. Or shy. Alt+H for the shy ones.", "Nothing here. A rare moment of tidiness.", "An empty folder. Minimalism, or a mistake?"]
            },
            "browse.nomatch": {
                neutral: ["Nothing here matches that."],
                dry: ["No such thing in this folder. Wrong folder, perhaps?", "Nothing matches. Backspace is right there.", "You typed with confidence. The folder disagrees."]
            },
            "browse.error": {
                neutral: ["Could not list that folder."],
                dry: ["That folder refused to cooperate.", "No such folder, or no permission. Either way, no.", "The filesystem said no. I'd respect it."]
            },
            "rg.ready": {
                neutral: ["Type text to find inside files."],
                dry: ["What did you write, and where did you bury it?", "Grep. The oldest form of memory.", "Somewhere, a line knows what you mean."]
            },
            "rg.searching": {
                neutral: ["Searching file contents."],
                dry: ["Reading your files so you don't have to.", "Ripping through text. Politely.", "Scanning. Your config files have so much to say."]
            },
            "rg.found": {
                neutral: ["Matching lines, by file."],
                dry: ["Found it. Several times, apparently.", "There it is. Copy-paste leaves traces.", "Lines located. Enter takes you to them."]
            },
            "rg.empty": {
                neutral: ["No file contains that."],
                dry: ["Nobody wrote that. Not even you.", "Zero matches. Gitignored, or imaginary?", "Nothing. Try --h, or a different folder."]
            },
            "rg.error": {
                neutral: ["ripgrep could not search there."],
                dry: ["rg refused. It usually has reasons.", "Search failed. The folder may not exist.", "ripgrep is unhappy. Details below."]
            },
            "qreep.ready": {
                neutral: ["Qreep's actions, grouped. Enter calls one."],
                dry: ["The control room. Please touch everything.", "All the levers. Some of them even do things.", "Qreep's nervous system, exposed. Charming.", "Pick a function. I'll press the button for you."]
            },
            "qreep.nomatch": {
                neutral: ["No IPC function matches that."],
                dry: ["No such lever. Not yet, anyway.", "Qreep doesn't do that. Write it, perhaps?", "Nothing matches. The shell is smaller than your ambitions."]
            },
            "qreep.called": {
                neutral: ["Called. Here is what it said."],
                dry: ["It answered. Briefly, as is its way.", "Done. It even replied.", "The shell has spoken."]
            },
            "qreep.error": {
                neutral: ["That IPC call failed."],
                dry: ["The shell declined. Details below.", "Something in Qreep said no.", "That call bounced. Arguments, perhaps?"]
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
