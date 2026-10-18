import QtQuick
import Quickshell.Io

// /def: offline definitions from sdcv (StarDict). sdcv -j prints a JSON list
// of { dict, word, definition }; an empty list means no match, or no
// dictionaries installed at all (`sdcv -l` tells which).
Item {
    id: rootKipDictService

    required property QtObject theme

    readonly property QtObject kt: theme.modules.kip

    // idle | busy | done | empty | nodict | error
    property string status: "idle"
    property string word: ""
    property var entries: []
    property string eventKey: ""
    property string markdown: ""
    property int requestId: 0
    property var activeProcess: null
    // Learned from `sdcv -l` once; -1 = not checked yet.
    property int dictionaryCount: -1

    Component {
        id: sdcvComponent

        Process {
            id: sdcvProcess

            property int ownerId: -1

            stdout: StdioCollector {
                id: sdcvStdout

                waitForEnd: true
            }

            onExited: exitCode => rootKipDictService.finish(sdcvProcess.ownerId, exitCode, sdcvStdout.text)
        }
    }

    Process {
        id: listProcess

        command: [rootKipDictService.kt.dictCommand, "-n", "-l"]
        running: true

        stdout: StdioCollector {
            id: listStdout

            waitForEnd: true
        }

        // First line is the "Dictionary's name   Word count" header.
        onExited: exitCode => {
            rootKipDictService.dictionaryCount = exitCode === 0 ? Math.max(0, String(listStdout.text).trim().split("\n").length - 1) : 0;
            rootKipDictService.settleEmpty();
        }
    }

    // A miss while the count says 0 waits for a recount, so installing a
    // dictionary takes effect without reloading Quickshell.
    property bool emptyPending: false

    function lookup(text) {
        cancel();
        word = String(text || "").trim();

        if (word.length === 0) {
            status = "idle";
            return;
        }

        status = "busy";

        // -n non-interactive, -j JSON, -0/-1 UTF-8 out/in, -e exact matches
        // only (fuzzy hits for half-typed words are noise while typing).
        const process = sdcvComponent.createObject(rootKipDictService, {
            ownerId: requestId,
            command: [kt.dictCommand, "-n", "-j", "-e", "-0", "-1", "--", word]
        });

        activeProcess = process;
        process.running = true;
    }

    function cancel() {
        requestId++;

        if (activeProcess) {
            const process = activeProcess;

            activeProcess = null;
            process.running = false;
            process.destroy();
        }
    }

    function reset() {
        cancel();
        status = "idle";
        word = "";
        entries = [];
        eventKey = "";
        markdown = "";
    }

    function finish(ownerId, exitCode, stdoutText) {
        if (ownerId !== requestId)
            return;

        const process = activeProcess;

        activeProcess = null;
        if (process)
            process.destroy();

        let parsed = null;

        try {
            parsed = JSON.parse(String(stdoutText).trim() || "[]");
        } catch (error) {
            status = "error";
            eventKey = "def.empty";
            markdown = "sdcv answered with something that is not JSON.";
            return;
        }

        entries = Array.isArray(parsed) ? parsed : [];

        if (entries.length > 0) {
            status = "done";
            eventKey = "def.found";
            markdown = render(entries);
            return;
        }

        if (dictionaryCount === 0 && !emptyPending) {
            emptyPending = true;
            listProcess.running = true;
            return;
        }

        settleEmpty();
    }

    function settleEmpty() {
        if (!emptyPending && status !== "busy")
            return;
        if (listProcess.running)
            return;

        emptyPending = false;

        if (dictionaryCount === 0) {
            status = "nodict";
            eventKey = "def.nodict";
            markdown = "sdcv has no dictionaries installed, so there is nothing to look `" + word + "` up in.\n\n"
                + "On Arch they come from the AUR and install to `/usr/share/stardict/dic/`, which sdcv reads by default. WordNet is a good first one:\n\n"
                + "```bash\nparu -S stardict-wordnet\n```\n\n"
                + "Broader and newer: `stardict-wikt-en-en` (English Wiktionary). Your own files can go in `~/.stardict/dic/`. `sdcv -l` lists what sdcv sees.";
            return;
        }

        status = "empty";
        eventKey = "def.empty";
        markdown = "No exact entry for `" + word + "` in " + (dictionaryCount > 0 ? dictionaryCount + " dictionar" + (dictionaryCount === 1 ? "y." : "ies.") : "the installed dictionaries.");
    }

    // Definitions arrive as each dictionary's own text format. Parse the two
    // known shapes (WordNet, Wiktionary dumps) into
    //   { dict, word, groups: [{ pos, senses: [{ text, examples, synonyms }] }] }
    // and render that as wrapping prose. Anything else falls back to cleaned
    // paragraphs. Never a code block: definitions must wrap.
    function render(list) {
        const parsed = list.map(entry => parse(entry));
        const out = ["## " + String(list[0].word || word)];

        for (const entry of parsed) {
            out.push("", "### " + dictLabel(entry.dict), "");
            if (entry.groups.length === 0) {
                for (const paragraph of entry.fallback)
                    out.push(safe(paragraph), "");
                continue;
            }
            for (const group of entry.groups) {
                if (group.pos.length > 0)
                    out.push("**" + group.pos + "**", "");
                group.senses.forEach((sense, index) => {
                    let line = (index + 1) + ". " + safe(sense.text);

                    if (sense.examples.length > 0)
                        line += " — " + sense.examples.map(example => "_" + safe(example) + "_").join("; ");
                    if (sense.synonyms.length > 0)
                        line += " · syn: " + sense.synonyms.map(safe).join(", ");
                    out.push(line);
                });
                out.push("");
            }
        }
        return out.join("\n");
    }

    function plainText() {
        return entries.map(entry => parse(entry)).map(entry => {
            const lines = [String(entry.word) + " (" + dictLabel(entry.dict) + ")"];

            if (entry.groups.length === 0)
                return lines.concat(entry.fallback).join("\n");
            for (const group of entry.groups) {
                if (group.pos.length > 0)
                    lines.push(group.pos);
                group.senses.forEach((sense, index) => lines.push("  " + (index + 1) + ". " + sense.text + (sense.examples.length > 0 ? " (" + sense.examples.join("; ") + ")" : "") + (sense.synonyms.length > 0 ? " [syn: " + sense.synonyms.join(", ") + "]" : "")));
            }
            return lines.join("\n");
        }).join("\n\n");
    }

    function parse(entry) {
        const dictName = String(entry.dict || "");
        const headword = String(entry.word || word);
        const text = String(entry.definition || "").replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]+>/g, "");
        const result = {
            dict: dictName,
            word: headword,
            groups: [],
            fallback: []
        };

        if (/^\s*(n|v|adj|adv|s)(\s+1)?\s*:\s/m.test(text) || /^wordnet/i.test(dictName))
            result.groups = parseWordNet(text);
        else if (/^wikt/i.test(dictName))
            result.groups = parseWiktionary(text, headword);

        if (result.groups.length === 0)
            result.fallback = text.split(/\n\s*\n|\n/).map(line => line.trim()).filter(line => line.length > 0);
        return result;
    }

    // "n 1: def; "ex" [syn: {a}, {b}]  2: …  v 1: …", hard-wrapped with indentation.
    function parseWordNet(text) {
        // Skip the headword line(s): the body starts at the first "n 1:" / "1:".
        const lines = text.split("\n");
        const first = lines.findIndex(line => /^\s*((n|v|adj|adv|s)(\s+\d+)?\s*|\d+):\s/.test(line));
        // Multi-part-of-speech entries repeat the headword line before each
        // block; drop those so they do not glue onto the previous sense.
        const headword = lines.slice(0, Math.max(0, first)).join(" ").trim().toLowerCase();
        const body = lines.slice(Math.max(0, first)).filter(line => line.trim().toLowerCase() !== headword || headword.length === 0).join(" ").replace(/\s+/g, " ").trim();
        // "n 1:", "2:", and "adj :" for a part of speech with a single sense.
        const marker = /(?:^|\s)(?:(n|v|adj|adv|s)(?:\s+\d+)?\s*|\d+):\s/g;
        const starts = [];
        let match;

        while ((match = marker.exec(body)) !== null)
            starts.push({ index: match.index, end: marker.lastIndex, pos: match[1] || "" });

        const groups = [];

        starts.forEach((start, i) => {
            const chunk = body.slice(start.end, i + 1 < starts.length ? starts[i + 1].index : body.length).trim();

            if (start.pos.length > 0 || groups.length === 0)
                groups.push({ pos: posName(start.pos), senses: [] });
            groups[groups.length - 1].senses.push(wordNetSense(chunk));
        });
        return groups.filter(group => group.senses.length > 0);
    }

    function wordNetSense(chunk) {
        const synonyms = [];
        let rest = chunk.replace(/\[(syn|ant|also):\s*([^\]]*)\]/g, (match, kind, list) => {
            if (kind === "syn")
                synonyms.push(...list.split(/\},?\s*/).map(item => item.replace(/[{}]/g, "").trim()).filter(item => item.length > 0));
            return "";
        }).trim();
        const examples = [];

        rest = rest.replace(/;?\s*"([^"]+)"/g, (match, example) => {
            examples.push(example);
            return "";
        }).replace(/[{}]/g, "").replace(/[;\s]+$/, "").trim();

        return { text: rest, examples: examples, synonyms: synonyms };
    }

    // "n." / "a." lines start parts of speech (repeated groups merge);
    // "(l en x)", "(gloss: …)", "(lb …)", "#English" are template residue.
    function parseWiktionary(text, headword) {
        const groups = [];
        const byPos = {};
        let current = null;

        for (const raw of text.split("\n")) {
            const line = raw.trim();
            const pos = /^([a-z]+)\.$/.exec(line);

            if (line.length === 0)
                continue;
            if (pos) {
                const name = posName(pos[1]);

                if (byPos[name] === undefined) {
                    byPos[name] = groups.length;
                    groups.push({ pos: name, senses: [] });
                }
                current = groups[byPos[name]];
                continue;
            }

            const cleaned = cleanWikt(line.replace(/^\d+\s+/, ""), headword);

            if (!/[A-Za-z]{3}/.test(cleaned.replace(/\([^)]*\)/g, "")))
                continue;
            if (!current) {
                byPos[""] = groups.length;
                groups.push({ pos: "", senses: [] });
                current = groups[groups.length - 1];
            }
            current.senses.push({ text: cleaned, examples: [], synonyms: [] });
        }
        return groups.filter(group => group.senses.length > 0);
    }

    function cleanWikt(line, headword) {
        return line.replace(/\(l [a-z-]+ ([^)]+)\)/g, (match, linked) => linked.trim().toLowerCase() === headword.toLowerCase() ? "" : linked)
            .replace(/\(gloss:\s*([^)]*)\)/g, "$1")
            .replace(/\(lb [^)]*\)/g, "")
            .replace(/#[A-Z][A-Za-z]*/g, "")
            .replace(/\s+([,;.])/g, "$1")
            .replace(/\s+/g, " ")
            .trim();
    }

    function posName(code) {
        return ({
                n: "noun",
                v: "verb",
                a: "adjective",
                adj: "adjective",
                s: "adjective",
                adv: "adverb",
                prep: "preposition",
                conj: "conjunction",
                pron: "pronoun",
                interj: "interjection",
                num: "numeral",
                det: "determiner",
                art: "article",
                abbr: "abbreviation",
                phr: "phrase"
            })[code] || code;
    }

    function dictLabel(name) {
        const match = /^wikt-([a-z]+)-([a-z]+)-(\d{4}-\d{2}-\d{2})$/.exec(name);

        return match ? "Wiktionary (" + match[1] + "→" + match[2] + ", " + match[3] + ")" : name;
    }

    // Dictionary text goes through the markdown renderer: keep its markers inert.
    function safe(text) {
        return String(text).replace(/[`*_]/g, "").replace(/^\s*(#+|>|-|\d+[.)])\s/, "$1\u00a0");
    }
}
