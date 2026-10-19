import QtQuick
import Quickshell
import Quickshell.Io

// Places data: the project list from ~/.config/qreep/places.json, a cheap
// summary per project (git + questlog counts) when the panel opens, and the
// heavier details (commits, changes, recent files, stats, README, questlog)
// only for the selected project. Reads only; the only writes are the
// programs it launches.
Item {
    id: rootPlacesService

    required property QtObject theme

    readonly property QtObject pt: theme.modules.places
    readonly property string home: Quickshell.env("HOME")

    property var config: ({})
    property string configError: ""
    property var projects: []
    property var summaries: ({})
    property string query: ""
    readonly property var filtered: filterProjects(projects, query)
    property int selectedIndex: 0
    readonly property var selected: filtered.length > 0 ? filtered[Math.min(selectedIndex, filtered.length - 1)] : null
    readonly property var selectedSummary: selected ? (summaries[selected.id] || null) : null

    // Details of the selected project. detailFor guards against a slow reply
    // landing after the selection moved on.
    property string detailFor: ""
    property var detail: emptyDetail()
    property var languages: ({})
    property var questlog: null
    property string questlogError: ""
    property string readmeSummary: ""

    // Both read summaries[selected.id] directly, not selectedSummary: going
    // through the second binding briefly paired the new path with the old
    // project's summary and asked for files that do not exist.
    readonly property string questlogPath: questlogPathFor(selected, summaries)
    readonly property string readmePath: readmePathFor(selected, summaries)

    FileView {
        id: configFile

        path: rootPlacesService.pt.configPath
        preload: true
        watchChanges: true

        onFileChanged: reload()
        onLoaded: rootPlacesService.applyConfig(text())
        onLoadFailed: error => {
            rootPlacesService.configError = error === FileViewError.FileNotFound ? "No config at " + path : "Could not read " + path;
            rootPlacesService.projects = [];
        }
    }

    FileView {
        id: questlogFile

        path: rootPlacesService.questlogPath
        preload: path.length > 0
        watchChanges: true

        onFileChanged: reload()
        onLoaded: rootPlacesService.applyQuestlog(text())
        onLoadFailed: rootPlacesService.questlog = null
    }

    FileView {
        id: readmeFile

        path: rootPlacesService.readmePath
        preload: path.length > 0
        watchChanges: true

        onFileChanged: reload()
        onLoaded: rootPlacesService.readmeSummary = rootPlacesService.firstParagraph(text())
        onLoadFailed: rootPlacesService.readmeSummary = ""
    }

    onQuestlogPathChanged: {
        questlog = null;
        questlogError = "";
    }

    onReadmePathChanged: readmeSummary = ""

    Process {
        id: summaryProcess

        stdout: StdioCollector {
            id: summaryStdout

            waitForEnd: true
        }

        onExited: rootPlacesService.applySummaries(summaryStdout.text)
    }

    Process {
        id: detailProcess

        property string projectId: ""

        stdout: StdioCollector {
            id: detailStdout

            waitForEnd: true
        }

        onExited: rootPlacesService.applyDetail(detailProcess.projectId, detailStdout.text)
    }

    Process {
        id: tokeiProcess

        property string projectId: ""

        stdout: StdioCollector {
            id: tokeiStdout

            waitForEnd: true
        }

        onExited: rootPlacesService.applyLanguages(tokeiProcess.projectId, tokeiStdout.text)
    }

    Process {
        id: launcher
    }

    // Selection settles before the detail read starts, so arrowing through
    // the list does not spawn a git log per row.
    Timer {
        id: detailDelay

        interval: 120
        repeat: false
        onTriggered: rootPlacesService.loadDetail()
    }

    onSelectedChanged: {
        if (selected && selected.id !== detailFor) {
            detail = emptyDetail();
            detailDelay.restart();
        }
    }

    function refresh() {
        configFile.reload();
        refreshSummaries();
        detailFor = "";
        if (selected)
            detailDelay.restart();
    }

    function setQuery(text) {
        query = String(text || "");
        selectedIndex = 0;
    }

    function move(step) {
        if (filtered.length === 0)
            return;
        selectedIndex = Math.max(0, Math.min(filtered.length - 1, selectedIndex + step));
    }

    // --- config -----------------------------------------------------------

    function applyConfig(text) {
        let parsed;

        try {
            parsed = JSON.parse(text);
        } catch (error) {
            configError = "places.json: " + error.message;
            return;
        }

        const next = [];
        const groups = Array.isArray(parsed.groups) ? parsed.groups : [];

        for (const group of groups) {
            for (const entry of (Array.isArray(group.projects) ? group.projects : [])) {
                if (!entry || !entry.path)
                    continue;

                const path = expand(entry.path).replace(/\/+$/, "");
                next.push({
                    id: String(entry.id || entry.name || path),
                    name: String(entry.name || path.replace(/^.*\//, "")),
                    group: String(group.name || ""),
                    path: path,
                    displayPath: path.indexOf(home) === 0 ? "~" + path.slice(home.length) : path,
                    iconName: String(entry.iconName || ""),
                    icon: String(entry.icon || ""),
                    editor: String(entry.editor || ""),
                    cockpit: Array.isArray(entry.cockpit) ? entry.cockpit.map(String) : [],
                    links: (Array.isArray(entry.links) ? entry.links : []).map(link => ({
                                name: String(link.name || link.path),
                                path: expand(link.path || "")
                            })),
                    pinned: Array.isArray(entry.pinned) ? entry.pinned.map(String) : []
                });
            }
        }

        config = parsed;
        configError = "";
        projects = next;
        refreshSummaries();
    }

    // --- summaries (every project, cheap) -----------------------------------

    function refreshSummaries() {
        if (projects.length === 0)
            return;

        summaryProcess.running = false;
        summaryProcess.command = ["sh", "-c", summaryScript(), "places"].concat(projects.map(project => project.path));
        summaryProcess.running = true;
    }

    function summaryScript() {
        return "i=0; for p in \"$@\"; do "
            + "printf '@@P %s\\n' \"$i\"; i=$((i+1)); "
            + "[ -d \"$p\" ] || { printf '@@MISSING\\n'; continue; }; "
            + "if git -C \"$p\" rev-parse --git-dir >/dev/null 2>&1; then "
            + "printf '@@GIT\\n'; git -C \"$p\" status --porcelain=v2 --branch 2>/dev/null; "
            + "printf '@@LOG\\n'; git -C \"$p\" log -1 --format='%ct%x09%s' 2>/dev/null; fi; "
            + "[ -f \"$p/README.md\" ] && printf '@@README\\n'; "
            + "for f in docs/ai/QUESTLOG.json questlog.json QUESTLOG.json; do "
            + "if [ -f \"$p/$f\" ]; then printf '@@QL %s\\n' \"$f\"; "
            + "jq -c '[.quests[]? | {s: .status, b: ([.steps[]? | select(.status == \"blocked\")] | length)}]' \"$p/$f\" 2>/dev/null; break; fi; done; "
            + "done";
    }

    function applySummaries(text) {
        const next = {};
        let current = null;
        let section = "";

        for (const line of String(text || "").split("\n")) {
            const marker = /^@@(\w+)\s*(.*)$/.exec(line);

            if (marker) {
                section = marker[1];

                if (section === "P") {
                    const project = projects[Number(marker[2])];
                    current = project ? emptySummary() : null;
                    if (project)
                        next[project.id] = current;
                } else if (current && section === "MISSING") {
                    current.missing = true;
                } else if (current && section === "GIT") {
                    current.git = true;
                } else if (current && section === "README") {
                    current.readme = true;
                } else if (current && section === "QL") {
                    current.questlogFile = marker[2];
                }
                continue;
            }

            if (!current || line.length === 0)
                continue;

            if (section === "GIT")
                applyStatusLine(current, line);
            else if (section === "LOG") {
                const tab = line.indexOf("\t");
                current.lastCommitTime = Number(line.slice(0, tab)) || 0;
                current.lastCommitSubject = line.slice(tab + 1);
            } else if (section === "QL") {
                try {
                    const quests = JSON.parse(line);
                    current.quests = {
                        active: quests.filter(quest => quest.s === "active").length,
                        paused: quests.filter(quest => quest.s === "paused").length,
                        done: quests.filter(quest => quest.s === "done").length,
                        total: quests.length,
                        blockedSteps: quests.reduce((sum, quest) => sum + (quest.s === "done" ? 0 : quest.b), 0)
                    };
                } catch (error) {
                    current.quests = null;
                }
            }
        }

        summaries = next;
    }

    // `git status --porcelain=v2 --branch`: headers start with "#", entries do not.
    function applyStatusLine(summary, line) {
        if (line.indexOf("# branch.head ") === 0)
            summary.branch = line.slice(14);
        else if (line.indexOf("# branch.ab ") === 0) {
            const parts = line.slice(12).split(" ");
            summary.ahead = Math.abs(Number(parts[0]) || 0);
            summary.behind = Math.abs(Number(parts[1]) || 0);
        } else if (line[0] !== "#")
            summary.changed++;
    }

    function emptySummary() {
        return {
            missing: false,
            git: false,
            branch: "",
            ahead: 0,
            behind: 0,
            changed: 0,
            lastCommitTime: 0,
            lastCommitSubject: "",
            readme: false,
            questlogFile: "",
            quests: null
        };
    }

    // --- details (selected project only) ------------------------------------

    function loadDetail() {
        const project = selected;

        if (!project)
            return;

        detailFor = project.id;
        detailProcess.running = false;
        detailProcess.projectId = project.id;
        detailProcess.command = ["sh", "-c", detailScript(), "places", project.path, String(pt.recentFileDays), String(pt.recentFileLimit), String(pt.commitLimit), String(pt.activityWeeks)];
        detailProcess.running = true;

        if (languages[project.id] === undefined) {
            tokeiProcess.running = false;
            tokeiProcess.projectId = project.id;
            // Reports are dropped in jq: the full tokei JSON lists every file.
            tokeiProcess.command = ["sh", "-c", "cd \"$1\" && tokei -o json . 2>/dev/null | jq -c 'to_entries | map({n: .key, c: .value.code, f: ((.value.reports // []) | length)})'", "places", project.path];
            tokeiProcess.running = true;
        }
    }

    function detailScript() {
        // $1 path, $2 recent days, $3 recent limit, $4 commit limit, $5 activity weeks
        return "cd \"$1\" 2>/dev/null || exit 0; "
            + "if git rev-parse --git-dir >/dev/null 2>&1; then "
            + "printf '@@STATUS\\n'; git status --porcelain=v1 2>/dev/null | head -n 40; "
            + "printf '@@COMMITS\\n'; git log -n \"$4\" --format='%h%x09%ct%x09%an%x09%s' 2>/dev/null; "
            + "printf '@@ACTIVITY\\n'; git log --since=\"$5 weeks ago\" --format=%ct 2>/dev/null; "
            + "printf '@@COUNT\\n'; git rev-list --count HEAD 2>/dev/null; fi; "
            // fd honours .gitignore, so build output and vendor trees stay out.
            + "printf '@@RECENT\\n'; fd --type f --changed-within \"$2\"d --exclude .git --exec-batch stat -c '%Y\t%n' 2>/dev/null | sort -rn | head -n \"$3\"; "
            + "printf '@@PINNED\\n'; for f in README.md AGENTS.md CLAUDE.md docs/ai/CURRENT.md; do [ -f \"$f\" ] && printf '%s\\n' \"$f\"; done; "
            + "printf '@@FILES\\n'; fd --type f 2>/dev/null | wc -l";
    }

    function applyDetail(projectId, text) {
        if (!selected || selected.id !== projectId)
            return;

        const next = emptyDetail();
        let section = "";

        for (const line of String(text || "").split("\n")) {
            const marker = /^@@(\w+)$/.exec(line);

            if (marker) {
                section = marker[1];
                continue;
            }
            if (line.length === 0)
                continue;

            if (section === "STATUS")
                next.changes.push({
                    status: line.slice(0, 2).trim() || "?",
                    path: line.slice(3)
                });
            else if (section === "COMMITS") {
                const parts = line.split("\t");
                next.commits.push({
                    hash: parts[0],
                    time: Number(parts[1]) || 0,
                    author: parts[2] || "",
                    subject: parts.slice(3).join("\t")
                });
            } else if (section === "ACTIVITY")
                next.activityTimes.push(Number(line) || 0);
            else if (section === "COUNT")
                next.commitCount = Number(line) || 0;
            else if (section === "RECENT") {
                const tab = line.indexOf("\t");
                next.recent.push({
                    time: Number(line.slice(0, tab)) || 0,
                    path: line.slice(tab + 1).replace(/^\.\//, "")
                });
            } else if (section === "PINNED")
                next.autoPinned.push(line);
            else if (section === "FILES")
                next.fileCount = Number(line.trim()) || 0;
        }

        next.activity = weeklyBuckets(next.activityTimes, pt.activityWeeks);
        detail = next;
    }

    function applyLanguages(projectId, text) {
        let rows = [];

        try {
            rows = JSON.parse(String(text || "").trim() || "[]");
        } catch (error) {
            rows = [];
        }

        const total = rows.find(row => row.n === "Total");
        const next = Object.assign({}, languages);

        next[projectId] = {
            total: total ? total.c : 0,
            rows: rows.filter(row => row.n !== "Total" && row.c > 0).sort((left, right) => right.c - left.c).slice(0, pt.languageLimit)
        };
        languages = next;
    }

    function emptyDetail() {
        return {
            changes: [],
            commits: [],
            activityTimes: [],
            activity: [],
            commitCount: 0,
            recent: [],
            autoPinned: [],
            fileCount: 0
        };
    }

    // Pinned = config pins first, then the usual suspects that exist.
    function pinnedFiles() {
        if (!selected)
            return [];

        const files = selected.pinned.slice();

        for (const file of detail.autoPinned) {
            if (files.indexOf(file) < 0)
                files.push(file);
        }
        return files;
    }

    function weeklyBuckets(times, weeks) {
        const buckets = new Array(weeks).fill(0);
        const now = Date.now() / 1000;
        const week = 7 * 24 * 3600;

        for (const time of times) {
            const age = Math.floor((now - time) / week);
            if (age >= 0 && age < weeks)
                buckets[weeks - 1 - age]++;
        }
        return buckets;
    }

    // --- questlog / README ------------------------------------------------

    function applyQuestlog(text) {
        try {
            const parsed = JSON.parse(text);
            const rank = {
                active: 0,
                paused: 1,
                todo: 2,
                done: 3
            };
            const quests = (Array.isArray(parsed.quests) ? parsed.quests : []).slice();

            quests.sort((left, right) => (rank[left.status] ?? 2) - (rank[right.status] ?? 2) || String(right.updatedAt || "").localeCompare(String(left.updatedAt || "")));
            questlog = {
                updatedAt: parsed.updatedAt || "",
                updatedBy: parsed.updatedBy || "",
                quests: quests
            };
            questlogError = "";
        } catch (error) {
            questlog = null;
            questlogError = "Questlog does not parse: " + error.message;
        }
    }

    // First real paragraph: skip headings, badges, HTML, tables and quotes.
    function firstParagraph(text) {
        const lines = String(text || "").split("\n");
        const paragraph = [];
        let inFence = false;

        for (const raw of lines) {
            const line = raw.trim();

            if (line.indexOf("```") === 0) {
                inFence = !inFence;
                continue;
            }
            if (inFence)
                continue;
            if (line.length === 0) {
                if (paragraph.length > 0)
                    break;
                continue;
            }
            if (/^(#|!\[|\[!\[|<|\||>|---|===|\* |- |\d+\. )/.test(line)) {
                if (paragraph.length > 0)
                    break;
                continue;
            }
            paragraph.push(line);
        }

        const joined = paragraph.join(" ").replace(/\*\*|__|`/g, "").replace(/\[([^\]]+)\]\([^)]*\)/g, "$1");
        return joined.length > 320 ? joined.slice(0, 317) + "…" : joined;
    }

    // --- actions ----------------------------------------------------------

    function editorFor(project) {
        const editors = config.editors || {};
        const name = (project && project.editor) || config.defaultEditor || "nvim";

        return editors[name] || {
            command: ["nvim", "{path}"],
            terminal: true
        };
    }

    function editorNames() {
        return Object.keys(config.editors || {});
    }

    function openInEditor(project, file, editorName) {
        if (!project)
            return;

        const editors = config.editors || {};
        const editor = editorName && editors[editorName] ? editors[editorName] : editorFor(project);
        const target = file ? project.path + "/" + file : project.path;

        launch(editor, target, project.path);
    }

    function openFolder(project, path) {
        if (!project)
            return;
        launch(config.fileManager || {
            command: ["yazi", "{path}"],
            terminal: true
        }, path || project.path, path || project.path);
    }

    function openTerminal(project) {
        if (!project)
            return;
        run(terminalPrefix(project.path), project.path);
    }

    function openCockpit(project) {
        if (!project)
            return;
        if (project.cockpit.length === 0) {
            openInEditor(project, "");
            return;
        }
        run(project.cockpit.map(arg => expand(arg)), project.path);
    }

    function openLink(project, link) {
        openFolder(project, link.path);
    }

    function launch(spec, path, cwd) {
        const command = (spec.command || []).map(arg => expand(String(arg).replace("{path}", path).replace("{cwd}", cwd)));

        if (command.length === 0)
            return;

        run(spec.terminal ? terminalPrefix(cwd).concat(["-e"]).concat(command) : command, cwd);
    }

    function terminalPrefix(cwd) {
        const prefix = Array.isArray(config.terminal) ? config.terminal : ["ghostty", "--working-directory={cwd}"];

        return prefix.map(arg => expand(String(arg).replace("{cwd}", cwd)));
    }

    function run(command, cwd) {
        launcher.command = command;
        launcher.workingDirectory = cwd;
        launcher.startDetached();
    }

    // --- helpers ----------------------------------------------------------

    function questlogPathFor(project, all) {
        const summary = project ? all[project.id] : null;
        return summary && summary.questlogFile ? project.path + "/" + summary.questlogFile : "";
    }

    function readmePathFor(project, all) {
        const summary = project ? all[project.id] : null;
        return summary && summary.readme ? project.path + "/README.md" : "";
    }

    function filterProjects(list, text) {
        const words = String(text || "").toLowerCase().split(/\s+/).filter(word => word.length > 0);

        if (words.length === 0)
            return list;

        return list.filter(project => {
            const haystack = (project.name + " " + project.id + " " + project.group + " " + project.displayPath).toLowerCase();
            return words.every(word => haystack.indexOf(word) >= 0);
        });
    }

    function expand(path) {
        const value = String(path || "");
        return value === "~" ? home : value.indexOf("~/") === 0 ? home + value.slice(1) : value;
    }

    function iconSource(project) {
        if (!project || !project.iconName)
            return "";

        // Theme first; then the ADArtWork folder. A missing file just makes
        // PlacesIcon fall back to the glyph or the first letter.
        return Quickshell.iconPath(project.iconName, true) || "file://" + pt.iconFallbackDir + "/" + project.iconName + ".svg";
    }

    function ago(seconds) {
        if (!seconds)
            return "";

        const delta = Math.max(0, Date.now() / 1000 - seconds);

        if (delta < 60)
            return "now";
        if (delta < 3600)
            return Math.floor(delta / 60) + "m";
        if (delta < 86400)
            return Math.floor(delta / 3600) + "h";
        if (delta < 86400 * 60)
            return Math.floor(delta / 86400) + "d";
        return Math.floor(delta / (86400 * 30)) + "mo";
    }

    function formatCount(value) {
        const number = Number(value) || 0;
        return number >= 10000 ? (number / 1000).toFixed(number >= 100000 ? 0 : 1) + "k" : String(number).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }
}
