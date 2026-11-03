import QtQuick
import Quickshell
import Quickshell.Io

// Loads one Orbit JSON file and any files it pulls in through itemsSource,
// tracks where you are in the tree, and runs the chosen node. Only reads the
// files; writes nothing.
Scope {
    id: rootOrbitService

    required property QtObject theme

    readonly property QtObject ot: theme.modules.orbit
    readonly property string home: Quickshell.env("HOME")

    property string fileName: ""
    property string error: ""
    // The file showWith asked for, and every file read so far, by path:
    // { value } when it parsed, { error } when it did not.
    property string rootPath: ""
    property var files: ({})
    // One watching FileView per path.
    property var fileViews: ({})
    // Normalised tree: { id, name, text, iconSource, key, app, exec, ipc, items }.
    property var root: null
    // Every node of the tree, flat. The panel keeps one circle alive per node.
    property var nodes: []
    // Nodes above the current one: [{ node, selectedIndex }].
    property var trail: []
    property var current: null
    property int selectedIndex: -1
    // Letters typed so far, while they still match more than one node.
    property string typed: ""

    readonly property var items: current ? current.items : []
    readonly property var selectedNode: selectedIndex >= 0 && selectedIndex < items.length ? items[selectedIndex] : null
    readonly property var matchedIndexes: typed.length > 0 ? matches(typed) : []
    // A failed itemsSource breaks only its own node, so it shows on that node.
    readonly property string problem: error || (selectedNode && selectedNode.sourceError) || (current && current.sourceError) || ""

    signal closeRequested

    readonly property Component fileViewComponent: Component {
        FileView {
            watchChanges: true
            preload: true

            onFileChanged: reload()
            onLoaded: rootOrbitService.fileLoaded(path, text())
            onLoadFailed: loadError => rootOrbitService.fileFailed(path, loadError === FileViewError.FileNotFound ? "No file at " + path : "Could not read " + path)
        }
    }

    Process {
        id: launcher

        workingDirectory: rootOrbitService.home
    }

    // "mox" -> <configDir>/mox.json; an absolute path is used as it is.
    function load(name) {
        fileName = name;
        error = "";
        setTree(null);
        for (const path in fileViews)
            fileViews[path].destroy();
        fileViews = {};
        files = {};
        rootPath = pathFor(name);
        watchFile(rootPath);
    }

    function watchFile(path) {
        const views = Object.assign({}, fileViews);

        views[path] = fileViewComponent.createObject(rootOrbitService, {
            path: path
        });
        fileViews = views;
    }

    function pathFor(name) {
        const expanded = expand(name);

        if (expanded.startsWith("/"))
            return expanded;
        return ot.configDir + "/" + (expanded.endsWith(".json") ? expanded : expanded + ".json");
    }

    function expand(value) {
        const text = String(value);

        return text === "~" || text.startsWith("~/") ? home + text.slice(1) : text;
    }

    function fileLoaded(path, text) {
        storeFile(path, parseFile(path, text));
    }

    function fileFailed(path, message) {
        storeFile(path, {
            error: message
        });
    }

    function storeFile(path, result) {
        const known = Object.assign({}, files);

        known[path] = result;
        files = known;
        rebuild();
    }

    function parseFile(path, text) {
        let parsed = null;

        try {
            parsed = JSON.parse(text);
        } catch (parseError) {
            return {
                error: path + ": " + parseError.message
            };
        }
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
            return {
                error: path + ": the top level must be one node"
            };
        }
        return {
            value: parsed
        };
    }

    // Walk the tree with the files read so far. A source nobody has read yet
    // goes on the list and the walk is thrown away; each file that arrives
    // comes back here, so the tree appears once, complete.
    function rebuild() {
        const file = files[rootPath];

        if (!file)
            return;
        if (file.error) {
            setTree(null);
            error = file.error;
            return;
        }

        const missing = {};
        const tree = normalize(file.value, "root", [rootPath], missing);
        const paths = Object.keys(missing);

        if (paths.length > 0) {
            paths.filter(path => !fileViews[path]).forEach(path => watchFile(path));
            return;
        }

        error = "";
        setTree(tree);
    }

    // What an itemsSource points at: { node, chain } to use, { error } when it
    // cannot be used, or nothing yet while the file is still being read.
    function readSource(source, chain, missing) {
        const path = pathFor(source);

        if (chain.indexOf(path) >= 0)
            return {
                error: "itemsSource loop: " + chain.concat([path]).join(" -> ")
            };

        const file = files[path];

        if (!file) {
            missing[path] = true;
            return {};
        }
        if (file.error)
            return {
                error: file.error
            };
        return {
            node: file.value,
            chain: chain.concat([path])
        };
    }

    function setTree(tree) {
        root = tree;
        nodes = tree ? flatten(tree) : [];
        trail = [];
        current = tree;
        selectedIndex = tree && tree.items.length > 0 ? 0 : -1;
        typed = "";
    }

    function flatten(node) {
        return node.items.reduce((list, child) => list.concat(flatten(child)), [node]);
    }

    function normalize(raw, id, chain, missing) {
        const node = raw && typeof raw === "object" ? raw : {};
        const entry = node.app ? appEntry(node.app) : null;
        const source = node.itemsSource ? readSource(node.itemsSource, chain, missing) : {};
        const sourced = source.node || {};
        const name = String(node.name || (entry && entry.name) || sourced.name || node.text || "?");
        const own = (Array.isArray(node.items) ? node.items : []).map(child => ({
            raw: child,
            chain: chain
        }));
        const pulled = (Array.isArray(sourced.items) ? sourced.items : []).map(child => ({
            raw: child,
            chain: source.chain
        }));

        return {
            id: id,
            name: name,
            text: String(node.text || name.charAt(0).toUpperCase() + name.slice(1, 2)),
            iconSource: iconSource(node.icon || (entry && entry.icon) || sourced.icon || ""),
            key: String(node.key || "").toLowerCase(),
            app: node.app ? String(node.app) : "",
            exec: node.exec || null,
            ipc: node.ipc || null,
            sourceError: source.error || "",
            items: own.concat(pulled).map((child, index) => normalize(child.raw, id + "/" + index, child.chain, missing))
        };
    }

    function appEntry(id) {
        return DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id) || null;
    }

    function iconSource(icon) {
        const value = expand(icon);

        if (value.length === 0)
            return "";
        return value.startsWith("/") ? "file://" + value : Quickshell.iconPath(value, true);
    }

    // --- navigation -------------------------------------------------------

    function cycle(step) {
        if (items.length === 0)
            return;
        typed = "";
        error = "";
        selectedIndex = (selectedIndex + step + items.length) % items.length;
    }

    function enter(index) {
        trail = trail.concat([{
            node: current,
            selectedIndex: index
        }]);
        current = items[index];
        selectedIndex = current.items.length > 0 ? 0 : -1;
        typed = "";
        error = "";
    }

    // False at the root, so the panel knows Esc should close instead.
    function goUp() {
        if (trail.length === 0)
            return false;

        const last = trail[trail.length - 1];

        trail = trail.slice(0, -1);
        current = last.node;
        selectedIndex = last.selectedIndex;
        typed = "";
        error = "";
        return true;
    }

    function goUpLevels(count) {
        for (let level = 0; level < count; level++)
            goUp();
    }

    function clearTyped() {
        if (typed.length === 0)
            return false;
        typed = "";
        return true;
    }

    // Indexes of the nodes answering to these letters. A pinned key answers
    // only to itself and beats label matches, so it stays stable when a
    // neighbour with a similar label turns up.
    function matches(letters) {
        const list = items;
        const indexes = list.map((node, index) => index);
        const pinned = indexes.filter(index => list[index].key === letters);

        if (pinned.length > 0)
            return pinned;
        return indexes.filter(index => list[index].key.length === 0 && list[index].text.toLowerCase().startsWith(letters));
    }

    function isDimmed(index) {
        return typed.length > 0 && matchedIndexes.indexOf(index) < 0;
    }

    // One match left: go inside it, or run it when it has nothing inside.
    // Several left: select the first and wait for the next letter.
    function typeLetter(letter) {
        error = "";

        let letters = typed + letter;
        let found = matches(letters);

        if (found.length === 0 && typed.length > 0) {
            letters = letter;
            found = matches(letters);
        }
        if (found.length === 0) {
            typed = "";
            return;
        }

        selectedIndex = found[0];
        if (found.length > 1) {
            typed = letters;
            return;
        }

        typed = "";
        if (items[found[0]].items.length > 0)
            enter(found[0]);
        else
            activate(found[0]);
    }

    // Enter and click: run the node's action, or go inside when it has none.
    // A node with neither just stays selected, which is how diagrams work.
    function activate(index) {
        const node = items[index];

        if (!node)
            return;

        typed = "";
        error = "";
        selectedIndex = index;
        if (node.app || node.exec || node.ipc) {
            if (run(node))
                closeRequested();
        } else if (node.items.length > 0) {
            enter(index);
        }
    }

    function detailOf(node) {
        if (!node)
            return "";
        if (node.app)
            return node.app;
        if (Array.isArray(node.exec))
            return node.exec.join(" ");
        if (Array.isArray(node.ipc))
            return node.ipc.join(" ");
        return node.items.length > 0 ? node.items.length + (node.items.length === 1 ? " item" : " items") : "";
    }

    // --- actions ----------------------------------------------------------

    function run(node) {
        if (node.app)
            return runApp(node);

        const field = node.exec ? "exec" : "ipc";
        const args = node[field];

        if (!Array.isArray(args) || args.length === 0) {
            error = node.name + ": " + field + " must be a non-empty array";
            return false;
        }

        const strings = args.map(arg => expand(arg));

        startProcess(node.exec ? strings : ["quickshell", "ipc", "--pid", String(Quickshell.processId), "call"].concat(strings));
        return true;
    }

    function runApp(node) {
        const entry = appEntry(node.app);

        if (!entry) {
            error = node.name + ": no desktop entry for " + node.app;
            return false;
        }
        if (entry.runInTerminal)
            startProcess(theme.terminalCommand(entry.command));
        else
            entry.execute();
        return true;
    }

    function startProcess(command) {
        launcher.command = command;
        launcher.startDetached();
    }
}
