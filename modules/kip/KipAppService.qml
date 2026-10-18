import QtQuick
import Quickshell
import Quickshell.Io

// App launcher data: desktop entries from Quickshell, grouped or searched,
// plus a tiny launch log so "Most used" and "Recent" have something to say.
// The log is one SQLite table written through the sqlite3 CLI; it records
// which desktop entry id KIP launched and when. Nothing else.
Item {
    id: rootKipAppService

    required property QtObject theme

    readonly property QtObject kt: theme.modules.kip
    readonly property string dbPath: Quickshell.env("HOME") + "/.local/share/qreep/kip/apps.db"

    // Runtime choices, kept here because the panel is destroyed on close.
    // category | name | letter
    property string grouping: kt.appDefaultGrouping
    // grid | list
    property string view: kt.appDefaultView

    readonly property var apps: {
        const seen = {};
        const values = DesktopEntries.applications.values;

        return values.filter(entry => {
            if (!entry || entry.noDisplay || seen[entry.id])
                return false;
            seen[entry.id] = true;
            return true;
        }).sort((left, right) => left.name.localeCompare(right.name));
    }

    // app id -> { count, last, hours: [24 launch counts by local hour] }
    property var usage: ({})
    property string errorText: ""
    property var pendingSql: []

    // Freedesktop main categories, folded into names a person would use.
    readonly property var categoryNames: ({
            AudioVideo: "Multimedia",
            Audio: "Multimedia",
            Video: "Multimedia",
            Development: "Development",
            Education: "Education",
            Game: "Games",
            Graphics: "Graphics",
            Network: "Internet",
            Office: "Office",
            Science: "Science",
            Settings: "Settings",
            System: "System",
            Utility: "Utilities"
        })

    Process {
        id: dbProcess

        stdout: StdioCollector {
            id: dbStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: dbStderr

            waitForEnd: true
        }

        onExited: exitCode => rootKipAppService.finishSql(exitCode, dbStdout.text, dbStderr.text)
    }

    Process {
        id: launchProcess
    }

    Component.onCompleted: refreshUsage()

    // Every statement ends with the usage query, so one round trip both
    // writes and refreshes what the launcher shows.
    function refreshUsage() {
        runSql("");
    }

    function runSql(statement) {
        const sql = "CREATE TABLE IF NOT EXISTS launches (app_id TEXT NOT NULL, launched_at INTEGER NOT NULL);" + "CREATE INDEX IF NOT EXISTS launches_app ON launches (app_id);" + statement + "SELECT app_id, COUNT(*) AS count, MAX(launched_at) AS last, GROUP_CONCAT(CAST(strftime('%H', launched_at / 1000, 'unixepoch', 'localtime') AS INTEGER)) AS hours FROM launches GROUP BY app_id;";

        if (dbProcess.running) {
            pendingSql = pendingSql.concat([sql]);
            return;
        }

        startSql(sql);
    }

    // Path and SQL arrive as $1 and $2; nothing is pasted into the script.
    function startSql(sql) {
        dbProcess.command = ["sh", "-c", "mkdir -p -- \"$(dirname -- \"$1\")\" && exec sqlite3 -json \"$1\" \"$2\"", "kip-apps", dbPath, sql];
        dbProcess.running = true;
    }

    function finishSql(exitCode, stdoutText, stderrText) {
        if (exitCode !== 0) {
            errorText = String(stderrText || "").trim() || "sqlite3 exited " + exitCode;
        } else {
            errorText = "";
            try {
                const rows = String(stdoutText || "").trim().length > 0 ? JSON.parse(stdoutText) : [];
                const next = {};

                for (const row of rows) {
                    const hours = [];

                    for (let hour = 0; hour < 24; hour++)
                        hours.push(0);
                    for (const hour of String(row.hours || "").split(","))
                        if (hour.length > 0)
                            hours[Number(hour) % 24]++;
                    next[row.app_id] = {
                        count: Number(row.count) || 0,
                        last: Number(row.last) || 0,
                        hours: hours
                    };
                }
                usage = next;
            } catch (error) {
                errorText = "could not read the launch log: " + error;
            }
        }

        if (pendingSql.length > 0) {
            const next = pendingSql[0];

            pendingSql = pendingSql.slice(1);
            startSql(next);
        }
    }

    function launch(entry) {
        if (!entry)
            return;

        if (entry.runInTerminal) {
            launchProcess.command = [kt.appTerminal, "-e"].concat(entry.command);
            launchProcess.startDetached();
        } else {
            entry.execute();
        }

        runSql("INSERT INTO launches (app_id, launched_at) VALUES ('" + String(entry.id).replace(/'/g, "''") + "', " + Date.now() + ");");
    }

    function cycleGrouping() {
        const order = ["category", "name", "letter"];

        grouping = order[(order.indexOf(grouping) + 1) % order.length];
    }

    function toggleView() {
        view = view === "grid" ? "list" : "grid";
    }

    function categoryOf(entry) {
        const categories = entry.categories || [];

        for (const category of categories) {
            if (categoryNames[category])
                return categoryNames[category];
        }
        return "Other";
    }

    // [{ title, apps }]. A query means one ranked section; grouping is for
    // browsing, not for hunting.
    function sections(query, groupingMode) {
        const text = String(query || "").trim().toLowerCase();

        if (text.length > 0) {
            const found = search(text);

            return found.length > 0 ? [
                {
                    title: found.length + (found.length === 1 ? " match" : " matches"),
                    apps: found
                }
            ] : [];
        }

        return usageSections().concat(groupingMode === "category" ? byCategory() : groupingMode === "letter" ? byLetter() : [
            {
                title: "All applications",
                apps: apps
            }
        ]);
    }

    function usageSections() {
        const used = apps.filter(entry => usage[entry.id] !== undefined);
        const result = [];
        const mostUsed = used.slice().sort((left, right) => usage[right.id].count - usage[left.id].count || usage[right.id].last - usage[left.id].last).slice(0, kt.appMostUsedCount);
        const recent = used.slice().sort((left, right) => usage[right.id].last - usage[left.id].last).slice(0, kt.appRecentCount);

        if (mostUsed.length > 0)
            result.push({
                title: "Most used",
                apps: mostUsed
            });
        if (recent.length > 0)
            result.push({
                title: "Recent",
                apps: recent
            });
        return result;
    }

    function byCategory() {
        const groups = {};

        for (const entry of apps) {
            const name = categoryOf(entry);

            (groups[name] = groups[name] || []).push(entry);
        }

        return Object.keys(groups).sort((left, right) => left === "Other" ? 1 : right === "Other" ? -1 : left.localeCompare(right)).map(name => ({
                    title: name,
                    apps: groups[name]
                }));
    }

    function byLetter() {
        const groups = {};

        for (const entry of apps) {
            const first = entry.name.charAt(0).toUpperCase();
            const letter = /[A-Z]/.test(first) ? first : "#";

            (groups[letter] = groups[letter] || []).push(entry);
        }

        return Object.keys(groups).sort((left, right) => left === "#" ? 1 : right === "#" ? -1 : left.localeCompare(right)).map(letter => ({
                    title: letter,
                    apps: groups[letter]
                }));
    }

    // Every word must match somewhere. Name hits beat the rest; ties go to
    // whatever you launch more.
    function search(text) {
        const words = text.split(/\s+/).filter(word => word.length > 0);
        const scored = [];

        for (const entry of apps) {
            const name = entry.name.toLowerCase();
            const extra = [entry.genericName, entry.comment, entry.id].concat(entry.keywords || []).join(" ").toLowerCase();
            let score = 0;
            let matched = true;

            for (const word of words) {
                if (name.startsWith(word))
                    score += 0;
                else if (name.indexOf(" " + word) >= 0 || name.indexOf("-" + word) >= 0)
                    score += 1;
                else if (name.indexOf(word) >= 0)
                    score += 2;
                else if (extra.indexOf(word) >= 0)
                    score += 4;
                else {
                    matched = false;
                    break;
                }
            }

            if (matched)
                scored.push({
                    entry: entry,
                    score: score
                });
        }

        return scored.sort((left, right) => left.score - right.score || countOf(right.entry) - countOf(left.entry) || left.entry.name.localeCompare(right.entry.name)).map(item => item.entry);
    }

    // Something KIP can say about your habits, or null when there is too
    // little history to be smug about. { kind: most | hour | recent, entry, values }
    function nudge() {
        const used = apps.filter(entry => usage[entry.id] !== undefined && usage[entry.id].count >= kt.appNudgeMinLaunches);
        const options = [];

        if (used.length === 0)
            return null;

        const now = new Date();
        const hour = now.getHours();
        const top = used.slice().sort((left, right) => usage[right.id].count - usage[left.id].count)[0];

        options.push({
            kind: "most",
            entry: top,
            values: {
                app: top.name,
                count: usage[top.id].count
            }
        });

        // This hour and its neighbours, so 08:59 and 09:01 count as one habit.
        const around = entry => {
            const hours = usage[entry.id].hours;

            return hours[(hour + 23) % 24] + hours[hour] + hours[(hour + 1) % 24];
        };
        const habit = used.slice().sort((left, right) => around(right) - around(left))[0];

        if (around(habit) >= kt.appNudgeMinLaunches)
            options.push({
                kind: "hour",
                entry: habit,
                values: {
                    app: habit.name,
                    count: around(habit),
                    hour: (hour < 10 ? "0" : "") + hour + ":00"
                }
            });

        const latest = used.slice().sort((left, right) => usage[right.id].last - usage[left.id].last)[0];

        if (now.getTime() - usage[latest.id].last < kt.appNudgeRecentWindow)
            options.push({
                kind: "recent",
                entry: latest,
                values: {
                    app: latest.name,
                    ago: ago(usage[latest.id].last)
                }
            });

        return options[Math.floor(Math.random() * options.length)];
    }

    function ago(time) {
        const minutes = Math.max(1, Math.round((Date.now() - time) / 60000));

        if (minutes < 60)
            return minutes + (minutes === 1 ? " minute ago" : " minutes ago");
        const hours = Math.round(minutes / 60);

        return hours + (hours === 1 ? " hour ago" : " hours ago");
    }

    function countOf(entry) {
        return usage[entry.id] ? usage[entry.id].count : 0;
    }

    function iconSource(entry) {
        const icon = String(entry && entry.icon || "");

        if (icon.startsWith("/"))
            return "file://" + icon;
        return Quickshell.iconPath(icon, "application-x-executable");
    }
}
