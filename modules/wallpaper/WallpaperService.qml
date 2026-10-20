import QtQuick
import Quickshell
import Quickshell.Io

// Wallpapers: the folder listing, thumbnails, the current one, view state,
// and applying. wallpaper-thumbs (next to this file) does the file work:
// "list" is instant and never decodes an image, "build" makes the missing
// thumbnails in parallel while the panel already shows what it has.
Item {
    id: rootWallpaperService

    required property QtObject theme

    readonly property QtObject wt: theme.modules.wallpaper
    readonly property string worker: Quickshell.shellDir + "/modules/wallpaper/wallpaper-thumbs"

    // [{ name, path, bytes, width, height, thumbed }], by name.
    property var wallpapers: []
    property string query: ""
    readonly property var filtered: filter(wallpapers, query)
    property string current: ""
    // The panel's highlighted wallpaper name, for the IPC state line.
    property string selectedName: ""
    property string errorText: ""

    // Thumbnail build progress; stamp changes when it finishes, so images
    // that failed to load (thumb not made yet) are asked for again.
    property bool building: false
    property int buildTotal: 0
    property int buildDone: 0
    property int thumbStamp: 0

    // Remembered between opens: "grid" | "list", and a key of wt.sizes.
    property string view: "grid"
    property string size: "m"

    // Unclaimed Bloom compositions (names), the active one (current-profile
    // file), and the one chosen in the panel. Choosing changes nothing until
    // apply; every open starts again from the active one.
    property var profiles: []
    property string currentProfile: ""
    property string chosenProfile: ""

    function refresh() {
        listProcess.running = false;
        listProcess.running = true;
        chosenProfile = currentProfile;
        profileProcess.running = false;
        profileProcess.running = true;
        if (!building) {
            buildProcess.running = true;
            building = true;
        }
    }

    function setQuery(text) {
        query = String(text || "");
    }

    function filter(list, text) {
        const words = String(text || "").toLowerCase().split(/\s+/).filter(word => word.length > 0);

        if (words.length === 0)
            return list;
        return list.filter(item => words.every(word => item.name.toLowerCase().indexOf(word) >= 0));
    }

    // file:// URL of a thumbnail (400 or 800), or "" when it is not made yet.
    function thumbUrl(item, px) {
        if (!item || !item.thumbed)
            return "";
        return "file://" + wt.thumbnailDir + "/" + px + "/" + encodeURIComponent(item.name + ".jpg") + "?" + thumbStamp;
    }

    function isCurrent(item) {
        return item !== null && item !== undefined && item.path === current;
    }

    function apply(item) {
        if (!item)
            return;
        // A different profile is switched first, so wallset (which plants the
        // active profile) grows the new one. sh -c with positional arguments:
        // names and paths are never pasted into the script text.
        if (chosenProfile.length > 0 && chosenProfile !== currentProfile)
            applier.command = ["sh", "-c", "\"$0\" profile use \"$1\" && exec \"$2\" \"$3\"", wt.sporeCommand, chosenProfile, wt.applyCommand, item.path];
        else
            applier.command = [wt.applyCommand, item.path];
        applier.startDetached();
    }

    function chooseProfile(name) {
        if (profiles.indexOf(name) >= 0)
            chosenProfile = name;
    }

    // Ctrl+B / Ctrl+Shift+B: next / previous, wrapping.
    function stepProfile(step) {
        if (profiles.length === 0)
            return;
        const index = profiles.indexOf(chosenProfile);

        chosenProfile = index < 0 ? profiles[0] : profiles[(index + step + profiles.length) % profiles.length];
    }

    function setView(next) {
        view = next === "list" ? "list" : "grid";
        saveState();
    }

    function setSize(next) {
        if (wt.sizeOrder.indexOf(next) < 0)
            return;
        size = next;
        saveState();
    }

    function stepSize(step) {
        const index = Math.max(0, Math.min(wt.sizeOrder.length - 1, wt.sizeOrder.indexOf(size) + step));

        size = wt.sizeOrder[index];
        saveState();
    }

    function saveState() {
        stateFile.setText(JSON.stringify({
            view: view,
            size: size
        }, null, 2) + "\n");
    }

    function formatBytes(bytes) {
        if (bytes >= 1048576)
            return (bytes / 1048576).toFixed(1) + " MB";
        return Math.max(1, Math.round(bytes / 1024)) + " KB";
    }

    function describe(item) {
        if (!item)
            return "";
        return (item.width > 0 ? item.width + "×" + item.height + " · " : "") + formatBytes(item.bytes);
    }

    Process {
        id: listProcess

        command: [rootWallpaperService.worker, "list", rootWallpaperService.wt.wallpaperDir, rootWallpaperService.wt.thumbnailDir]

        stdout: StdioCollector {
            id: listStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: listStderr

            waitForEnd: true
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                rootWallpaperService.errorText = listStderr.text.trim() || "wallpaper-thumbs list failed (exit " + exitCode + ").";
                rootWallpaperService.wallpapers = [];
                return;
            }

            const dir = rootWallpaperService.wt.wallpaperDir;

            rootWallpaperService.errorText = "";
            rootWallpaperService.wallpapers = listStdout.text.split("\n").filter(line => line.length > 0).map(line => {
                const parts = line.split("\t");

                return {
                    name: parts[0],
                    path: dir + "/" + parts[0],
                    bytes: Number(parts[1]) || 0,
                    width: Number(parts[2]) || 0,
                    height: Number(parts[3]) || 0,
                    thumbed: parts[4] === "1"
                };
            });
        }
    }

    Process {
        id: buildProcess

        command: [rootWallpaperService.worker, "build", rootWallpaperService.wt.wallpaperDir, rootWallpaperService.wt.thumbnailDir]

        stdout: SplitParser {
            onRead: data => {
                const line = String(data);

                if (line.indexOf("todo ") === 0) {
                    rootWallpaperService.buildTotal = Number(line.slice(5)) || 0;
                    rootWallpaperService.buildDone = 0;
                } else if (line.indexOf("made ") === 0) {
                    rootWallpaperService.buildDone++;
                }
            }
        }

        onExited: {
            const made = rootWallpaperService.buildDone > 0;

            rootWallpaperService.building = false;
            rootWallpaperService.buildTotal = 0;
            rootWallpaperService.buildDone = 0;
            if (made) {
                rootWallpaperService.thumbStamp++;
                listProcess.running = true;
            }
        }
    }

    Process {
        id: applier
    }

    // Only compositions: they theme the whole desktop (GTK included). A plain
    // profile such as daily-gtk would plant a single target.
    Process {
        id: profileProcess

        command: [rootWallpaperService.wt.sporeCommand, "profile", "list", "--json"]

        stdout: StdioCollector {
            id: profileStdout

            waitForEnd: true
        }

        onExited: exitCode => {
            if (exitCode !== 0)
                return;
            try {
                const listed = JSON.parse(profileStdout.text).profiles || [];

                rootWallpaperService.profiles = listed.filter(profile => profile.type === "composition").map(profile => profile.name);
            } catch (error) {
                rootWallpaperService.profiles = [];
            }
        }
    }

    FileView {
        path: rootWallpaperService.wt.currentProfileFile
        preload: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            const active = text().trim();
            const following = rootWallpaperService.chosenProfile === rootWallpaperService.currentProfile;

            rootWallpaperService.currentProfile = active;
            // Keep a pending choice; otherwise follow the active profile.
            if (following || rootWallpaperService.chosenProfile.length === 0)
                rootWallpaperService.chosenProfile = active;
        }
    }

    FileView {
        path: rootWallpaperService.wt.currentWallpaperFile
        preload: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: rootWallpaperService.current = text().trim()
    }

    FileView {
        id: stateFile

        path: rootWallpaperService.wt.statePath
        preload: true
        printErrors: false

        onLoaded: {
            try {
                const saved = JSON.parse(text() || "{}");

                if (saved.view === "list" || saved.view === "grid")
                    rootWallpaperService.view = saved.view;
                if (rootWallpaperService.wt.sizeOrder.indexOf(saved.size) >= 0)
                    rootWallpaperService.size = saved.size;
            } catch (error) {}
        }
    }
}
