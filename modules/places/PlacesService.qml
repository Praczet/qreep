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
    // First paragraph of README.md, else of AGENTS.md. A config
    // `description` wins over both (see description()).
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

    Process {
        id: folderProcess

        stdout: StdioCollector {
            id: folderStdout

            waitForEnd: true
        }

        onExited: rootPlacesService.applyFolders(folderStdout.text)
    }

    Process {
        id: todoProcess

        stdout: StdioCollector {
            id: todoStdout

            waitForEnd: true
        }

        onExited: rootPlacesService.applyTodos(todoStdout.text)
    }

    // Calendar sources, the same three files the bar clock watches.
    Repeater {
        model: rootPlacesService.wantsCalendar ? [
            { key: "local", path: Quickshell.shellDir + "/events.json" },
            { key: "google", path: rootPlacesService.home + "/.cache/qreep/calendar/events.json" },
            { key: "microsoft", path: rootPlacesService.home + "/.cache/qreep/calendar/microsoft-events.json" }
        ] : []

        Item {
            id: calendarSource

            required property var modelData

            FileView {
                path: calendarSource.modelData.path
                preload: true
                watchChanges: true

                onFileChanged: reload()
                onLoaded: rootPlacesService.applyCalendarFile(calendarSource.modelData.key, text())
                onLoadFailed: rootPlacesService.applyCalendarFile(calendarSource.modelData.key, "[]")
            }
        }
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
        refreshTodos();
        refreshFolders();
        checkSsh();
        detailFor = "";
        if (selected)
            detailDelay.restart();
    }

    // Blocks: { type, title?, enabled?, items }. Items become
    // { kind: "file" | "folder" | "app", path | id, label }. Paths may be
    // absolute, ~/..., or relative to the entry's folder.
    function parseBlocks(blocks, basePath) {
        if (!Array.isArray(blocks))
            return [];

        return blocks.filter(block => block && isEnabled(block)).map((block, index) => {
            const type = String(block.type || "");
            const raw = Array.isArray(block.items) ? block.items : [];
            let items = [];

            if (type === "documents" || type === "folders")
                items = raw.map(item => blockPathItem(item, type === "documents" ? "file" : "folder", basePath)).filter(item => item.path.length > 0);
            else if (type === "ssh")
                items = raw.map(item => sshItem(typeof item === "string" ? {
                        host: item
                    } : (item || {}))).filter(item => item.host.length > 0);
            else if (type === "smb")
                items = raw.concat(Array.isArray(block.shares) ? block.shares : []).map(item => smbShare(item)).filter(item => item.host.length > 0);
            else if (type === "apps")
                items = raw.map(item => ({
                            kind: "app",
                            id: String(item).replace(/\.desktop$/, ""),
                            label: String(item).replace(/\.desktop$/, "")
                        }));

            // folder: one directory, listed live (see folderListings).
            const folderPath = type === "folder" ? blockPathItem(String(block.path || ""), "folder", basePath).path : "";

            return {
                id: "block:" + index,
                type: type,
                title: String(block.title || (type === "folder" && folderPath ? folderPath.replace(/^.*\//, "") : defaultBlockTitle(type))),
                path: folderPath,
                sort: block.sort === "modified" ? "modified" : "name",
                hidden: block.hidden === true,
                // ssh: no items = every host in ~/.ssh/config, minus "exclude"
                // and git forges (isGitForge: they give no shell).
                fromSshConfig: type === "ssh" && raw.length === 0,
                exclude: Array.isArray(block.exclude) ? block.exclude.map(String) : [],
                items: items,
                // "wide": true spans both columns; every block is one cell otherwise.
                wide: block.wide === true,
                // Live blocks with nothing to show can step aside; usb does by default.
                hideWhenEmpty: block.hideWhenEmpty === undefined ? type === "usb" : block.hideWhenEmpty === true,
                // calendar: days ahead; todos: states to show. Both: limit.
                days: Math.max(1, Number(block.days) || 2),
                limit: Math.max(1, Number(block.limit) || 10),
                states: Array.isArray(block.states) ? block.states.map(state => String(state).toUpperCase()) : ["NOW", "DOING", "TODO", "LATER"]
            };
        });
    }

    // Live types compute their items from current data, so a block's list
    // follows the calendar cache and the Logseq graph while Places is open.
    function blockItems(block) {
        if (!block)
            return [];
        if (block.type === "calendar")
            return upcomingEvents(block.days, block.limit);
        if (block.type === "todos")
            return todos.filter(todo => block.states.indexOf(todo.state) >= 0).slice(0, block.limit);
        if (block.type === "folder")
            return folderItems(block);
        if (block.type === "usb")
            return usbDrives;
        if (block.type === "smb")
            return block.items.map(share => Object.assign({}, share, {
                        mounted: smbIsMounted(share),
                        detail: (share.user ? share.user + " · " : "") + (smbIsMounted(share) ? "mounted" : "not mounted")
                    }));
        if (block.type === "ssh" && block.fromSshConfig)
            return sshConfigHosts.filter(host => block.exclude.indexOf(host.host) < 0 && !isGitForge(host)).slice(0, block.limit);
        return block.items;
    }

    // --- smarter Open with: file type, default app, remembered choice -------

    // extension (or mime type for files without one) -> chooser option id,
    // the last thing you picked for that kind of file.
    readonly property string openersPath: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/qreep/places-openers.json"
    property var openers: ({})

    // The chooser asked what a file is; answered once xdg-mime has spoken.
    // apps: [{ id, name, desktopFile, isDefault }], every visible desktop
    // entry whose MimeType lists this type, the default first.
    signal fileTypeKnown(string path, string mime, string appName, var apps)

    FileView {
        id: openersFile

        path: rootPlacesService.openersPath
        printErrors: false

        onLoaded: {
            try {
                rootPlacesService.openers = JSON.parse(text() || "{}");
            } catch (error) {
                rootPlacesService.openers = {};
            }
        }
    }

    function openerKey(path, mime) {
        const name = String(path).replace(/^.*\//, "");
        const dot = name.lastIndexOf(".");
        return dot > 0 ? name.slice(dot + 1).toLowerCase() : String(mime || "");
    }

    function rememberOpener(path, optionId, mime) {
        const key = openerKey(path, mime);

        if (key.length === 0 || optionId === "copy-path" || openers[key] === optionId)
            return;

        const next = Object.assign({}, openers);
        next[key] = optionId;
        openers = next;
        openersFile.setText(JSON.stringify(next, null, 2) + "\n");
    }

    // Text by nature even when the mime type does not start with text/.
    function isTextMime(mime) {
        return /^text\//.test(mime) || /(json|xml|javascript|ecmascript|x-shellscript|x-sh|yaml|toml|x-php|x-python|x-perl|x-ruby|sql|x-desktop|x-subrip|x-empty)$/.test(mime);
    }

    function inspectFile(path) {
        fileTypeProcess.running = false;
        fileTypeProcess.path = path;
        // Line 1 mime, line 2 default desktop id, then every .desktop file
        // that lists the type and is not NoDisplay=true.
        fileTypeProcess.command = ["sh", "-c", "m=$(xdg-mime query filetype \"$1\" 2>/dev/null); printf '%s\\n%s\\n' \"$m\" \"$(xdg-mime query default \"$m\" 2>/dev/null)\"; "
            + "[ -n \"$m\" ] || exit 0; e=$(printf '%s' \"$m\" | sed 's/[.+]/\\\\&/g'); "
            + "for d in \"${XDG_DATA_HOME:-$HOME/.local/share}/applications\" /usr/local/share/applications /usr/share/applications /var/lib/flatpak/exports/share/applications \"$HOME/.local/share/flatpak/exports/share/applications\"; do "
            + "[ -d \"$d\" ] && grep -lE \"^MimeType=(.*;)?$e(;|$)\" \"$d\"/*.desktop 2>/dev/null | while read -r f; do grep -q '^NoDisplay=true' \"$f\" || printf '%s\\n' \"$f\"; done; done", "places", path];
        fileTypeProcess.running = true;
    }

    Process {
        id: fileTypeProcess

        property string path: ""

        stdout: StdioCollector {
            id: fileTypeStdout

            waitForEnd: true
        }

        onExited: {
            const lines = fileTypeStdout.text.split("\n");
            const mime = (lines[0] || "").trim();
            const desktopId = (lines[1] || "").trim().replace(/\.desktop$/, "");
            const entry = desktopId ? DesktopEntries.byId(desktopId) : null;
            const seen = {};
            const apps = [];

            // The first file per id wins: user dirs come before system ones.
            for (const file of lines.slice(2).map(line => line.trim()).filter(line => line.length > 0)) {
                const id = file.replace(/^.*\//, "").replace(/\.desktop$/, "");
                const app = DesktopEntries.byId(id);

                if (seen[id])
                    continue;
                seen[id] = true;
                apps.push({
                    id: id,
                    name: app ? app.name : id,
                    desktopFile: file,
                    isDefault: id === desktopId
                });
            }
            apps.sort((left, right) => (right.isDefault ? 1 : 0) - (left.isDefault ? 1 : 0) || left.name.localeCompare(right.name));

            rootPlacesService.fileTypeKnown(fileTypeProcess.path, mime, entry ? entry.name : desktopId, apps);
        }
    }

    // --- usb: removable partitions via lsblk, actions via udisksctl ----------

    // Places.qml binds this to its open state: USB is polled only while visible.
    property bool panelActive: false
    readonly property bool wantsUsb: projects.some(project => project.blocks.some(block => block.type === "usb"))
    property var usbDrives: []

    Timer {
        interval: 3000
        repeat: true
        running: rootPlacesService.panelActive && rootPlacesService.wantsUsb
        triggeredOnStart: true
        onTriggered: rootPlacesService.refreshUsb()
    }

    Process {
        id: usbProcess

        command: ["lsblk", "-J", "-o", "NAME,PATH,RM,HOTPLUG,TRAN,TYPE,LABEL,MODEL,SIZE,FSTYPE,MOUNTPOINT"]
        stdout: StdioCollector {
            id: usbStdout

            waitForEnd: true
        }

        onExited: rootPlacesService.usbDrives = rootPlacesService.parseUsb(usbStdout.text)
    }

    function refreshUsb() {
        if (!usbProcess.running)
            usbProcess.running = true;
    }

    // Partitions with a filesystem on USB / removable / hotplug disks; a
    // disk formatted without partitions counts as its own partition.
    function parseUsb(text) {
        let devices = [];

        try {
            devices = JSON.parse(text).blockdevices || [];
        } catch (error) {
            return [];
        }

        const drives = [];

        for (const disk of devices) {
            if (disk.type !== "disk" || !(disk.tran === "usb" || disk.rm || disk.hotplug))
                continue;

            const parts = (disk.children || []).concat(disk.fstype ? [disk] : []).filter(part => part.fstype);

            for (const part of parts)
                drives.push({
                    kind: "usb",
                    device: part.path,
                    disk: disk.path,
                    label: String(part.label || disk.model || part.name).trim(),
                    size: String(part.size || ""),
                    mountpoint: String(part.mountpoint || ""),
                    detail: part.size + (part.mountpoint ? " · " + shortPath(part.mountpoint) : " · not mounted")
                });
        }
        return drives;
    }

    // open: mount if needed, then yazi there. terminal: kitty in it.
    // mount / unmount / eject (unmount + power off the whole disk).
    function usbAction(drive, action) {
        if (action === "terminal" && drive.mountpoint) {
            run(theme.terminalCommand([], { cwd: drive.mountpoint }), drive.mountpoint);
            return;
        }
        if (action === "open" && drive.mountpoint) {
            run(theme.terminalCommand(["yazi", drive.mountpoint]), drive.mountpoint);
            return;
        }

        const scripts = {
            // udisksctl prints "Mounted /dev/sdb1 at /run/media/adam/STICK"; keep the path.
            open: "out=$(udisksctl mount -b \"$1\" 2>&1) || { notify-send 'USB' \"$out\"; exit 1; }; printf '%s' \"$out\" | sed -n 's/^Mounted .* at \\(.*\\)$/\\1/p' | sed 's/\\.$//'",
            mount: "out=$(udisksctl mount -b \"$1\" 2>&1) || notify-send 'USB' \"$out\"",
            unmount: "out=$(udisksctl unmount -b \"$1\" 2>&1) || notify-send 'USB' \"$out\"",
            eject: "out=$(udisksctl unmount -b \"$1\" 2>&1 && udisksctl power-off -b \"$2\" 2>&1) && notify-send 'USB' 'Safe to remove.' || notify-send 'USB' \"$out\""
        };

        if (!scripts[action] || usbActionProcess.running)
            return;

        usbActionProcess.openAfter = action === "open";
        usbActionProcess.command = ["sh", "-c", scripts[action], "places", drive.device, drive.disk];
        usbActionProcess.running = true;
    }

    Process {
        id: usbActionProcess

        property bool openAfter: false

        stdout: StdioCollector {
            id: usbActionStdout

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            const path = usbActionStdout.text.trim();

            if (usbActionProcess.openAfter && exitCode === 0 && path.length > 0)
                rootPlacesService.run(rootPlacesService.theme.terminalCommand(["yazi", path]), path);
            rootPlacesService.refreshUsb();
        }
    }

    // --- smb: GVFS shares, password in GNOME Keyring (never in config/argv) --

    readonly property bool wantsSmb: projects.some(project => project.blocks.some(block => block.type === "smb"))
    // [{ host, share }] from `gio mount -l`, polled while Places is open.
    property var smbMounts: []

    // A share needs a password the keyring does not have: the panel asks.
    signal smbPasswordNeeded(var share, string message)

    // { name, url, user, domain } -> share item. url: smb://[user@]host/share
    function smbShare(spec) {
        const config = typeof spec === "string" ? {
            url: spec
        } : (spec || {});
        const match = /^smb:\/\/(?:([^@\/]+)@)?([^\/]+)\/([^\/]+)/i.exec(String(config.url || ""));
        const user = String(config.user || (match && match[1] ? decodeURIComponent(match[1]) : ""));
        const host = match ? match[2] : "";
        const share = match ? match[3] : "";

        return {
            kind: "smb",
            label: String(config.name || share + " on " + host),
            host: host,
            share: share,
            user: user,
            domain: String(config.domain || ""),
            // gio wants the user in the URL so it only asks domain + password.
            url: host ? "smb://" + (user ? encodeURIComponent(user) + "@" : "") + host + "/" + share + "/" : "",
            // Keyring key: one entry per share, independent of the user.
            key: "smb://" + host + "/" + share + "/"
        };
    }

    function smbIsMounted(share) {
        return smbMounts.some(mount => mount.host.toLowerCase() === share.host.toLowerCase() && mount.share.toLowerCase() === share.share.toLowerCase());
    }

    Timer {
        interval: 3000
        repeat: true
        running: rootPlacesService.panelActive && rootPlacesService.wantsSmb
        triggeredOnStart: true
        onTriggered: {
            if (!smbListProcess.running)
                smbListProcess.running = true;
        }
    }

    Process {
        id: smbListProcess

        command: ["gio", "mount", "-l"]
        stdout: StdioCollector {
            id: smbListStdout

            waitForEnd: true
        }

        onExited: {
            const mounts = [];

            for (const line of smbListStdout.text.split("\n")) {
                const match = / -> smb:\/\/(?:[^@\/]+@)?([^\/]+)\/([^\/]+)/i.exec(line);
                if (match)
                    mounts.push({
                        host: match[1],
                        share: decodeURIComponent(match[2])
                    });
            }
            rootPlacesService.smbMounts = mounts;
        }
    }

    // open: mount if needed, then yazi on the GVFS path. terminal: kitty there.
    // mount, unmount, forget (delete the saved password).
    function smbAction(share, action) {
        if (smbProcess.running)
            return;

        if (action === "forget") {
            run(["secret-tool", "clear", "service", "qreep-places-smb", "url", share.key], home);
            return;
        }
        if (action === "unmount") {
            run(["gio", "mount", "-u", share.url], home);
            return;
        }

        // $1 url, $2 domain, $3 key. Saved password -> piped to gio (domain,
        // password). None -> gio with no input: GVFS may still have its own
        // saved login; if it asks, exit 3 and the panel asks instead.
        // Prints the local GVFS path on success.
        const script = "out=''; "
            + "if ! gio info \"$1\" >/dev/null 2>&1; then "
            + "pw=$(secret-tool lookup service qreep-places-smb url \"$3\" 2>/dev/null); "
            + "if [ -n \"$pw\" ]; then out=$(printf '%s\\n%s\\n' \"$2\" \"$pw\" | gio mount \"$1\" 2>&1); else out=$(gio mount \"$1\" </dev/null 2>&1); fi; "
            + "gio info \"$1\" >/dev/null 2>&1 || { case \"$out\" in *assword*|*uthenticat*) exit 3;; esac; printf '%s' \"$out\" >&2; exit 1; }; fi; "
            + "gio info \"$1\" | sed -n 's/^local path: //p'";

        smbProcess.share = share;
        smbProcess.action = action;
        smbProcess.stdinEnabled = false;
        smbProcess.command = ["sh", "-c", script, "places", share.url, share.domain, share.key];
        smbProcess.running = true;
    }

    // From the password dialog. The password reaches sh on stdin, never argv;
    // "remember" stores it in the keyring first (secret-tool reads stdin too).
    function smbLogin(share, domain, password, remember) {
        if (smbProcess.running)
            return;

        const script = "IFS= read -r pw; "
            + "if [ \"$4\" = 1 ]; then printf '%s' \"$pw\" | secret-tool store --label=\"Qreep Places: $3\" service qreep-places-smb url \"$3\" || exit 4; fi; "
            + "out=$(printf '%s\\n%s\\n' \"$2\" \"$pw\" | gio mount \"$1\" 2>&1); "
            + "gio info \"$1\" >/dev/null 2>&1 || { case \"$out\" in *assword*|*uthenticat*) exit 3;; esac; printf '%s' \"$out\" >&2; exit 1; }; "
            + "gio info \"$1\" | sed -n 's/^local path: //p'";

        smbProcess.share = share;
        smbProcess.action = "open";
        smbProcess.command = ["sh", "-c", script, "places", share.url, domain, share.key, remember ? "1" : "0"];
        smbProcess.pendingInput = password + "\n";
        smbProcess.stdinEnabled = true;
        smbProcess.running = true;
    }

    Process {
        id: smbProcess

        property var share: null
        property string action: ""
        // The password, held only until the process is up to read it.
        property string pendingInput: ""

        onStarted: {
            if (pendingInput.length === 0)
                return;
            write(pendingInput);
            pendingInput = "";
            stdinEnabled = false;
        }

        stdout: StdioCollector {
            id: smbStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: smbStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            const path = smbStdout.text.trim();

            if (exitCode === 3) {
                rootPlacesService.smbPasswordNeeded(smbProcess.share, "Password needed (or the saved one was refused).");
            } else if (exitCode === 4) {
                rootPlacesService.run(["notify-send", "SMB", "Could not save the password in the keyring."], rootPlacesService.home);
            } else if (exitCode !== 0) {
                rootPlacesService.run(["notify-send", "SMB", smbStderr.text.trim() || "Mount failed."], rootPlacesService.home);
            } else if (path.length > 0 && smbProcess.action === "open") {
                rootPlacesService.run(rootPlacesService.theme.terminalCommand(["yazi", path]), path);
            } else if (path.length > 0 && smbProcess.action === "terminal") {
                rootPlacesService.run(rootPlacesService.theme.terminalCommand([], { cwd: path }), path);
            }
            if (!smbListProcess.running)
                smbListProcess.running = true;
        }
    }

    // --- ssh: ~/.ssh/config hosts, or hand-listed ones -----------------------

    readonly property bool wantsSshConfig: projects.some(project => project.blocks.some(block => block.type === "ssh" && block.fromSshConfig))
    property var sshConfigHosts: []

    FileView {
        path: rootPlacesService.wantsSshConfig ? rootPlacesService.home + "/.ssh/config" : ""
        preload: path.length > 0
        watchChanges: true

        onFileChanged: reload()
        onLoaded: rootPlacesService.sshConfigHosts = rootPlacesService.parseSshConfig(text())
        onLoadFailed: rootPlacesService.sshConfigHosts = []
    }

    // "Host a b" starts a block; HostName / User / Port apply to it.
    // Wildcard patterns (*, ?, !) are not hosts you can connect to.
    function parseSshConfig(text) {
        const hosts = [];
        let current = [];

        for (const raw of String(text || "").split("\n")) {
            const line = raw.replace(/#.*$/, "").trim();
            const match = /^(\S+)\s+(.+)$/.exec(line);

            if (!match)
                continue;

            const key = match[1].toLowerCase();
            const value = match[2].trim();

            if (key === "host") {
                current = value.split(/\s+/).filter(name => !/[*?!]/.test(name)).map(name => ({
                            host: name,
                            hostName: "",
                            user: "",
                            port: ""
                        }));
                hosts.push(...current);
            } else if (key === "match") {
                current = [];
            } else if (key === "hostname" || key === "user" || key === "port") {
                for (const host of current)
                    host[key === "hostname" ? "hostName" : key] = value;
            }
        }

        return hosts.map(host => sshItem(host));
    }

    // Git hosting: ssh there gives no shell, only "you've authenticated".
    function isGitForge(host) {
        return host.user === "git" || /^(github\.com|gitlab\.com|bitbucket\.org|codeberg\.org)$/i.test(host.host);
    }

    function sshItem(spec) {
        const host = String(spec.host || "");
        const user = String(spec.user || "");
        const hostName = String(spec.hostName || spec.hostname || "");
        const port = String(spec.port || "");
        const target = (user ? user + "@" : "") + (hostName && hostName !== host ? hostName : "") + (port && port !== "22" ? ":" + port : "");

        return {
            kind: "ssh",
            host: host,
            user: user,
            label: String(spec.name || host),
            detail: target.length > 0 && target !== user + "@" ? target : user
        };
    }

    // host -> "up" | "down"; missing = not checked yet. One TCP connect to
    // the ssh port per host (address and port from `ssh -G`), all in
    // parallel, 1.5 s each. No login, so no prompts and no host-key questions.
    property var sshReachable: ({})

    // ~/.ssh/config can arrive after Places opened; check once it has.
    onSshConfigHostsChanged: {
        if (panelActive)
            checkSsh();
    }

    function checkSsh() {
        const hosts = [];

        for (const project of projects) {
            for (const block of project.blocks) {
                if (block.type === "ssh")
                    hosts.push(...blockItems(block).map(item => item.host));
            }
        }

        const unique = hosts.filter((host, index) => hosts.indexOf(host) === index);

        if (unique.length === 0 || sshCheckProcess.running)
            return;

        sshCheckProcess.command = ["bash", "-c", "for h in \"$@\"; do ( a=$(ssh -G \"$h\" 2>/dev/null | awk '/^hostname /{print $2}'); p=$(ssh -G \"$h\" 2>/dev/null | awk '/^port /{print $2}'); if timeout 1.5 bash -c \"exec 3<>/dev/tcp/${a:-$h}/${p:-22}\" 2>/dev/null; then echo \"$h up\"; else echo \"$h down\"; fi ) & done; wait", "places"].concat(unique);
        sshCheckProcess.running = true;
    }

    Process {
        id: sshCheckProcess

        stdout: StdioCollector {
            id: sshCheckStdout

            waitForEnd: true
        }

        onExited: {
            const next = {};

            for (const line of sshCheckStdout.text.split("\n")) {
                const parts = line.trim().split(" ");
                if (parts.length === 2)
                    next[parts[0]] = parts[1];
            }
            rootPlacesService.sshReachable = next;
        }
    }

    // kitty ssh <host>: ssh reads the rest from ~/.ssh/config.
    function openSsh(item) {
        run(theme.terminalCommand(["ssh", item.host]), home);
    }

    // --- folder: a directory's contents, one find per refresh ----------------

    // path -> [{ type: "d" | "f" | ..., time, name }]
    property var folderListings: ({})
    readonly property var folderPaths: projects.reduce((paths, project) => paths.concat(project.blocks.filter(block => block.type === "folder" && block.path).map(block => block.path)), []).filter((path, index, all) => all.indexOf(path) === index)

    onFolderPathsChanged: refreshFolders()

    function refreshFolders() {
        if (folderPaths.length === 0 || folderProcess.running)
            return;

        // GNU find: type, mtime, name per entry, one level deep. Symlinks to
        // folders count as folders (%Y follows them).
        folderProcess.command = ["sh", "-c", "for p in \"$@\"; do printf '@@DIR %s\\n' \"$p\"; find \"$p\" -mindepth 1 -maxdepth 1 -printf '%Y\\t%T@\\t%f\\n' 2>/dev/null; done", "places"].concat(folderPaths);
        folderProcess.running = true;
    }

    function applyFolders(text) {
        const next = {};
        let current = null;

        for (const line of String(text || "").split("\n")) {
            if (line.indexOf("@@DIR ") === 0) {
                current = line.slice(6);
                next[current] = [];
                continue;
            }

            const parts = line.split("\t");
            if (!current || parts.length < 3)
                continue;

            next[current].push({
                type: parts[0],
                time: Number(parts[1]) || 0,
                name: parts.slice(2).join("\t")
            });
        }

        folderListings = next;
    }

    // Entries the listing has beyond "limit", for the "+ N more" line.
    function folderTotal(block) {
        return (folderListings[block.path] || []).filter(entry => block.hidden || entry.name.indexOf(".") !== 0).length;
    }

    // Folders first, then files; by name or newest first. Dot-entries only
    // with "hidden": true.
    function folderItems(block) {
        const entries = (folderListings[block.path] || []).filter(entry => block.hidden || entry.name.indexOf(".") !== 0);

        entries.sort((left, right) => {
            const leftDir = left.type === "d" ? 0 : 1;
            const rightDir = right.type === "d" ? 0 : 1;

            if (leftDir !== rightDir)
                return leftDir - rightDir;
            return block.sort === "modified" ? right.time - left.time : left.name.localeCompare(right.name);
        });

        return entries.slice(0, block.limit).map(entry => ({
                    kind: entry.type === "d" ? "folder" : "file",
                    path: block.path + "/" + entry.name,
                    label: entry.name,
                    time: entry.time
                }));
    }

    readonly property bool wantsCalendar: projects.some(project => project.blocks.some(block => block.type === "calendar"))
    readonly property bool wantsTodos: projects.some(project => project.blocks.some(block => block.type === "todos"))

    // --- calendar: the files the bar clock reads (EventStore) ---------------

    property var calendarFiles: ({})
    readonly property var calendarEvents: Object.keys(calendarFiles).reduce((all, key) => all.concat(calendarFiles[key]), [])

    function applyCalendarFile(key, text) {
        let events = [];

        try {
            const parsed = JSON.parse(text);
            events = Array.isArray(parsed) ? parsed : (Array.isArray(parsed.events) ? parsed.events : []);
        } catch (error) {
            events = [];
        }

        const next = Object.assign({}, calendarFiles);
        next[key] = events;
        calendarFiles = next;
    }

    function eventStart(event) {
        const raw = event.start && (event.start.dateTime || event.start.date) || event.date || "";
        // A bare date is local midnight, not UTC midnight.
        return /^\d{4}-\d{2}-\d{2}$/.test(raw) ? new Date(raw + "T00:00:00") : new Date(raw);
    }

    function eventEnd(event, start, allDay) {
        const raw = event.end && (event.end.dateTime || event.end.date) || "";
        const end = /^\d{4}-\d{2}-\d{2}$/.test(raw) ? new Date(raw + "T00:00:00") : new Date(raw);

        if (!isNaN(end.getTime()))
            return end;
        return new Date(start.getTime() + (allDay ? 24 : 1) * 3600 * 1000);
    }

    // Events from now (still running counts) to the end of `days` days.
    function upcomingEvents(days, limit) {
        const now = new Date();
        const horizon = new Date(now);
        horizon.setHours(0, 0, 0, 0);
        horizon.setDate(horizon.getDate() + days);
        const seen = {};
        const items = [];

        for (const event of calendarEvents) {
            if (!event || event.status === "cancelled" || /^canceled:/i.test(String(event.title || "")))
                continue;

            const start = eventStart(event);
            if (isNaN(start.getTime()))
                continue;

            const allDay = event.allDay === true;
            const end = eventEnd(event, start, allDay);
            const key = (event.id || event.title) + start.getTime();

            if (end <= now || start >= horizon || seen[key])
                continue;
            seen[key] = true;

            items.push({
                kind: "event",
                title: String(event.title || "(no title)"),
                start: start,
                allDay: allDay,
                time: allDay ? "all day" : Qt.formatTime(start, "HH:mm"),
                day: dayLabel(start),
                location: String(event.location || ""),
                calendar: String(event.calendar || ""),
                url: String(event.url || event.htmlLink || "")
            });
        }

        items.sort((left, right) => left.start - right.start || (right.allDay ? 1 : 0) - (left.allDay ? 1 : 0));
        return items.slice(0, limit);
    }

    function dayLabel(date) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const day = new Date(date);
        day.setHours(0, 0, 0, 0);
        const offset = Math.round((day - today) / (24 * 3600 * 1000));

        if (offset <= 0)
            return "Today";
        if (offset === 1)
            return "Tomorrow";
        return Qt.formatDate(day, "ddd d MMM");
    }

    // --- todos: Logseq TODO / LATER / NOW / DOING lines ----------------------

    property var todos: []

    // The first config load can land after refresh() ran; catch up then.
    onWantsTodosChanged: refreshTodos()

    function refreshTodos() {
        if (!wantsTodos || todoProcess.running)
            return;

        todoProcess.command = ["rg", "--no-heading", "--line-number", "--with-filename", "--glob", "*.md", "-e", "^\\s*- (NOW|DOING|TODO|LATER|WAITING) ", theme.modules.kip.logseqGraphDir + "/journals", theme.modules.kip.logseqGraphDir + "/pages"];
        todoProcess.running = true;
    }

    function applyTodos(text) {
        const order = {
            NOW: 0,
            DOING: 0,
            TODO: 1,
            WAITING: 2,
            LATER: 3
        };
        const next = [];

        for (const line of String(text || "").split("\n")) {
            const match = /^(.*?):(\d+):\s*- (NOW|DOING|TODO|LATER|WAITING) (.*)$/.exec(line);
            if (!match)
                continue;

            const absolutePath = match[1];
            const file = absolutePath.replace(/^.*\//, "");
            const journal = /^(\d{4})_(\d{2})_(\d{2})\.md$/.exec(file);

            next.push({
                kind: "todo",
                state: match[3],
                // Drop Logseq noise: priorities, SCHEDULED/DEADLINE stamps.
                text: match[4].replace(/\[#[ABC]\]\s*/g, "").replace(/(SCHEDULED|DEADLINE): <[^>]*>/g, "").trim(),
                absolutePath: absolutePath,
                path: absolutePath,
                file: file,
                line: Number(match[2]),
                page: journal ? Qt.formatDate(new Date(Number(journal[1]), Number(journal[2]) - 1, Number(journal[3])), "d MMM yyyy") : file.replace(/\.md$/, "").replace(/___/g, "/"),
                sortKey: journal ? journal[1] + journal[2] + journal[3] : "0"
            });
        }

        // NOW/DOING first, then TODO, then later states; newest journal first.
        next.sort((left, right) => order[left.state] - order[right.state] || right.sortKey.localeCompare(left.sortKey) || left.line - right.line);
        todos = next;
    }

    function blockPathItem(item, kind, basePath) {
        const spec = typeof item === "string" ? {
            path: item
        } : (item || {});
        const raw = String(spec.path || "");
        const path = raw.indexOf("/") === 0 || raw.indexOf("~") === 0 ? expand(raw) : (basePath ? basePath + "/" + raw : expand(raw));

        return {
            kind: kind,
            path: path.replace(/\/+$/, ""),
            // Documents default to the file name; folders to the ~ path.
            label: String(spec.name || (kind === "file" ? path.replace(/^.*\//, "") : shortPath(path)))
        };
    }

    function defaultBlockTitle(type) {
        return ({
                documents: "Documents",
                folders: "Folders",
                folder: "Folder",
                apps: "Apps",
                calendar: "Calendar",
                todos: "Todos",
                ssh: "SSH",
                usb: "USB drives",
                smb: "Network shares"
            })[type] || type;
    }

    function shortPath(path) {
        return path.indexOf(home) === 0 ? "~" + path.slice(home.length) : path;
    }

    // Desktop entry for an apps block item: exact id first, then Quickshell's guess.
    function appEntry(id) {
        return DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id) || null;
    }

    function appIcon(id) {
        const entry = appEntry(id);
        const icon = String(entry && entry.icon || "");

        return icon.indexOf("/") === 0 ? "file://" + icon : Quickshell.iconPath(icon || id, "application-x-executable");
    }

    function launchApp(id) {
        const entry = appEntry(id);

        if (!entry)
            return false;
        if (entry.runInTerminal)
            run(theme.terminalCommand(entry.command), home);
        else
            entry.execute();
        return true;
    }

    // One line under a place's name: what is on the page right now.
    function placeSummary(place) {
        if (!place || place.kind !== "place")
            return "";

        const parts = [];

        for (const block of place.blocks) {
            const items = blockItems(block);

            if (block.type === "calendar") {
                const today = items.filter(item => item.day === "Today");
                const next = items[0];

                parts.push(today.length === 0 ? "nothing left today" : today.length + (today.length === 1 ? " event" : " events") + " left today");
                if (next)
                    parts.push("next: " + (next.day === "Today" ? "" : next.day + " ") + next.time + " " + next.title);
            } else if (block.type === "todos") {
                parts.push(items.length + (items.length === 1 ? " todo" : " todos"));
            } else if (block.type === "smb") {
                const mounted = items.filter(item => item.mounted);
                parts.push(mounted.length > 0 ? mounted.map(item => item.label).join(", ") + " mounted" : items.length + (items.length === 1 ? " share, not mounted" : " shares, none mounted"));
            } else if (block.type === "usb" && items.length > 0) {
                parts.push(items.length + (items.length === 1 ? " USB drive" : " USB drives") + " plugged in");
            } else if (block.type === "ssh") {
                const up = items.filter(item => sshReachable[item.host] === "up").length;
                parts.push(items.length + " SSH hosts" + (Object.keys(sshReachable).length > 0 ? ", " + up + " reachable" : ""));
            }
        }

        return parts.join("  ·  ");
    }

    function isEnabled(entry) {
        return entry.enabled !== false;
    }

    // Select a project by id with no filter, e.g. from KIP's /p.
    function selectProject(id) {
        query = "";
        const index = projects.findIndex(project => project.id === id);
        selectedIndex = Math.max(0, index);
    }

    // Ctrl+1..9, Ctrl+0: the 1st..10th entry in list order, places and
    // projects alike. Past ten there is no key; filter instead.
    function entryNumber(id) {
        const number = projects.findIndex(project => project.id === id) + 1;
        return number > 0 && number <= 10 ? number : 0;
    }

    // "Ctrl+3"; the 10th entry is Ctrl+0, like the number row.
    function entryKey(id) {
        const number = entryNumber(id);
        return number === 0 ? "" : "Ctrl+" + (number % 10);
    }

    function selectEntryNumber(number) {
        const project = projects[number - 1];

        if (project)
            selectProject(project.id);
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
            // "enabled": false parks an entry without deleting it; missing = on.
            if (!isEnabled(group))
                continue;

            // "projects" are git-aware folders; "places" are pages of blocks
            // and may have no folder at all. Both can carry blocks.
            const entries = (Array.isArray(group.projects) ? group.projects.map(entry => ({
                            kind: "project",
                            entry: entry
                        })) : []).concat(Array.isArray(group.places) ? group.places.map(entry => ({
                            kind: "place",
                            entry: entry
                        })) : []);

            for (const item of entries) {
                const entry = item.entry;

                if (!entry || !isEnabled(entry) || (item.kind === "project" && !entry.path))
                    continue;

                const path = entry.path ? expand(entry.path).replace(/\/+$/, "") : "";
                next.push({
                    kind: item.kind,
                    id: String(entry.id || entry.name || path),
                    name: String(entry.name || path.replace(/^.*\//, "")),
                    group: String(group.name || ""),
                    path: path,
                    displayPath: path.indexOf(home) === 0 ? "~" + path.slice(home.length) : path,
                    blocks: parseBlocks(entry.blocks, path),
                    iconName: String(entry.iconName || ""),
                    icon: String(entry.icon || ""),
                    editor: String(entry.editor || ""),
                    cockpit: Array.isArray(entry.cockpit) ? entry.cockpit.map(String) : [],
                    links: (Array.isArray(entry.links) ? entry.links : []).map(link => ({
                                name: String(link.name || link.path),
                                path: expand(link.path || "")
                            })),
                    pinned: Array.isArray(entry.pinned) ? entry.pinned.map(String) : [],
                    description: String(entry.description || "")
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
            // Places without a folder: nothing to look at.
            + "[ -n \"$p\" ] || continue; "
            + "[ -d \"$p\" ] || { printf '@@MISSING\\n'; continue; }; "
            + "if git -C \"$p\" rev-parse --git-dir >/dev/null 2>&1; then "
            + "printf '@@GIT\\n'; git -C \"$p\" status --porcelain=v2 --branch 2>/dev/null; "
            + "printf '@@LOG\\n'; git -C \"$p\" log -1 --format='%ct%x09%s' 2>/dev/null; fi; "
            + "[ -f \"$p/README.md\" ] && printf '@@README\\n'; "
            + "[ -f \"$p/AGENTS.md\" ] && printf '@@AGENTS\\n'; "
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
                } else if (current && section === "AGENTS") {
                    current.agents = true;
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
            agents: false,
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
        if (!project.path) {
            detail = emptyDetail();
            return;
        }
        detailProcess.running = false;
        detailProcess.projectId = project.id;
        detailProcess.command = ["sh", "-c", detailScript(), "places", project.path, String(pt.recentFileDays), String(pt.recentFileLimit), String(pt.commitLimit), String(pt.activityWeeks), String(pt.docLimit)];
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
        // $1 path, $2 recent days, $3 recent limit, $4 commit limit, $5 activity weeks, $6 doc limit
        return "cd \"$1\" 2>/dev/null || exit 0; "
            + "if git rev-parse --git-dir >/dev/null 2>&1; then "
            + "printf '@@STATUS\\n'; git status --porcelain=v1 2>/dev/null | head -n 40; "
            + "printf '@@COMMITS\\n'; git log -n \"$4\" --format='%h%x09%ct%x09%an%x09%s' 2>/dev/null; "
            + "printf '@@ACTIVITY\\n'; git log --since=\"$5 weeks ago\" --format=%ct 2>/dev/null; "
            + "printf '@@COUNT\\n'; git rev-list --count HEAD 2>/dev/null; fi; "
            // fd honours .gitignore, so build output and vendor trees stay out.
            + "printf '@@RECENT\\n'; fd --type f --changed-within \"$2\"d --exclude .git --exec-batch stat -c '%Y\t%n' 2>/dev/null | sort -rn | head -n \"$3\"; "
            + "printf '@@PINNED\\n'; for f in README.md AGENTS.md CLAUDE.md docs/ai/CURRENT.md; do [ -f \"$f\" ] && printf '%s\\n' \"$f\"; done; "
            + "printf '@@FILES\\n'; fd --type f 2>/dev/null | wc -l; "
            // docs/: what someone wrote down, newest first. Two levels deep.
            + "if [ -d docs ]; then printf '@@DOCS\\n'; fd --type f --max-depth 2 -e md -e txt -e pdf -e html . docs --exec-batch stat -c '%Y\t%n' 2>/dev/null | sort -rn | head -n \"$6\"; fi";
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
            else if (section === "DOCS") {
                const tab = line.indexOf("\t");
                next.docs.push({
                    time: Number(line.slice(0, tab)) || 0,
                    path: line.slice(tab + 1).replace(/^\.\//, "")
                });
            }
        }

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
            commitCount: 0,
            recent: [],
            autoPinned: [],
            docs: [],
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
        run(theme.terminalCommand([], { cwd: project.path }), project.path);
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

        run(spec.terminal ? theme.terminalCommand(command, { cwd: cwd }) : command, cwd);
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

    // README.md first, AGENTS.md when there is no README; none when the
    // config already has a description.
    function readmePathFor(project, all) {
        const summary = project ? all[project.id] : null;

        if (!summary || project.description)
            return "";
        return summary.readme ? project.path + "/README.md" : summary.agents ? project.path + "/AGENTS.md" : "";
    }

    function description() {
        return selected && selected.description ? selected.description : readmeSummary;
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
