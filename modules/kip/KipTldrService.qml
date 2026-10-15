import QtQuick
import Quickshell
import Quickshell.Io

// /tldr: real tldr pages, read straight from the client's local cache
// (~/.cache/tldr/pages/<platform>/<name>.md). KIP never runs the tldr client,
// so a lookup cannot fetch anything from the network; `tldr --update`
// (run by you) is what fills the cache. Nothing on a page is ever executed.
Item {
    id: rootKipTldrService

    required property QtObject theme

    readonly property QtObject kt: theme.modules.kip

    // idle | done | missing | nocache | invalid
    property string status: "idle"
    property string name: ""
    property string platform: ""
    property string rawPage: ""
    property string markdown: ""
    property string moreInfo: ""
    property string eventKey: ""

    FileView {
        id: pageReader

        blockLoading: true
        printErrors: false
    }

    // Tells "cache missing" apart from "page missing".
    Process {
        id: cacheProbe

        property string forName: ""

        onExited: exitCode => rootKipTldrService.finishProbe(forName, exitCode === 0)
    }

    function lookup(argument) {
        const words = String(argument || "").trim().toLowerCase().split(/\s+/).filter(word => word.length > 0);

        reset();

        if (words.length === 0)
            return;

        // tldr page names: "git commit" is git-commit.md. Anything else is
        // not a command name, and never becomes part of a path.
        if (!words.every(word => /^[a-z0-9][a-z0-9._+-]*$/.test(word))) {
            name = words.join(" ");
            status = "invalid";
            eventKey = "tldr.missing";
            markdown = "`" + name + "` is not a command name tldr would have a page for.";
            return;
        }

        name = words.join("-");

        for (const candidate of kt.tldrPlatforms) {
            const text = read(kt.tldrCacheDir + "/pages/" + candidate + "/" + name + ".md");

            if (text.length > 0) {
                platform = candidate;
                rawPage = text;
                markdown = render(text);
                status = "done";
                eventKey = "tldr.found";
                return;
            }
        }

        cacheProbe.running = false;
        cacheProbe.forName = name;
        cacheProbe.command = ["test", "-d", kt.tldrCacheDir + "/pages"];
        cacheProbe.running = true;
    }

    function finishProbe(forName, cacheExists) {
        if (forName !== name || status !== "idle")
            return;

        if (cacheExists) {
            status = "missing";
            eventKey = "tldr.missing";
            markdown = "No tldr page for `" + name + "` in the local cache (" + kt.tldrPlatforms.join(", ") + ").\n\n"
                + "Try `man " + name.split("-")[0] + "` or `" + name.split("-")[0] + " --help` in a terminal. KIP does not run them for you.";
        } else {
            status = "nocache";
            eventKey = "tldr.nocache";
            markdown = "The tldr cache is empty. Fill it once, in a terminal:\n\n```bash\ntldr --update\n```\n\nKIP reads only that cache and never downloads pages itself.";
        }
    }

    function reset() {
        status = "idle";
        name = "";
        platform = "";
        rawPage = "";
        markdown = "";
        moreInfo = "";
        eventKey = "";
    }

    function read(path) {
        pageReader.path = path;
        pageReader.waitForJob();
        return String(pageReader.text() || "");
    }

    // tldr page format → KIP markdown. Every example command becomes its own
    // fenced block, so each gets a Copy link. {{placeholders}} lose their
    // braces: what you copy is a template to edit, not literal braces.
    function render(page) {
        const out = [];
        const descriptions = [];

        for (const line of page.split("\n")) {
            const title = /^#\s+(.*)$/.exec(line);
            const quote = /^>\s?(.*)$/.exec(line);
            const example = /^-\s+(.*)$/.exec(line);
            const command = /^`(.*)`\s*$/.exec(line);

            if (title) {
                out.push("## " + title[1]);
            } else if (quote) {
                const info = /More information:\s*<(https?:\/\/[^>]+)>/.exec(quote[1]);

                if (info) {
                    moreInfo = info[1];
                    descriptions.push("More information: [" + info[1] + "](" + info[1] + ")");
                } else {
                    descriptions.push(quote[1]);
                }
            } else if (example) {
                if (descriptions.length > 0) {
                    out.push("", descriptions.join(" "));
                    descriptions.length = 0;
                }
                out.push("", "**" + example[1].replace(/:\s*$/, "") + "**");
            } else if (command) {
                out.push("```bash", command[1].replace(/\{\{(.*?)\}\}/g, "$1"), "```");
            }
        }

        if (descriptions.length > 0)
            out.push("", descriptions.join(" "));

        out.push("", "_tldr page · " + platform + " · local cache_");
        return out.join("\n");
    }
}
