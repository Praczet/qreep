import QtQuick

// Tips for the card under the project list, zsh "tip of the day" style, in Markdown.
// A random one per open, click for the next. Extra tips can come from
// places.json: "tips": { "enabled": true, "items": ["..."] }.
// qmlformat off
QtObject {
  readonly property var builtIn: [
    "`command ssd <host>` bypasses the ssh alias and pure ssh command",
    "Alt+1 … Alt+9 jump into cards: a project's file cards first, then its blocks.",
    "Places are pages of blocks: apps, documents, folders. Add one under \"places\" in places.json.",
    "Blocks take \"enabled\": false too, so a card can rest without being deleted.",
    "Open with remembers: pick code for .sql once and it moves to the top for .sql files.",
    "Open with lists every app that can open the file, the default first.",
    "A calendar block shows the bar clock's events: { \"type\": \"calendar\", \"days\": 3 }.",
    "A todos block lists Logseq TODO/NOW/LATER lines; Enter opens the page in Logseq.",
    "In an apps card, left and right walk the apps; up and down change card.",
    "\"folders\" is a list of shortcuts; \"folder\" lists what is inside one path.",
    "Blocks fill two columns, each into the shorter one; \"wide\": true takes the full width.",
    "\"hideWhenEmpty\": true hides a block with nothing to show; usb does it by default.",
    "Green SSH icon: the host's ssh port answered when Places opened. Dim: it did not.",
    "Ctrl+1 … Ctrl+0 jump straight to the 1st … 10th entry; each row shows its key.",
    "A usb block shows plugged-in drives live; Eject unmounts and powers them off.",
    "smb shares mount through GVFS; the password stays in GNOME Keyring, never in places.json.",
    "An ssh block with no items lists every host in ~/.ssh/config. Enter opens kitty with kitten ssh.",
    "From KIP: `/ssh` lists the same hosts as the ssh blocks; Enter connects.",
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
    "Esc clears the filter first and closes Places second."]
}
