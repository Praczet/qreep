import QtQuick

// Command registry and parser. No UI in here: the panel asks parse(text) what
// the input currently means and renders whatever comes back.
QtObject {
    id: rootKipCommands

    // kind: what Enter does. "ask" and "search" take an argument, "help" does
    // not, "screenshots" takes one optionally (argumentOptional).
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
            takesArgument: true
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
            takesArgument: true
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
            argumentOptional: true
        },
        {
            name: "help",
            aliases: ["?"],
            label: "Help",
            description: "List commands and keys.",
            helper: "Tab completes, Enter runs, Escape steps back.",
            eventKey: "help.ready",
            placeholder: "",
            icon: "󰋖",
            sourceHint: "",
            kind: "help",
            takesArgument: false
        }
    ]

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

        return result("ready", command.eventKey, command, token, argument, command.takesArgument ? [] : commands);
    }

    function result(mode, eventKey, command, token, argument, matches) {
        return {
            mode: mode,
            eventKey: eventKey,
            command: command,
            token: token,
            argument: argument,
            matches: matches
        };
    }
}
