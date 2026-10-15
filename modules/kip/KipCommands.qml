import QtQuick

// Command registry and parser. No UI in here: the panel asks parse(text) what
// the input currently means and renders whatever comes back.
QtObject {
    id: rootKipCommands

    // kind: what Enter does. "ask" and "search" take an argument, "help" does
    // not, "screenshots" takes one optionally (argumentOptional).
    // flags: --key or --key=value tokens anywhere in the argument, parsed out
    // before the rest becomes the argument. Only commands with flags get them;
    // "/ask --foo" stays literal text.
    readonly property var commands: [
        {
            name: "ask",
            aliases: ["a"],
            label: "Ask notes",
            description: "Answer a question using your indexed notes as context.",
            helper: "Type the question, then Enter. Sources come first, prose second.",
            eventKey: "ask.ready",
            placeholder: "question about your notes",
            icon: "󰭹",
            sourceHint: "~/Notes index · local model",
            kind: "ask",
            takesArgument: true,
            syntax: "/ask <question>",
            examples: ["/ask How do I inspect MariaDB user privileges?"],
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

    readonly property var keys: [
        ["Enter", "submit, or act on the selected result"],
        ["Tab", "complete a command; on results, show the original text"],
        ["Up / Down", "move through commands or results"],
        ["Esc", "results back to the prompt, then close"],
        ["1 – 9", "pick an option in an action chooser"],
        ["Ctrl+C", "copy the selected answer text (after selecting with the mouse)"],
        ["Ctrl+Shift+C", "copy path:line of the selected note"]
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
        lines.push("- plain text, no `/`: a general question to the local model, no notes as context");
        lines.push("", "`/help <command>` shows syntax, flags and examples.", "", "## Keys", "");
        for (const key of keys)
            lines.push("- **" + key[0] + "**: " + key[1]);
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
            return result("plain", "general.ready", null, "", trimmed, []);

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
