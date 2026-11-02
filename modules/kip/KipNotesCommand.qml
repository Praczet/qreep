import QtQuick

// /kip: what the kip terminal command does, from the launcher. This only decides
// what the input means. KipNotesService runs kip, which owns the notes and tags.
//
//   /kip qsv: process CSV              remember it
//   /kip try qsv: process CSV          try it later
//   /kip idea Mox reads my shortcuts   think about it
//   /kip todo renew the domain         a plain Logseq TODO
//   /kip qsv --example qsv stats a.csv everything after --example is literal
//   /kip list [todo|note|try|idea|shortcut|tip]
QtObject {
    id: rootKipNotesCommand

    readonly property var saveCommands: ({
        add: { tag: "#kip", label: "Remember" },
        try: { tag: "#kip/try", label: "To try" },
        idea: { tag: "#kip/idea", label: "Idea" },
        todo: { tag: "", label: "To do" }
    })
    readonly property var listKinds: ["todo", "note", "try", "idea", "shortcut", "tip"]
    // Shortcuts and tips have their own homes in /keys and the shell, so a plain
    // list stays about the things you wrote down yourself.
    readonly property var defaultListKinds: ["todo", "note", "try", "idea"]

    // Returns { action, valid, kinds, args, tag, text, example, preview, error }.
    // args is the argv after "kip", never a shell string.
    function plan(argument) {
        const raw = String(argument || "").trim();
        const words = raw.length > 0 ? raw.split(/\s+/) : [];
        const first = (words[0] || "").toLowerCase();

        if (words.length === 0)
            return result("help", false, { preview: helpMarkdown() });

        if (first === "list")
            return planList(words.slice(1));

        const command = Object.keys(saveCommands).indexOf(first) >= 0 ? first : "add";
        const rest = command === first ? raw.slice(words[0].length).trim() : raw;

        return planSave(command, rest);
    }

    function planList(words) {
        if (words.length === 0)
            return result("list", true, { kinds: defaultListKinds, args: ["list", "--json"] });

        const kind = words[0].toLowerCase();

        if (words.length > 1 || listKinds.indexOf(kind) < 0)
            return result("list", false, {
                preview: helpMarkdown(),
                error: "List one of: " + listKinds.join(", ") + "."
            });

        return result("list", true, { kinds: [kind], args: ["list", "--json", "--kind", kind] });
    }

    function planSave(command, rest) {
        const split = /(?:^|\s)--example(?:=|\s+)/.exec(rest);
        const text = (split ? rest.slice(0, split.index) : rest).trim();
        const example = split ? rest.slice(split.index + split[0].length).trim() : "";
        const spec = saveCommands[command];

        if (text.length === 0)
            return result("save", false, { preview: helpMarkdown(), error: "Write what it is and what it is for." });

        const args = [command];

        // One argv item each, and -- keeps a note starting with a dash from reading as a flag.
        if (example.length > 0)
            args.push("--example=" + example);
        args.push("--", text);

        return result("save", true, {
            args: args,
            tag: spec.tag,
            text: text,
            example: example,
            preview: "## " + spec.label + "\n\n```\n- " + (command === "todo" ? "TODO " + text.replace(/^TODO\s+/, "") : text + " " + spec.tag)
                + (example.length > 0 ? "\n  example:: " + example : "")
                + "\n```\n\nEnter saves this to today's journal."
        });
    }

    function result(action, valid, fields) {
        return Object.assign({
            action: action,
            valid: valid,
            kinds: [],
            args: [],
            tag: "",
            text: "",
            example: "",
            preview: "",
            error: ""
        }, fields);
    }

    // Turns kip's kip-items document into the page /kip list shows.
    function listMarkdown(document, kinds) {
        if (!document || document.schemaVersion !== 1 || document.format !== "kip-items")
            return "kip returned something this version does not understand.";

        const items = (document.items || []).filter(item => kinds.indexOf(item.kind) >= 0);
        const failed = (document.sources || []).filter(source => source.status === "error");
        const warning = failed.length > 0
            ? "Could not read: " + failed.map(source => source.id).join(", ") + ". This list may be short.\n\n"
            : "";

        if (items.length === 0)
            return warning + "Nothing here yet. Add one with `/kip try something: what it is for`.";

        return warning + kinds.map(kind => {
            const matching = items.filter(item => item.kind === kind);

            if (matching.length === 0)
                return "";
            return "## " + kind + " · " + matching.length + "\n\n" + matching.map(line).join("\n");
        }).filter(section => section.length > 0).join("\n\n");
    }

    function line(item) {
        const text = item.text ? ": " + item.text : "";
        const example = item.example ? "\n  - `" + item.example + "`" : "";
        return "- **" + item.title + "**" + text + example;
    }

    function helpMarkdown() {
        return "## Kip\n\nKeeps what you find, in today's Logseq journal.\n\n"
            + "- `/kip qsv: process CSV` remember it\n"
            + "- `/kip try qsv: process CSV` try it later\n"
            + "- `/kip idea Mox reads my shortcuts` think about it\n"
            + "- `/kip todo renew the domain` a plain Logseq TODO\n"
            + "- `/kip qsv: tables --example qsv table a.csv` everything after `--example` is literal\n"
            + "- `/kip list` or `/kip list try` see what is there\n\n"
            + "Plain text that starts with `try`, `idea`, `todo` or `list` needs `/kip add` in front.";
    }
}
