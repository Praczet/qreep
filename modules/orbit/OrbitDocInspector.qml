import Quickshell
import Quickshell.Io

// Asks once what can open a file: its type, the default app, and every desktop
// entry that lists the type. Same lookup as the Open with chooser in Places.
Process {
    id: rootOrbitDocInspector

    required property string path

    signal answered(string path, var info)

    running: true
    // Line 1 "missing" or the mime type, line 2 the default desktop id, then
    // every .desktop file that lists the type and is not NoDisplay=true.
    command: ["sh", "-c", "[ -e \"$1\" ] || { echo missing; exit 0; }; m=$(xdg-mime query filetype \"$1\" 2>/dev/null); printf '%s\\n%s\\n' \"$m\" \"$(xdg-mime query default \"$m\" 2>/dev/null)\"; "
        + "[ -n \"$m\" ] || exit 0; e=$(printf '%s' \"$m\" | sed 's/[.+]/\\\\&/g'); "
        + "for d in \"${XDG_DATA_HOME:-$HOME/.local/share}/applications\" /usr/local/share/applications /usr/share/applications /var/lib/flatpak/exports/share/applications \"$HOME/.local/share/flatpak/exports/share/applications\"; do "
        + "[ -d \"$d\" ] && grep -lE \"^MimeType=(.*;)?$e(;|$)\" \"$d\"/*.desktop 2>/dev/null | while read -r f; do grep -q '^NoDisplay=true' \"$f\" || printf '%s\\n' \"$f\"; done; done", "orbit", path]

    stdout: StdioCollector {
        id: output

        waitForEnd: true
    }

    onExited: {
        const lines = output.text.split("\n").map(line => line.trim());
        const mime = lines[0] || "";

        if (mime === "missing") {
            answered(path, {
                error: "No file at " + path
            });
            return;
        }

        const defaultId = (lines[1] || "").replace(/\.desktop$/, "");
        const seen = {};
        const apps = [];

        // The first file per id wins: user dirs come before system ones.
        for (const file of lines.slice(2).filter(line => line.length > 0)) {
            const id = file.replace(/^.*\//, "").replace(/\.desktop$/, "");

            if (seen[id])
                continue;
            seen[id] = true;

            const entry = DesktopEntries.byId(id);

            apps.push({
                id: id,
                name: entry ? entry.name : id,
                icon: entry ? entry.icon : "",
                desktopFile: file,
                isDefault: id === defaultId
            });
        }
        apps.sort((left, right) => (right.isDefault ? 1 : 0) - (left.isDefault ? 1 : 0) || left.name.localeCompare(right.name));

        answered(path, {
            mime: mime,
            apps: apps
        });
    }
}
