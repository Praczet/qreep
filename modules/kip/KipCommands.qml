import QtQuick

// Command registry and parser. No UI in here: the panel asks parse(text) what
// the input currently means and renders whatever comes back.
QtObject {
    id: rootKipCommands

    // kind: what Enter does. "ask" (notes-grounded), "general" (plain local
    // model) and "search" take an argument, "screenshots" takes one optionally
    // (argumentOptional).
    // flags: --key or --key=value tokens anywhere in the argument, parsed out
    // before the rest becomes the argument. Only commands with flags get them;
    // "/ask --foo" stays literal text.
    readonly property var commands: [
        {
            name: "app",
            aliases: ["apps"],
            label: "Applications",
            description: "Launch an application. Also what an empty input and plain text show.",
            helper: "Type to filter. Arrows move, Enter launches. Ctrl+G groups, Ctrl+L grid/list.",
            eventKey: "apps.ready",
            placeholder: "app name",
            icon: "󰀻",
            sourceHint: "desktop entries · launch log",
            kind: "apps",
            takesArgument: true,
            argumentOptional: true,
            syntax: "/app [name]",
            examples: ["/app", "/app firefox", "logseq"],
            actions: "Most used and Recent come first, from KIP's own launch log in ~/Data/sqlite/qreep/kip/apps.db. Then category, name or A–Z groups (Ctrl+G), as a grid or list (Ctrl+L). Typing ranks every app by name, then generic name, keywords and id. Enter launches and closes KIP."
        },
        {
            name: "ask",
            aliases: ["a"],
            label: "Ask local AI",
            description: "A general question to the local model, no notes as context.",
            helper: "Type the question, then Enter. For answers from your notes use /notes-ask.",
            eventKey: "general.ready",
            placeholder: "question",
            icon: "󰍩",
            sourceHint: "local model · no notes",
            kind: "general",
            takesArgument: true,
            syntax: "/ask <question>",
            examples: ["/ask What does SIGPIPE mean?"],
            actions: "The answer is selectable; code blocks have Copy. Enter on a finished answer opens its actions."
        },
        {
            name: "notes-ask",
            aliases: ["na"],
            label: "Ask notes",
            description: "Answer a question using your indexed notes as context.",
            helper: "Type the question, then Enter. Sources come first, prose second.",
            eventKey: "ask.ready",
            placeholder: "question about your notes",
            icon: "󰭹",
            sourceHint: "~/Notes index · local model",
            kind: "ask",
            takesArgument: true,
            syntax: "/notes-ask <question>",
            examples: ["/notes-ask How do I inspect MariaDB user privileges?", "/na borg restore steps"],
            actions: "Sources appear first: Up/Down, Enter opens one, Tab shows its original text. The answer is selectable; code blocks have Copy."
        },
        {
            name: "notes",
            aliases: ["n", "search"],
            label: "Search notes",
            description: "Semantic search across ~/Notes, Logseq and legacy toreview included.",
            helper: "Type what you remember, not what you named it. Enter searches.",
            eventKey: "notes.ready",
            placeholder: "what you are looking for",
            icon: "󰍉",
            sourceHint: "~/Notes · semantic index",
            kind: "search",
            takesArgument: true,
            syntax: "/notes <query>",
            examples: ["/notes mariadb permissions", "/n borg restore"],
            actions: "Up/Down, Enter opens the note (markdown asks Logseq / nvim / Vivify), Tab shows the original text, Ctrl+Shift+C copies path:line."
        },
        {
            name: "last",
            aliases: ["shot"],
            label: "Last screenshots",
            description: "Show the newest screenshots. /last 3 shows three.",
            helper: "Enter shows them. Then Enter on one to copy it, copy its path, or open it.",
            eventKey: "last.ready",
            placeholder: "how many (default 1)",
            icon: "󰹑",
            sourceHint: "screenshot folder · newest first",
            kind: "screenshots",
            takesArgument: true,
            argumentOptional: true,
            syntax: "/last [count]",
            examples: ["/last", "/last 3"],
            actions: "Appears as you type. Arrows move, Enter: copy image / copy path / show image."
        },
        {
            name: "fd",
            aliases: ["find"],
            label: "Find files",
            description: "Find files and folders by name or path with fd. Every word must match.",
            helper: "--f=<dir> searches elsewhere (default ~), --h includes hidden files.",
            eventKey: "fd.ready",
            placeholder: "words in the name or path",
            icon: "󰈞",
            sourceHint: "fd · ~ unless --f=",
            kind: "files",
            takesArgument: true,
            syntax: "/fd <words> [--f=<dir>] [--h]",
            examples: ["/fd kip", "/fd hyprland conf --f=/", "/fd jarvis memory --h"],
            actions: "Live after a short pause. Enter on a folder: open / terminal / broot / copy path; on a file: open / nvim / folder / copy path; markdown gets the note openers.",
            flags: {
                f: {
                    name: "from",
                    takesValue: true,
                    usage: "--f=<dir>",
                    help: "search this folder instead of ~ (--f=/ for everything)"
                },
                h: {
                    name: "hidden",
                    takesValue: false,
                    usage: "--h",
                    help: "include hidden files and folders"
                }
            }
        },
        {
            name: "rg",
            aliases: ["grep"],
            label: "Search contents",
            description: "Search inside files with ripgrep. Literal text, smart case.",
            helper: "--f=<dir> searches elsewhere (default ~), --h includes hidden files, --t=<type> limits to a file type (rg --type-list).",
            eventKey: "rg.ready",
            placeholder: "text inside files",
            icon: "󱎸",
            sourceHint: "ripgrep · ~ unless --f=",
            kind: "grep",
            takesArgument: true,
            syntax: "/rg <text> [--f=<dir>] [--h] [--t=<type>]",
            examples: ["/rg SUPER+TAB --f=~/.config/hypr", "/rg TODO --t=rust", "/rg bind --h"],
            actions: "Live after a short pause from 3 characters (Enter searches sooner). Gitignored files are skipped, like rg does. Up to 5 matches per file, 200 in total. Enter opens the action menu with nvim at the line first; markdown gets Vivify at the line too.",
            flags: {
                f: {
                    name: "from",
                    takesValue: true,
                    usage: "--f=<dir>",
                    help: "search this folder instead of ~"
                },
                h: {
                    name: "hidden",
                    takesValue: false,
                    usage: "--h",
                    help: "include hidden files and folders"
                },
                t: {
                    name: "type",
                    takesValue: true,
                    usage: "--t=<type>",
                    help: "only this rg file type, e.g. py, rust, md (rg --type-list)"
                }
            }
        },
        {
            name: "browse",
            aliases: ["b", "ls"],
            label: "Browse",
            description: "Walk folders one level at a time. The input is the path.",
            helper: "Enter opens a folder, or the actions of a file. Shift+Enter: folder actions. Alt+H hidden, Alt+I gitignored, Alt+P preview.",
            eventKey: "browse.ready",
            placeholder: "path, e.g. ~/.config/",
            icon: "󰉓",
            sourceHint: "fd · one level",
            kind: "browse",
            takesArgument: true,
            argumentOptional: true,
            syntax: "/browse [path]",
            examples: ["/browse", "/browse ~/.config/hypr/", "/browse /etc/sys"],
            actions: "What follows the last / filters the folder before it, so typing and Backspace walk around. Enter or Tab on a folder goes in, Alt+Up goes to the parent, ../ is listed too. Enter on a file opens its action menu (markdown gets the note openers); Shift+Enter on a folder opens the folder menu. Alt+H hidden files, Alt+I hide gitignored files, Alt+P preview of the selected file (text, image, or a note that it is binary)."
        },
        {
            name: "tldr",
            aliases: ["tl"],
            label: "tldr page",
            description: "Real tldr examples from the local cache, never the model's guess.",
            helper: "A curated examples page, not a summary of --help. Copy on each example.",
            eventKey: "tldr.ready",
            placeholder: "command, e.g. tar or git commit",
            icon: "󰘦",
            sourceHint: "~/.cache/tldr · offline",
            kind: "tldr",
            takesArgument: true,
            syntax: "/tldr <command> [subcommand]",
            examples: ["/tldr tar", "/tldr fd", "/tldr git commit"],
            actions: "Live as you type. Each example has Copy (placeholders like path/to/file stay as text to edit). Enter copies the whole page. Nothing is ever run. Pages come only from the local cache; refresh it yourself with tldr --update."
        },
        {
            name: "calc",
            aliases: ["c", "="],
            label: "Calculate",
            description: "Maths and units with qalc, offline. Shows how qalc read your input.",
            helper: "Live as you type. Enter copies the result and saves it to history.",
            eventKey: "calc.ready",
            placeholder: "expression, e.g. 5 km to mi",
            icon: "󰃬",
            sourceHint: "qalc · no currencies",
            kind: "calc",
            takesArgument: true,
            syntax: "/calc <expression>",
            examples: ["/calc 2^10 * 3", "/calc 5 km to mi", "/calc 90 min to h", "/calc sqrt(2)"],
            actions: "Live as you type. Enter copies the result and saves it to history, listed newest first under the input and narrowed by what you type; ↓ picks an entry, Enter copies its saved result, Shift+Enter recalculates it first (↻ marks results that depend on today/now), Tab puts its expression back to edit. qalc's own reading of the input is shown, because it will happily interpret nonsense as units. Currency is off: no exchange-rate downloads."
        },
        {
            name: "def",
            aliases: ["define"],
            label: "Define",
            description: "Offline dictionary lookup with sdcv (StarDict).",
            helper: "Exact word matches. Enter copies the definition.",
            eventKey: "def.ready",
            placeholder: "word",
            icon: "󰗚",
            sourceHint: "sdcv · offline",
            kind: "def",
            takesArgument: true,
            syntax: "/def <word>",
            examples: ["/def serendipity", "/def ephemeral"],
            actions: "Live after a short pause. Enter copies the definition as plain text. Needs StarDict dictionaries in ~/.stardict/dic (see sdcv -l)."
        },
        {
            name: "win",
            aliases: ["w", "window"],
            label: "Windows",
            description: "Switch to a window by class, title or workspace.",
            helper: "Every word must match. Enter switches workspace and focuses it.",
            eventKey: "win.ready",
            placeholder: "class or title words",
            icon: "󰖯",
            sourceHint: "hyprctl clients",
            kind: "windows",
            takesArgument: true,
            argumentOptional: true,
            syntax: "/win [words]",
            examples: ["/win", "/win firefox", "/win kitty qreep"],
            actions: "Lists windows, most recently focused first, as soon as you type the space, as a grid or list (Ctrl+L) of icons or live previews (Ctrl+P). Previews come from Expose's window matching; a window it cannot match safely shows its icon. Arrows move, Enter switches to the window's workspace and focuses it, then KIP closes."
        },
        {
            name: "p",
            aliases: ["proj", "project", "places"],
            label: "Projects",
            description: "Jump to a project from Places.",
            helper: "Every word must match the name, id, group or path. Enter opens it in Places.",
            eventKey: "projects.ready",
            placeholder: "project name",
            icon: "󰉋",
            sourceHint: "~/.config/qreep/places.json",
            kind: "projects",
            takesArgument: true,
            argumentOptional: true,
            syntax: "/p [words]",
            examples: ["/p", "/p eos", "/p coding mask"],
            actions: "Lists the projects from Places with branch, age, changed files and quests. Enter opens Places on the project, Shift+Enter launches its cockpit, Ctrl+Enter opens it in its editor; KIP closes."
        },
        {
            name: "ssh",
            aliases: ["hosts"],
            label: "SSH",
            description: "Connect to an ssh host from Places.",
            helper: "Every word must match the name, host or address. Enter connects in kitty.",
            eventKey: "ssh.ready",
            placeholder: "host name",
            icon: "󰣀",
            sourceHint: "Places ssh blocks, ~/.ssh/config",
            kind: "ssh",
            takesArgument: true,
            argumentOptional: true,
            syntax: "/ssh [words]",
            examples: ["/ssh", "/ssh cmask"],
            actions: "Lists the same ssh hosts as the Places ssh blocks, dimmed when the ssh port did not answer. Enter opens the host in kitty with kitten ssh (red-tinted theme while connected); KIP closes."
        },
        {
            name: "keys",
            aliases: ["binds", "k"],
            label: "Keys",
            description: "Look up a Hyprland keybinding by what it does or by its keys.",
            helper: "Every word must match the keys or the description. Enter copies the keys.",
            eventKey: "keys.ready",
            placeholder: "what it does, or keys",
            icon: "󰌌",
            sourceHint: "hyprctl binds",
            kind: "keys",
            takesArgument: true,
            argumentOptional: true,
            syntax: "/keys [words]",
            examples: ["/keys", "/keys screenshot", "/keys super shift"],
            actions: "Lists every bind with its description, in config order, as soon as you type the space. Words filter keys, description and submap; binds whose keys match come first. Enter copies the keys (SUPER+SHIFT+S). Nothing is run: with the Lua config every bind reports dispatcher __lua, so there is no command to replay."
        },
        {
            name: "timer",
            aliases: ["t"],
            label: "Timer",
            description: "Start, pause, resume or stop the Qreep timer.",
            helper: "Preview first, Enter does it. Same durations as the bar timer.",
            eventKey: "timer.ready",
            placeholder: "25m Tea · 15:03 Tea · up Focus · pause · stop",
            icon: "󰔛",
            sourceHint: "qreep-timer",
            kind: "timer",
            takesArgument: true,
            argumentOptional: true,
            syntax: "/timer [25m|1h30m|15:03|up|pause|resume|stop] [label]",
            examples: ["/timer", "/timer 25m Tea", "/timer 15:03 Standup", "/timer up Focus", "/timer stop"],
            actions: "Shows what will happen, including which running timer it replaces. Enter does it and closes KIP. Bare /timer shows the current timer."
        },
        {
            name: "run",
            aliases: ["r"],
            label: "Run",
            description: "Run a command, rofi-runner style, sharing its history. Terminal or background is decided for you.",
            helper: "Preview first: where it runs and why. Enter runs, Shift+Enter runs it the other way.",
            eventKey: "run.ready",
            placeholder: "command",
            icon: "󰆍",
            sourceHint: "rofi-runner history",
            kind: "run",
            takesArgument: true,
            argumentOptional: true,
            syntax: "/run <command line>",
            examples: ["/run htop", "/run pavucontrol", "/run df -h"],
            actions: "Up/Down picks from history and puts it in the input (Enter once more runs it). Enter runs; Shift+Enter runs it in the other mode and remembers that. Commands cinfo marks dangerous need a second Enter. Ctrl+Delete removes the selected history entry. Only what you type here ever runs."
        },
        {
            name: "qreep",
            aliases: ["q"],
            label: "Qreep",
            description: "Qreep actions: open panels, check updates, run the bar, wake Qreeper.",
            helper: "Grouped actions from what the running shell registers. Enter calls it; Ctrl+H shows every function.",
            eventKey: "qreep.ready",
            placeholder: "target function [arguments]",
            icon: "󰒓",
            sourceHint: "quickshell ipc · this instance",
            kind: "qreep",
            takesArgument: true,
            argumentOptional: true,
            syntax: "/qreep [target] [function] [arguments]",
            examples: ["/qreep upchecker toggle", "/qreep timer startCountdown 25m Tea break", "/qreep bar setCollapsed"],
            actions: "The list comes from quickshell ipc show for this process, so it is always what Qreep actually has; KipQreepCatalog.qml decides labels, groups, icons and what is worth listing. Script getters, hooks other programs call and duplicates are hidden; Ctrl+H shows them. Typing filters labels, targets and function names. Enter on an action without arguments calls it; with arguments it fills the input, and Tab cycles known values such as pill ids. Exact \"target function args\" calls hidden functions too. Calls that return nothing close KIP; calls that return a value show it."
        },
        {
            name: "help",
            aliases: ["?"],
            label: "Help",
            description: "List commands, or explain one: /help fd.",
            helper: "Appears as you type. Add a command name for its details.",
            eventKey: "help.ready",
            placeholder: "command",
            icon: "󰋖",
            sourceHint: "",
            kind: "help",
            takesArgument: true,
            argumentOptional: true,
            syntax: "/help [command]",
            examples: ["/help", "/help fd"],
            actions: "Read-only. Select and Ctrl+C like any answer."
        }
    ]

    // Shortcuts, grouped by where they apply. The Help sheet (header chip,
    // Ctrl+/) and /help both read this, so there is one list to keep honest.
    // id matches KipPanel.shortcutContext(), which puts the current group first.
    readonly property var shortcutGroups: [
        {
            id: "everywhere",
            title: "Everywhere",
            keys: [["F1, Ctrl+/", "this sheet"], ["F2", "app launcher"], ["F3", "/fd"], ["Shift+F3", "/rg"], ["F4", "/browse, starting at ~"], ["F5", "/win"], ["F6", "/qreep"], ["/", "command palette"], ["Tab", "complete the highlighted command"], ["Enter", "submit, or act on the selection"], ["Esc", "back one step, then close"], ["Ctrl+Esc", "close KIP"]]
        },
        {
            id: "apps",
            title: "Launcher",
            keys: [["←→↑↓", "move through the apps"], ["Enter", "launch and close KIP"], ["Ctrl+G", "group: category / name / A–Z"], ["Ctrl+L", "grid or list"], ["typing", "filter all apps, ranked"]]
        },
        {
            id: "browse",
            title: "/browse",
            keys: [["Enter, Tab", "into the folder"], ["Enter (file)", "its action menu"], ["Shift+Enter", "action menu, folders too"], ["Alt+↑", "parent folder"], ["Alt+H", "hidden files on/off"], ["Alt+I", "gitignored files on/off"], ["Alt+P", "preview on/off"]]
        },
        {
            id: "results",
            title: "/fd, /rg, /notes, /win, /keys",
            keys: [["↑↓", "move"], ["Enter", "open, or its action menu"], ["Tab", "original text of a note hit"], ["Ctrl+Shift+C", "copy path:line of a note hit"]]
        },
        {
            id: "menus",
            title: "Action menus",
            keys: [["↑↓, 1–9", "choose"], ["Enter", "do it"], ["Esc", "cancel"]]
        },
        {
            id: "run",
            title: "/run",
            keys: [["↑↓", "history into the input"], ["Enter", "run"], ["Shift+Enter", "run it the other way, remembered"], ["Ctrl+Delete", "forget that history entry"]]
        },
        {
            id: "answers",
            title: "Answers",
            keys: [["Enter", "answer actions: copy, retry, more detail"], ["Ctrl+C", "copy the selected text"], ["↑↓", "/notes-ask sources"]]
        },
        {
            id: "qreep",
            title: "/qreep",
            keys: [["typing", "filter actions"], ["↑↓", "move"], ["Enter", "call it, or fill in its arguments"], ["Tab", "complete the name, then cycle argument values"], ["Ctrl+H", "show every function, debug and hidden too"]]
        },
        {
            id: "shots",
            title: "/last",
            keys: [["←→↑↓", "move"], ["Enter", "copy image / copy path / show"]]
        }
    ]

    // Help as markdown, built from the registry above so it cannot drift
    // from what the parser actually accepts.
    function helpMarkdown(argument) {
        const wanted = String(argument || "").trim().replace(/^\//, "");

        if (wanted.length === 0)
            return overviewMarkdown();

        const command = find(wanted);

        if (command)
            return commandMarkdown(command);

        const guess = suggest(wanted);

        return "No command `/" + wanted + "`." + (guess ? " Did you mean `/" + guess.name + "`?" : "") + "\n\n" + overviewMarkdown();
    }

    function overviewMarkdown() {
        const lines = ["## Commands", ""];

        for (const command of commands)
            lines.push("- `" + command.syntax + "` " + command.description);
        lines.push("- plain text, no `/`: filter applications, same as `/app <name>`");
        lines.push("", "`/help <command>` shows syntax, flags and examples. Ctrl+/ shows the keys as a sheet.", "", "## Keys");
        for (const group of shortcutGroups) {
            lines.push("", "### " + group.title, "");
            for (const key of group.keys)
                lines.push("- **" + key[0] + "**: " + key[1]);
        }
        return lines.join("\n");
    }

    function commandMarkdown(command) {
        const lines = ["## /" + command.name, "", command.description, "", "```", command.syntax, "```"];

        if (command.aliases.length > 0)
            lines.push("", "Aliases: " + command.aliases.map(alias => "`/" + alias + "`").join(", "));

        if (command.flags) {
            lines.push("", "### Flags", "");
            for (const key in command.flags)
                lines.push("- `" + command.flags[key].usage + "` " + command.flags[key].help);
            lines.push("", "Only these flags. Native options of the underlying tool are not passed through.");
        }

        lines.push("", "### Examples", "", "```");
        for (const example of command.examples)
            lines.push(example);
        lines.push("```", "", "### After Enter", "", command.actions);
        return lines.join("\n");
    }

    // Closest command name or alias within two edits, for typos like /fdd.
    function suggest(token) {
        const needle = String(token || "").toLowerCase();
        let best = null;
        let bestDistance = 3;

        for (const command of commands) {
            for (const name of [command.name].concat(command.aliases)) {
                const distance = editDistance(needle, name);

                if (distance < bestDistance) {
                    best = command;
                    bestDistance = distance;
                }
            }
        }
        return best;
    }

    function editDistance(left, right) {
        const row = [];

        for (let j = 0; j <= right.length; j++)
            row.push(j);
        for (let i = 1; i <= left.length; i++) {
            let previous = row[0];

            row[0] = i;
            for (let j = 1; j <= right.length; j++) {
                const current = row[j];

                row[j] = Math.min(row[j] + 1, row[j - 1] + 1, previous + (left[i - 1] === right[j - 1] ? 0 : 1));
                previous = current;
            }
        }
        return row[right.length];
    }

    function find(token) {
        const needle = String(token || "").toLowerCase();

        for (let index = 0; index < commands.length; index++) {
            const command = commands[index];

            if (command.name === needle || command.aliases.indexOf(needle) >= 0)
                return command;
        }

        return null;
    }

    function matching(prefix) {
        const needle = String(prefix || "").toLowerCase();

        return commands.filter(command => command.name.startsWith(needle) || command.aliases.some(alias => alias.startsWith(needle)));
    }

    // Returns { mode, eventKey, command, token, argument, matches }.
    // mode: idle | plain | palette | candidate | ready | unknown
    function parse(text) {
        const raw = String(text || "");
        const trimmed = raw.trim();

        if (trimmed.length === 0)
            return result("idle", "kip.ready", null, "", "", []);

        if (!raw.startsWith("/"))
            return result("plain", "apps.ready", null, "", trimmed, []);

        const spaceAt = raw.search(/\s/);
        const token = spaceAt < 0 ? raw.slice(1) : raw.slice(1, spaceAt);
        const argument = spaceAt < 0 ? "" : raw.slice(spaceAt + 1).trim();

        if (spaceAt < 0) {
            if (token.length === 0)
                return result("palette", "kip.palette", null, token, "", commands);

            const exact = find(token);

            // "/help" and a bare "/last" are complete as typed.
            if (exact && (!exact.takesArgument || exact.argumentOptional))
                return result("ready", exact.eventKey, exact, token, "", commands);

            const matches = matching(token);

            if (matches.length > 0)
                return result("candidate", "kip.palette", exact, token, "", matches);

            return result("unknown", "command.unknown", null, token, "", commands);
        }

        const command = find(token);

        if (!command)
            return result("unknown", "command.unknown", null, token, argument, commands);

        const ready = result("ready", command.eventKey, command, token, argument, command.takesArgument ? [] : commands);

        if (command.flags)
            parseFlags(ready, raw, spaceAt + 1);

        return ready;
    }

    // Pulls --key / --key=value tokens out of the argument. Records where each
    // one sits in the raw text so the input can highlight it.
    function parseFlags(parsed, raw, start) {
        const pattern = /\S+/g;
        const words = [];
        let match;

        pattern.lastIndex = start;

        while ((match = pattern.exec(raw)) !== null) {
            const flag = /^--([A-Za-z]+)(?:=(.*))?$/.exec(match[0]);

            if (!flag) {
                words.push(match[0]);
                continue;
            }

            const spec = parsed.command.flags[flag[1]];
            const valid = spec !== undefined && (spec.takesValue ? flag[2] !== undefined && flag[2].length > 0 : flag[2] === undefined);

            parsed.flagRanges.push({
                start: match.index,
                end: match.index + match[0].length,
                known: valid
            });

            if (valid)
                parsed.flags[spec.name] = spec.takesValue ? flag[2] : true;
            else
                parsed.unknownFlags.push(match[0]);
        }

        parsed.argument = words.join(" ");
    }

    function result(mode, eventKey, command, token, argument, matches) {
        return {
            mode: mode,
            eventKey: eventKey,
            command: command,
            token: token,
            argument: argument,
            matches: matches,
            flags: ({}),
            unknownFlags: [],
            flagRanges: []
        };
    }
}
