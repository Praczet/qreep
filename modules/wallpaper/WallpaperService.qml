import QtQuick
import Quickshell
import Quickshell.Io
import "WallpaperColorNames.js" as ColorNames

// Wallpapers: the folder listing, thumbnails, the current one, view state,
// and applying. wallpaper-thumbs (next to this file) does the file work:
// "list" is instant and never decodes an image, "build" makes the missing
// thumbnails in parallel while the panel already shows what it has.
Item {
    id: rootWallpaperService

    required property QtObject theme

    readonly property QtObject wt: theme.modules.wallpaper
    readonly property string worker: Quickshell.shellDir + "/modules/wallpaper/wallpaper-thumbs"

    // [{ name, path, bytes, width, height, thumbed, colors }], by name.
    // colors: the worker's palette, biggest share first, each as
    // { hex, share, l, a, b, c, h } in OKLab/OKLCH (see oklab()).
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

    // Every word must match. A colour word ("teal", "dark", "#7aa2f7", ...)
    // matches the palette or the name; any other word matches the name.
    // A half-typed hex ("#7a") is ignored until it is complete. With a hex
    // in the query, the closest palettes come first.
    function filter(list, text) {
        const words = String(text || "").toLowerCase().split(/\s+/).filter(word => word.length > 0 && !/^#[0-9a-f]{0,5}$/.test(word) || /^#([0-9a-f]{3}|[0-9a-f]{6})$/.test(word));

        if (words.length === 0)
            return list;

        const terms = words.map(word => ({
                    word: word,
                    color: colorTerm(word)
                }));
        const kept = list.filter(item => terms.every(term => item.name.toLowerCase().indexOf(term.word) >= 0 || (term.color !== null && (item.colors || []).length > 0 && term.color.test(item.colors))));
        const ranked = terms.filter(term => term.color !== null && term.color.distance !== undefined);

        if (ranked.length === 0)
            return kept;

        const score = item => ranked.reduce((sum, term) => sum + term.color.distance(item.colors || []), 0);

        return kept.slice().sort((left, right) => score(left) - score(right));
    }

    // --- colour search ------------------------------------------------------

    // OKLCH hue centre and half-width in degrees; a palette colour needs
    // some chroma (c >= 0.04) to count as having a hue at all.
    readonly property var hueWords: ({
            red: [27, 20],
            orange: [58, 18],
            yellow: [100, 22],
            green: [142, 34],
            teal: [182, 16],
            cyan: [210, 18],
            blue: [258, 24],
            violet: [292, 16],
            purple: [305, 20],
            magenta: [330, 14],
            pink: [352, 18]
        })

    // "#rrggbb" -> OKLab (l, a, b) plus OKLCH chroma c and hue h.
    function oklab(hex) {
        const linear = value => {
            const v = value / 255;

            return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        };
        const r = linear(parseInt(hex.slice(1, 3), 16));
        const g = linear(parseInt(hex.slice(3, 5), 16));
        const b = linear(parseInt(hex.slice(5, 7), 16));
        const lc = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
        const mc = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
        const sc = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
        const okA = 1.9779984951 * lc - 2.4285922050 * mc + 0.4505937099 * sc;
        const okB = 0.0259040371 * lc + 0.7827717662 * mc - 0.8086757660 * sc;
        const hue = Math.atan2(okB, okA) * 180 / Math.PI;

        return {
            l: 0.2104542553 * lc + 0.7936177850 * mc - 0.0040720468 * sc,
            a: okA,
            b: okB,
            c: Math.sqrt(okA * okA + okB * okB),
            h: hue < 0 ? hue + 360 : hue
        };
    }

    // "#2b3a55 0.41 #c8a46e 0.18 ..." -> [{ hex, share, l, a, b, c, h }]
    function parsePalette(text) {
        const parts = String(text || "").trim().split(/\s+/);
        const palette = [];

        for (let i = 0; i + 1 < parts.length; i += 2) {
            if (/^#[0-9a-f]{6}$/i.test(parts[i]))
                palette.push(Object.assign({
                    hex: parts[i].toLowerCase(),
                    share: Number(parts[i + 1]) || 0
                }, oklab(parts[i])));
        }
        return palette;
    }

    function hueGap(left, right) {
        const gap = Math.abs(left - right) % 360;

        return gap > 180 ? 360 - gap : gap;
    }

    function shareOf(palette, test) {
        return palette.reduce((sum, color) => sum + (test(color) ? color.share : 0), 0);
    }

    function weighted(palette, key) {
        return palette.reduce((sum, color) => sum + color[key] * color.share, 0);
    }

    // OKLab distance from a target to the nearest palette colour that covers
    // at least 5% of the image.
    function distanceTo(palette, target) {
        let best = 9;

        for (const color of palette) {
            if (color.share >= 0.05)
                best = Math.min(best, Math.hypot(color.l - target.l, color.a - target.a, color.b - target.b));
        }
        return best;
    }

    // A single colour: palettes with a dominant colour near it, closest first.
    function nearTerm(hex) {
        const target = oklab(hex);

        return {
            test: palette => distanceTo(palette, target) < 0.1,
            distance: palette => distanceTo(palette, target)
        };
    }

    // null when the word is not about colour; otherwise { test(palette) }
    // and, for single colours, distance(palette) for ranking. Order matters:
    // a hex, then the broad hue families ("blue" means any blue, not CSS
    // #0000ff), then the descriptive words, then the CSS names
    // ("steelblue" means near #4682b4).
    function colorTerm(word) {
        if (/^#([0-9a-f]{3}|[0-9a-f]{6})$/.test(word))
            return nearTerm(word.length === 4 ? "#" + word.slice(1).split("").map(digit => digit + digit).join("") : word);
        if (hueWords[word] !== undefined) {
            const centre = hueWords[word][0];
            const width = hueWords[word][1];

            return {
                test: palette => shareOf(palette, color => color.c >= 0.04 && hueGap(color.h, centre) <= width) >= 0.1
            };
        }

        const warmth = palette => shareOf(palette, color => color.c >= 0.04 && (color.h < 110 || color.h > 330));
        const coolness = palette => shareOf(palette, color => color.c >= 0.04 && color.h >= 150 && color.h <= 300);

        switch (word) {
        case "dark":
            return { test: palette => weighted(palette, "l") < 0.4 };
        case "light":
        case "bright":
            return { test: palette => weighted(palette, "l") > 0.65 };
        case "muted":
            return { test: palette => weighted(palette, "c") < 0.05 };
        case "vivid":
        case "colorful":
        case "colourful":
            return { test: palette => weighted(palette, "c") > 0.1 };
        case "grey":
        case "gray":
            return { test: palette => weighted(palette, "c") < 0.03 };
        case "black":
            return { test: palette => shareOf(palette, color => color.l < 0.2) >= 0.5 };
        case "white":
            return { test: palette => shareOf(palette, color => color.l > 0.9 && color.c < 0.04) >= 0.3 };
        case "warm":
            return { test: palette => warmth(palette) >= 0.25 && warmth(palette) > coolness(palette) };
        case "cool":
            return { test: palette => coolness(palette) >= 0.25 && coolness(palette) > warmth(palette) };
        }
        if (ColorNames.names.hasOwnProperty(word))
            return nearTerm(ColorNames.names[word]);
        return null;
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
                    thumbed: parts[4] === "1",
                    colors: rootWallpaperService.parsePalette(parts[5])
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
