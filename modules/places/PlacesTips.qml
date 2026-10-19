import QtQuick

// Tips for the card under the project list, zsh "tip of the day" style.
// A random one per open, click for the next. Extra tips can come from
// places.json: "tips": { "enabled": true, "items": ["..."] }.
QtObject {
    readonly property var builtIn: [
        "Alt+1 … Alt+4 jump into Uncommitted, Pinned, Recently touched and Docs.",
        "Tab walks the buttons, then the file cards, then around again.",
        "Click a file, or Enter on it in a card, for Open with: nvim, Vivify, app, folder, terminal, copy path.",
        "Shift+Enter launches the cockpit: terminal and browser on the dev workspace.",
        "Ctrl+E opens the project in the other editor. Ctrl+O yazi, Ctrl+T a terminal.",
        "From KIP: /p eos opens Places on EOS. Shift+Enter there goes straight to the cockpit.",
        "\"enabled\": false on a project or group hides it without deleting it.",
        "\"pinned\": [\"docs/notes/spec.docx\"] in places.json pins a file to its project.",
        "\"description\" in places.json beats the README's first paragraph.",
        "No README? The header falls back to the first paragraph of AGENTS.md.",
        "A docs/ folder gets its own card, newest first, two levels deep.",
        "docs/ai/QUESTLOG.json or questlog.json shows up as the Quests card, live.",
        "The activity grid is a year of commits; darker squares are busier days.",
        "Ctrl+R re-reads the config, git, and stats.",
        "F1 lists every shortcut, in case this card is not enough.",
        "Esc clears the filter first and closes Places second."
    ]
}
