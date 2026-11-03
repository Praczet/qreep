# Orbit

A keyboard-first launcher shaped like a small solar system. One JSON file is
one tree: the current node sits in the middle, its items sit on a ring around
it. It is for a small hand-picked menu you learn by route. For "I know the name
of the thing", KIP is right there.

Going inside a node moves it to the middle while its siblings shrink into the
parent, which stays as a faint dot, lower-left. Older parents curl away behind
it, smaller and fainter, up to four in all. Its children then grow out of it. A thin line joins every visible node to its parent and follows them as they
move. Keys do not wait for any of this, so a fast route still lands correctly.

## Try it

```bash
mkdir -p ~/.config/qreep/orbit
cp modules/orbit/examples/mox.json ~/.config/qreep/orbit/mox.json
quickshell -c qreep ipc call qreep-orbit toggleWith mox
```

## IPC

```bash
quickshell -c qreep ipc call qreep-orbit showWith mox       # or an absolute path
quickshell -c qreep ipc call qreep-orbit toggleWith mox     # another name switches file
quickshell -c qreep ipc call qreep-orbit hideMe
quickshell -c qreep ipc call qreep-orbit state
```

Do not rename `showWith` to `show`. The quickshell CLI reads that word as its
own `ipc show` command and rejects the argument.

## Keys

| Key | What it does |
| --- | --- |
| Letters | Match the label. One match left: go inside it, or run it when it has no items |
| `Tab` / `Shift+Tab` | Clockwise / anticlockwise around the ring |
| `Enter` / click | Run the action, or go inside when there is none |
| `Backspace` | Clear typed letters, then go up |
| `Esc` | Clear typed letters, then go up, then close |
| `Ctrl+Esc` | Close, however deep you are |

Click the centre to go up, or a parent to jump back to it. Click outside to close.

## JSON

The file lives at `~/.config/qreep/orbit/<name>.json`. It is watched, so a saved
edit shows up at once and puts you back at the top. Every node, the top one
included, takes these fields:

| Field | Meaning |
| --- | --- |
| `name` | Full name, shown next to the node and under the centre when selected. Falls back to the app's name |
| `text` | Circle label and what you type. Defaults to the first two letters of `name` |
| `icon` | Themed icon name, or a path starting with `/` or `~/`. Beats `text` on the circle |
| `key` | Pins what you type. A pinned node answers only to this, so a new neighbour cannot change its route |
| `items` | Child nodes |
| `itemsSource` | Another Orbit file whose `items` go under this node, after any local `items`. Same path rules as `showWith` |
| `app` | Desktop entry id. Also supplies the name and icon |
| `exec` | Argv array, no shell. An argument that starts with `~/` is expanded |
| `ipc` | Qreep IPC, for example `["qreep-aegis", "toggle"]` |

A node with an action and items runs on `Enter` and opens on its letters. A node
with neither just gets selected, so a read-only diagram works. The actions are
checked in the order `app`, `exec`, `ipc`; the first one set wins.

A node with `itemsSource` keeps its own `name` and `icon`, and borrows the other
file's when it has none. A file works on its own and pulled into another one.
Every file is read when Orbit opens and watched while it stays loaded. A missing
or broken file, or a loop of files, breaks only the node asking for it; select
that node to see why.

Icon nodes get a small badge saying what to type, because a folder picture is
not much of a hint.

## Not built yet

- Organic placement.
- Arrow keys.
- Validating a file when it loads. Broken JSON and a missing file show an error,
  but a malformed `exec` only complains when you run it.

Orbit only reads its files. It writes nothing but the processes it launches.

## How the motion works

The ring turns slowly while Orbit is open. Set `ringRotationEnabled` to `false`
in `OrbitTheme.qml` to stop it, or change `ringRotationSeconds` for the speed.
Keys and Tab order are unaffected; only the place on screen drifts.

`OrbitLayout.scene()` is a pure function: tree position in, target for every node
out. Each node keeps one `OrbitNode` for the life of the panel and animates to
its target from wherever it currently is. Timing lives in `OrbitTheme.qml`. Keep
it that way; per-transition animation scripts are how this gets unreadable.
