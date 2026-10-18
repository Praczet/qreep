# Qreeper map surfaces

QREEP renders Qreeper's published map. It does not read the Blightmud database, parse MUD output, infer successful movement, or write back notes. The Lua plugin remains the adult in that particular room.

## On demand

Qreeper is a play-time feature, so it starts asleep: no snapshot watch, no
fallback polling, and no compass pill in the bar. A session starts with
`start`, or by opening the minimap or Atlas (IPC, a keybind, or KIP's
`/qreep` Qreeper group). `stop` closes both surfaces and puts it back to
sleep. Nothing about this is persisted; a Qreep restart means asleep again.

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper start
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper stop
```

## Controls

- Left-click the compass pill to toggle the floating minimap.
- Right-click it to toggle the Atlas.
- Drag the minimap header to move the window. Its top/right layer-shell margins are saved through Qt settings and clamped when it opens.
- Drag inside either map to pan and use the wheel to zoom.
- The minimap camera stays on the current room, easing after it as the layout settles (also into a new map). Zooming keeps following; panning pauses it. Press `◎` to recenter and resume.
- In the Atlas, use `−`/`+` to change floors, `current ◎` to find the current room, and `Escape` to close.
- Drag a room to move it; it stays pinned where you drop it. Right-click a room to release the pin.
- Atlas `rearrange` re-runs the layout and keeps pinned rooms. `reset` (double-click) forgets every position and pin.

The pill can be hidden with the normal bar-pill API:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar-pill disablePill qreeper
```

That only hides the button, and it wins over a running session. The
controller and IPC remain alive either way.

## IPC

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper start
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper stop
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper toggleMinimap
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper showMinimap
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper hideMinimap
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper toggleAtlas
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper showAtlas
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper hideAtlas
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper refresh
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper recenter
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper rearrange
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper resetLayout
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper state
```

## Text size

On a small high-density laptop panel the default text reads like fine print. `fontScale` in `QreeperTheme.qml` scales map and panel text. Room nodes, grid spacing, headers, and buttons grow with it, so room ids stay inside their rooms. Edit that value to change the size used at startup.

To change it while running, use the Atlas `A−` / `A+` buttons or IPC. Runtime changes are lost on restart. The value is clamped to `0.7`–`2.0`.

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper fontBigger
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper fontSmaller
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper setFontScale 1.3
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper resetFontScale
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-qreeper fontScale
```

## Snapshot bridge

The default read-only input is:

```text
~/.local/state/qreeper/map.json
```

Set `QREEP_QREEPER_MAP_PATH` before starting QREEP to use another file. `FileView` watches the path and a two-second reload backs it up so atomic replacement does not leave the watcher admiring an obsolete inode.

The complete schema-version-1 snapshot has this shape:

```json
{
  "schemaVersion": 1,
  "world": "3scapes",
  "revision": 42,
  "publishedAt": "2026-10-12T10:00:00Z",
  "currentRoomId": 22,
  "rooms": [
    {
      "id": 22,
      "name": "Newbie Tower: Forest",
      "description": "A trail between dense trees.",
      "realm": "Newbieland",
      "area": "Newbie Tower: Forest",
      "level": 0,
      "x": 0,
      "y": 2,
      "z": 0,
      "positionStatus": "inferred",
      "notes": [{"id": 8, "text": "Thieves here", "createdAt": "2026-10-12T09:00:00Z"}]
    }
  ],
  "exits": [
    {"from": 22, "direction": "north", "to": null, "geometry": "unknown"}
  ],
  "layout": {"anchorRoomId": 11, "coordinateSystem": "east+x,south+y,up+z"}
}
```

Contract rules:

- `schemaVersion` is exactly `1`; `revision` is a monotonically increasing non-negative integer.
- Optional, additive: each room may carry `mapId` (integer or `null`), each exit `boundary` (`null`, `"door"` or `"portal"`), each room `marked` (boolean, a room the player marked with `qreeper:mark-it`; drawn with a thick border and tinted fill), and the root a `maps` array of `{"id", "name", "type", "realm", "entranceRoomId"}`. A map is a separately laid-out group (streets, a building, a cave) joined to others by named exits or marked doors/portals; `x`/`y`/`z` are only comparable inside one map. `type` is a free word (`outdoor`, `building`, `cave`, or one the player added); `realm` may be `null`. Rooms no longer carry `realm`/`area`. The minimap and the Atlas show only the current room's map (and floor); each map and floor is laid out on its own, and an exit into another map is a stub naming that map. Room colour shape and entrance markers come from the map `type`.
- Room and note IDs are integers. `currentRoomId` is either `null` or the ID of a supplied room.
- `rooms` and `exits` are arrays. QREEP accepts at most 3,000 rooms and 10,000 exits per snapshot.
- `level`, `x`, `y`, and `z` may be absent or `null`; unknown is not silently converted to zero.
- `positionStatus` is `fixed`, `inferred`, or `unplaced`.
- Exits are directed. `to: null` means the exit is known but its destination has not been observed.
- `geometry` is `regular`, `irregular`, `named`, `unknown`, or `unplaced`. Only recorded regular edges get a solid spatial line.
- `publishedAt` is informational. Staleness is based on how long QREEP has gone without applying a newer revision.
- A bad newer snapshot leaves the last valid graph in memory and changes the UI state to error/stale.

## Layout

`QreeperLayout.qml` owns one organic layout for both views. The producer's `x`/`y` are only starting points; every room gets a position here, including rooms the producer left unplaced (seeded next to a neighbour, or east of everything for a separate area).

A small force simulation then settles it, and sleeps once nothing moves:

- every compass exit pulls its target towards the recorded direction; exits confirmed both ways pull twice as hard;
- compass exits the producer marks `irregular` do not pull at all. One looping exit (`223 west → 190` in the Valley of Eras) would otherwise drag a whole block of rooms seven cells across the map to obey it;
- named exits (`enter`, `omp`, …) are plain springs with no direction;
- rooms on the same level repel inside `layoutRepelRadius`, so they cannot overlap;
- pinned rooms (dragged by you) do not move and anchor everything else.

Drawing follows rule one: every exit leaves its room in its recorded direction, then bends to the target. An exit is solid when the target lies within ~35° of that direction (`layoutAgreeCos`), dashed with an arrow when it contradicts it. That is judged on the live layout, not the producer's grid classification.

Positions and pins are QREEP's own state in `~/.local/state/qreep/qreeper-layout.json` (written atomically). Only pinned rooms are restored from it; every other room starts again from the producer's grid, so a stale file cannot flip the map. Qreeper's database is never touched. All tuning lives in `QreeperTheme.qml` (`layout*`).

## Fixture test

Committed fixtures in `fixtures/qreeper/`:

| File | What it is |
| --- | --- |
| `map.json` | Base graph, current room `22`. Rooms 11–23, repeated `Newbie Tower: Forest` names, irregular `22 northeast → 18`, unknown `22 northwest`, named `up`/`down` to floor 1, `enter`/`out` to unplaced room 23, notes on 22 and 18. |
| `map-moved.json` | Same graph, current room `18`. |
| `map-discovered.json` | Adds placed room `24` south of 17 with real edges, now current. It sits next to 18 with no edge on purpose: no connector should be drawn. |

The service path is read once at startup, so the running daemon has to step aside first:

```bash
# Stop the normal instance; it watches the real state path, not the fixture.
quickshell kill -c qreep

export QREEP_QREEPER_MAP_PATH="$PWD/fixtures/qreeper/live-map.json"
quickshell --path "$PWD" --no-duplicate
```

In another terminal, export the same variable and drive it with the fixture helper. It writes temp file + `mv`, keeps revisions increasing in a `live-map.revision` sidecar, and refuses to touch `~/.local/state/qreeper/map.json` without `--real-state`:

```bash
export QREEP_QREEPER_MAP_PATH="$PWD/fixtures/qreeper/live-map.json"
scripts/qreep-qreeper-fixture_v0.0.1 --help
```

Acceptance checks and the commands that set them up:

| Check | Command | Expected |
| --- | --- | --- |
| No snapshot | `... remove`, then start QREEP | Bar works; both surfaces say they are waiting. |
| Snapshot appears | `... reset` | Room 22 highlighted; the minimap centers on it even if it was opened first. |
| Movement | `... move 18 12` | Highlight moves; map does not rearrange; the Atlas keeps its viewport. |
| Rapid travel | `... rapid` | Marker steps promptly; the camera eases after it and ends on 16. |
| Long travel | `... drift` | The current room stays centred the whole way. |
| Same-room change | `... note "Thieves again"` / `... exit southeast` | Visuals update; no recenter. |
| Failed move | `... touch` | Revision changes, marker does not. |
| Discovery | `... discover` | Room 24 and its edges appear; other nodes stay where they were. |
| Named exit | `... named` | Unplaced card for 23 says "Reached via enter from #22"; return to 22 leaves no phantom highlight. |
| Coalescing | `... coalesce 22 19 20` | Only 20 arrives, revisions are skipped; the camera ends at 20. |
| Unresolved | `... unresolved` | Map stays; location shows as unresolved. |
| Bad input | `... malformed` / `... unsupported` | Error state; last good graph stays on screen. `... reset` recovers. |
| Size | `... large 3000` / `... large 3500` | 3000 renders (watch the frame rate); 3500 is rejected by the limit. |

Restart the normal shell afterwards with `quickshell -c qreep -d`.

The static fixtures carry revisions 42–44. After the helper has published (epoch-sized revisions), a plain `cp` of a static fixture is ignored as old news; use `reset` or `discover` instead.

## Current limits

- Quickshell 0.3.2 and Qt 6 are the currently verified API baseline.
- Minimap placement is one saved top/right position in `~/.config/quickshell/qreep-qreeper.ini`, not per-monitor state. It is re-clamped on the selected output.
- Layer-shell windows cannot use ordinary desktop-window dragging. The header changes layer-shell margins from pointer deltas instead.
- The Atlas keeps its viewport while it remains open; closing it destroys the lazy surface. Persistent Atlas sessions and route planning are later problems.
- There is no QREEP-wide reduced-motion setting yet. Camera follow timings live in `QreeperTheme.qml`, ready for that setting when one exists.
- The producer is the Qreeper Blightmud plugin (`publisher/` in `~/.local/share/blightmud/plugins/qreeper`). It publishes after each room, note and geography change, plus a 60-second heartbeat, so `stale` here means Qreeper stopped, not that you stood still.
- Producer positions are first-placement-wins and stored, so nodes do not jump between snapshots. Up/down exits get z offsets and are classified like compass exits; they connect different `level` views, so the map does not draw them.
- Edges to rooms on another floor or to unplaced rooms (`11 up → 21`, `22 enter → 23`) are not drawn on the map. They are listed in the Atlas room details, and the unplaced card names its inbound exits.
- Every node binds to the camera, so a 3000-room graph repaints everything while panning. Fine for the fixture; unproven for a large real world.
