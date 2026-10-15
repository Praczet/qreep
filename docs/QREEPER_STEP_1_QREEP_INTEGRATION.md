# Qreeper × QREEP — Step 1: graphical integration, bar control, minimap and atlas

## Agent assignment

Implement the **QREEP side only** of integrating Qreeper (a Blightmud Lua MUD exploration companion) into the existing **Praczet/qreep** Quickshell desktop shell for Hyprland.

Repository: https://github.com/Praczet/qreep

This is **step 1 of 2**. Step 2 will change Qreeper's Lua plugin to publish live state. For now, fully implement the QREEP consumer, UI, interactions, state management, documentation, and a development fixture so the feature can be tested **without running Blightmud**.

You are expected to investigate the actual current repository, decide the most maintainable integration within its conventions, implement it, and verify it. **Do not blindly copy suggested paths or assume old repository structure is current.**

### Mandatory investigation before modifying code

1. Read root `AGENTS.md` completely and obey its instructions on architecture, QML, naming, styles, testing, documentation and commits. Its guidance takes precedence over this prompt when they conflict, except for the functional requirements specified here.
2. Examine `shell.qml`, `modules/bar/`, bar feature composition/registration, theme mechanisms, existing feature controller patterns, IPC routing, overlays/window management, and how mouse buttons are handled.
3. Inspect at least one bar-owned small control and at least one shell-owned large surface/controller (e.g., Dashboard, Exposé, Aegis, OSD) as appropriate. Reuse existing primitives rather than introducing parallel infrastructure.
4. Check installed Quickshell/Qt API availability. Verify the real behavior of `PanelWindow`, `PopupWindow`, `Scope`, `LazyLoader`, file watching, Wayland layers, focus handling, output/screen properties and pointer dragging against current code/docs. Don't invent APIs.
5. Briefly report architectural choices and any limitations before implementation, then implement; don't stop after only drafting a plan.

### Product vision

Qreeper is the companion that recognizes rooms in the text MUD **3Scapes**, while QREEP renders its map graph as a pleasant, useful, unobtrusive desktop UI. The Lua plugin owns discovery, SQLite, notes, connections, realm/area/level context and room identity. QREEP **must not** parse MUD text, write to the plugin's SQLite DB, or independently conclude which exits are real.

The integration has three surfaces:

- **Bar control:** a small, theme-consistent map/compass icon in the QREEP bar. **Left click toggles the floating minimap. Right click opens/toggles the large Atlas.** Show meaningful states (connected / waiting for data / stale / error) without loud decoration. Tooltips should include Qreeper and current location when available. Follow the bar's exact existing sizing, item registration, customization and visibility rules.
- **Floating minimap:** a small, persistent, **movable** overlay above normal application windows, intended to remain visible alongside Blightmud. A glanceable map centered on the current room, with current-room highlighting, nearby connected rooms, exits, notes indicators and reliable movement updates. It is not a tooltip, not anchored to the bar, and not a modal dialog. Keep interaction with Blightmud unaffected outside the overlay.
- **Large Atlas:** right-click opens a larger, nontrivial map surface for exploration, with panning, zoom, full graph context, room selection/details, notes and explanations of unknown/irregular edges. Opening the Atlas must not reset or corrupt minimap state.

Aim for QREEP's existing voice: deliberate, restrained, thematic, slightly playful, not a generic dashboard.

## Architecture and ownership

Follow the existing AGENTS.md convention: **bar hosts a small control; feature-owned shell-level module owns the controller and windows**. Likely shape (adapt to actual code):

```text
modules/
  bar/
    features/
      qreeper/            # Thin bar button only, if warranted
        QreeperButton.qml
  qreeper/
    Qreeper.qml           # Scope/controller, feature public API, IPC if appropriate
    QreeperService.qml    # Snapshot parsing, validated state, file refresh
    QreeperMinimap.qml    # movable overlay
    QreeperAtlas.qml      # large view
    MapView.qml           # shared map rendering / interaction logic
    MapNode.qml           # room visuals, if genuinely useful
    QreeperTheme.qml      # feature-specific tokens if repo conventions warrant
    README.md
```

Component names and exact paths are **proposals**, not commands. Inspect actual tree and preserve its conventions. The controller should be hosted once in the shell, with a clear public API the bar can use. The bar should not own the state or construct the large windows on its own. Use lazy loading for heavier map surfaces if consistent with project conventions; keep the always-needed service lightweight. Avoid a second Quickshell process unless an evidenced Wayland restriction leaves no clean same-process alternative.

Check whether QREEP supports multiple monitors. Minimap should appear on the preferred/current output, and dragging, visibility and positioning should remain sensible if monitor geometry changes. The map should not reserve screen space; do not push or reflow regular windows.

## Exact bar interaction contract

- Left mouse button: toggle **minimap**, without opening the Atlas. A second left click hides it.
- Right mouse button: toggle/open **Atlas**, without being treated as left click or opening a context menu unintentionally. Use existing mouse event conventions. Decide and document if repeated right click closes Atlas; prefer toggle.
- Neither click should trigger MUD commands, alter Qreeper tracking, or forcibly focus Blightmud.
- Optional middle-click/scroll behavior only if consistent with the current bar; otherwise leave unbound.
- Distinct but subtle states for no snapshot, stale snapshot, invalid snapshot, and valid/live snapshot. No constantly animated polling indicator.
- Accessible tooltip/label, comfortable hit area, keyboard accessibility where the existing bar architecture provides it.
- No hardcoded icon-font assumption: follow QREEP's curated icons/assets/theme system; create an appropriate simple fallback icon if needed.
- User should be able to disable the bar entry using the existing configuration mechanism, if available, without breaking the service/window APIs.

## Floating minimap: required behavior

- A **real floating Wayland overlay**, not just a popup tethered to the bar. It should remain in place after the bar is hidden/collapsed. Above normal Blightmud windows, below system-critical surfaces. Ensure no unwanted full-screen input layer or reserved margins.
- Initial placement: unobtrusive upper-right (or user-respected existing QREEP placement convention), away from the bar; default reasonable size for an ultrawide display but scale appropriately on laptops.
- Movable by dragging a clear header/drag handle **without hijacking pan gestures inside the map**. Clamp to usable screen boundaries; use real monitor geometry. If current Quickshell/Wayland APIs prohibit direct movement, implement it by changing layer-shell anchors/margins/geometry based on pointer deltas and document constraints. Do not claim native window dragging works on layer-shell.
- Save position (and optional size/visibility) using QREEP's existing persisted settings/state approach; restore on restart with sane clamping. If per-monitor preferences are practical, support them; otherwise document fallback.
- Header shows current area and level, with compact close button and optional open-Atlas affordance. Current room prominent and visually different. Other room nodes and discovered passages remain readable.
- Support pointer interaction over the overlay, while clicks outside must pass normally to desktop/Blightmud. Minimap must not steal keyboard focus during routine updates.
- Zoom/pan either in minimap or just auto-centering; choose behavior that keeps the minimap genuinely glanceable. If user manually pans, offer an obvious recenter action. Default recenter around current room when movement happens, preferably smoothly but not with distracting animations.
- If no data or malformed data, show a compact waiting/error state; never crash QREEP. If Qreeper stops, keep last valid state marked stale rather than making rooms disappear immediately.


## Movement feedback, delayed camera follow and discovery (critical UX requirement)

The minimap must behave well during *fast repeated travel*, not just one command at a time. Example: user quickly sends `s, s, s, w, s, e, e, e`. Each confirmed room change should be represented immediately, while camera movement is deferred until the player pauses. **Separate the marker's current location from the camera's center** and also separate persistent map topology from transient rendering/view state.

### State ownership and confirmed movement

- Qreeper Lua (Step 2) determines whether an attempted movement succeeded, resolves the room ID, updates its graph, and publishes snapshots. **Never animate a move merely because the player typed a direction**, as a failed move or an ambiguous location may follow.
- The QREEP service processes increasing snapshot revisions. From successive snapshots, it derives a confirmed `currentRoomId` transition; if rooms/exits change, merge the new snapshot and refresh the view. Do not assume every revision is movement: a note edit or area rename may update the graph with the same current room.
- **Apply each valid new snapshot immediately** to the in-memory state. Highlight the new current room immediately, even while the camera is stationary. Rendering coalescing to one frame is acceptable; avoid blocking the QML main thread.
- Snapshots are the authoritative latest state, **not a guaranteed replayable movement-event stream**. A rapid sequence of atomic file replacements may be coalesced by the filesystem watcher or publisher. UI must remain correct if intermediate revisions are skipped: display the newest graph/room, do not invent intermediate steps. This first step does not promise that every fast move will have its own visible animation.

### Minimap camera follow: debounce plus safe framing

- Keep `currentRoomId`, marker position, `cameraTarget`, current viewport offset, and `lastMovementAt` (or equivalent) separate. Do not recalculate world coordinates relative to the current room or shift all rooms whenever it moves.
- Default **follow mode**: on a confirmed change of `currentRoomId`, immediately update the highlighted node; reset a single ~**700 ms** trailing-edge camera-follow delay. If another confirmed move arrives before the delay expires, defer recentering again. After a pause, animate the camera smoothly to the *latest* confirmed room, over approximately **250–350 ms** with a restrained easing curve. These durations are defaults and should be configurable internally or through existing QREEP settings where sensible, not magic constants spread across components.
- Do not queue one camera animation per move. When a newer move arrives, cancel/re-target the previous animation to the latest target. No stuttering/backlog after a rapid `s,s,s,w,s,e,e,e` sequence. QML Timer is appropriate for the debounce if supported; no busy polling.
- **Safe-margin rule**: if the current room approaches/leaves a defined inner safe rectangle (for example 20% inset) or would move fully outside the minimap, initiate an earlier restrained follow so the current position remains visible during longer fast movement. Avoid jerking on every step. The exact margin and tuning may be adapted after visual testing.
- **User pan/zoom override**: explicit manual panning suspends automatic follow, with a clear one-click recenter/resume-follow control. The Atlas has its own independent pan/zoom and should **never auto-recenter on routine movement**; it only updates the highlight and optionally offers a 'follow current room' toggle.
- Do not conflate **dragging the entire floating minimap window** (header handle) with **panning the map inside the minimap**. Minimap window position persists independently from map camera center. Camera animations must not move the window itself.
- If current room remains unchanged but graph/notes change, update visuals without forcing recenter or restarting a follow timer.
- Respect QREEP/Qt reduced-motion or animation settings, if present: instantly move camera on scheduled follow rather than animating, while retaining sensible highlight/follow behavior.

### Discovering and positioning a new room

- A newly observed room may arrive with a known position, an inferred position, conflicting placement, or **no usable position**. This is expected: 3Scapes contains repeated room names, irregular geography, named exits and possibly portals. Never identify rooms by name or guess positions in QML.
- **Placed, nonconflicting room**: create/update its node and real outgoing/incoming directed edges from the snapshot immediately. Optionally use a subtle node-appearance transition; keep existing nodes stationary. Highlight new current room immediately; camera follows after debounce unless the safe-margin rule intervenes.
- **Inferred but provisional position**: draw it as tentative (subtle dashed outline/soft visual cue) without implying certainty; retain IDs, notes and exits. The UI must not arbitrarily move already-placed nodes simply to accommodate a new room.
- **Spatial conflict**: preserve the graph edge in the model and expose it as irregular/conflicting (dashed/annotated edge or clearly labeled separate connection). Do not draw a convincing false cardinal connection. If a plausible preview position is necessary for a newly unplaced current room, treat it strictly as a **visual-only temporary placement**, visually marked as such, not a saved coordinate or graph fact.
- **Named exit or no coordinates** (e.g. `enter`, `out`, `tutorial`): keep a visible current-room card/node in a separate **unplaced/current-room cluster or fallback panel**, with the inbound named connection clearly identified if known. Do not extrapolate a compass direction or display the player at a previous room. The camera should focus the temporary/current-room panel when appropriate rather than trying to interpolate to nonexistent world coordinates. When a future snapshot provides a valid position, transition it to the mapped node sensibly.
- **Disconnected spatial components**: don't teleport nodes or recompute an unrelated cluster just because the player changed components. Make the new cluster visible using the same fallbacks, while preserving independent Atlas viewport state.
- **Unknown room identity**: if `currentRoomId` becomes `null`, retain the map, present location as unresolved, and suppress imaginary movement animation. Surface a compact unobtrusive status.
- For this step, fixture scenarios must include a newly discovered normally positioned room, a conflicting connection such as `22 northeast → 18`, a named-exit transition to an unplaced room, and return from the unplaced room. Test that UI never crashes and always shows the current room.

### JSON contract impact

The existing `schemaVersion: 1` **full snapshot** is sufficient for initial camera-follow behavior: `revision`, `currentRoomId`, room positioning, and exits identify the latest confirmed state. The UI may derive changes between revisions; **do not require a `movementDirection` field or unconfirmed client-side command events**. If the QREEP agent introduces an optional event or update metadata field (for UI storytelling), document it precisely and keep the base snapshot self-sufficient for cold starts, missed events and watcher coalescing. In the Step 2 prompt, insist that Lua publishes promptly after confirmed room observation and after relevant graph/metadata changes; publishing should be atomic and cheap.

### Additional acceptance tests

1. Simulate rapid confirmed transitions `11→12→22→19→20→19→12→16` within the follow-delay window. Marker changes promptly; camera follows the **last** room only after a pause, without accumulating animations.
2. During long uninterrupted movement that would push the marker offscreen, verify the safe-margin early-follow behavior keeps it visible without recentering at every step.
3. Simulate updates to notes or discovered exits with an unchanged `currentRoomId`; the map refreshes, but camera does not recenter.
4. Simulate a failed move/no new confirmed room: no marker motion from command intent alone.
5. Simulate adding a room with a newly valid coordinate and connection: node/edge appear promptly, current-room highlight works, previous nodes remain stable.
6. Simulate a newly current unplaced room reached via a named exit, and then return: location always visible in fallback view, no previous-room phantom highlight, no crashes.
7. Simulate watcher coalescing/skipped revisions: newest state wins and the camera ends at the latest current room; no false guarantee that every intermediate move is shown.
8. Verify minimap window dragging, internal map panning, and Atlas viewport remain independent of auto-follow; a user pan pauses follow until explicit recenter/resume.

## Large Atlas: required behavior

- Right-click bar icon opens a comfortably sized Atlas surface, not a second copy of the minimap.
- Shared state/model with minimap, but independent viewport controls (pan, zoom, selection, level choice); closing Atlas doesn't reset the minimap position, and vice versa.
- Show an overview of the connected graph, with highlighted current room and visual indication of notes. Inspect/select nodes to show room ID, name, realm/area/level, description if available, latest note, and exits (known/unknown).
- Display other floors explicitly with level switching (`+1`, `0`, `-1`) rather than blending overlapping floors. Coordinates are *relative visualization coordinates*, not necessarily authoritative in-game coordinates.
- Display named connections (`enter`, `out`, `tutorial`, portal names) as **semantic graph links** even without physical offsets. Do not invent compass positions for them.
- Show spatially irregular/conflicting connections distinctly (e.g. dashed edge/legend or dedicated connection list). Such connections must remain discoverable and usable by future navigation features. Never silently discard real edges just because they don't fit a grid.
- Display unknown exits with clear semantics: `unknown` means a known exit whose **destination is not yet observed**, not a room of uncertain identity. Avoid adding `?` to room IDs if it risks ambiguity; exit stubs/legend are preferable.
- No notes editing through QREEP in this step unless the repo already has a robust two-way command bridge. Reading and presenting notes is enough. No accidental stale state mutation.
- Include meaningful empty/loading/error states, graceful handling of disconnected clusters, cycles and repeated room names.

## Bridge: where data lives and how updates arrive

**Source of truth:** Qreeper's SQLite database (managed only by the Blightmud Lua plugin), currently at:

`~/.local/share/blightmud/qreeper/worlds/3scapes.sqlite`

**Recommended public interface:** a complete, versioned, read-only JSON snapshot published separately by Qreeper, at:

`~/.local/state/qreeper/map.json`

QREEP may read the JSON path but must not write to it. It should not need to read SQLite at all. The location is a **proposed contract**, to be adopted by Step 2. Support a configurable/overridable path or XDG state directory where consistent with existing project conventions, but keep the default simple and document it.

For Step 1, build a **fixture JSON file** and a documented way to use it. QREEP should be fully demoable before the Lua publisher exists. Prefer a file watcher using proven Quickshell APIs with safe reload; if atomic rename is not detected by the chosen watcher, implement a reliable re-arm / directory watcher or a low-frequency fallback, or explicitly use another tested mechanism. Avoid tight polling. Debounce duplicate events and never parse partial writes as stable state.

An atomic file-replacement publisher is planned: write temp file in same directory, flush/close, rename over `map.json`. Validate what QREEP actually receives on file replacement; don't assume watching an inode always follows renames. The consumer should read the latest whole file, validate it, and update UI atomically. Keep the previous valid snapshot when a later load fails.

### Proposed JSON contract, version 1

This is the authoritative interface to implement and document, subject to clearly recorded minor refinements that Step 2 can adopt. Prefer **arrays** of objects rather than ID-keyed JSON dictionaries so both Lua and QML handle IDs consistently.

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
      "notes": [
        {"id": 8, "text": "Thieves here", "createdAt": "2026-10-12T09:00:00Z"}
      ]
    },
    {
      "id": 18,
      "name": "Newbie Tower: Forest",
      "description": null,
      "realm": "Newbieland",
      "area": "Newbie Tower: Forest",
      "level": 0,
      "x": 1,
      "y": 1,
      "z": 0,
      "positionStatus": "inferred",
      "notes": []
    }
  ],
  "exits": [
    {
      "from": 22,
      "direction": "northeast",
      "to": 18,
      "geometry": "irregular"
    },
    {
      "from": 22,
      "direction": "north",
      "to": null,
      "geometry": "unknown"
    }
  ],
  "layout": {
    "anchorRoomId": 11,
    "coordinateSystem": "east+x,south+y,up+z"
  }
}
```

**Schema rules:**

- `schemaVersion` must be checked; unsupported versions show a clear, noncrashing error.
- `world` distinguishes future MUDs/world databases.
- `revision` should increase when the publisher emits changed state; stale/replayed revisions should not disrupt the UI. `publishedAt` is informational, not a trust mechanism.
- `currentRoomId` can be `null` (before a room is recognized), and might reference a known but **unplaced** room.
- Room IDs and note IDs are integers, **not unique room-name strings** (the forest contains several rooms with identical names).
- `description`, `realm`, `area`, `level`, `x`, `y`, `z` can be absent/null; unknown is not zero. The absolute `level` of a room and the relative layout `z` must not be silently conflated.
- `positionStatus` should be `inferred`, `fixed`, or `unplaced`; do not interpret inferred coordinates as verified geography.
- Exits are **directed**. Having `22 → 18` does not imply `18 → 22`. `to: null` means unexplored. Keep named directions and store a `geometry` classification such as `regular`, `irregular`, `named`, `unknown`, or `unplaced` (adapt values with clear documentation if warranted).
- Geometry classification is a visualization aid. Route/navigation decisions must use graph edges, not on-screen proximity.
- `notes` are optional on rooms; map should show a note indicator and latest note preview, Atlas should display full provided notes; do not fabricate metadata.
- Coordinates may collide or be inconsistent: UI must handle this without losing rooms or falsely drawing a connector. A separate unplaced/irregular list or cluster view is acceptable as needed.
- Snapshot should be treated as untrusted local input: validate types, clamp extreme coordinates and sizes, limit resource usage, handle malformed JSON and missing fields gracefully; never evaluate dynamic script content from JSON.
- If you refine this contract, document **exact final fixture schema and why**, so the Qreeper Step 2 agent can implement a matching producer with no guesswork.

### Model and rendering responsibilities

Use a lightweight, explicit in-memory model derived from the snapshot:

- `QreeperService` (or equivalent) owns snapshot reading, validation, indexes by room ID, load state, current room selection, revision, and signals/properties consumed by both views.
- Rendering is done with suitable QML/Qt Quick technology; compare Canvas, Shape, and reusable Items against graph size, hit-testing, theme consistency and animations. Use the simplest reliable choice. Avoid building custom JS layout algorithms unnecessarily if the snapshot already includes positions.
- The view transforms `(x,y,z)` to pixels, supports zoom/pan without writing coordinates back, filters by layer, and draws **only edges backed by snapshot records**.
- Never draw an apparent solid spatial connection where the recorded edge contradicts its spatial placement. Preserve named/conflicting edges visibly or in an accessible connection list.
- Reuse QREEP theme palette, scaling and UI primitives. Current room distinctly highlighted; note nodes legible, not noisy; colors must survive theme changes.
- Minimap and Atlas should not independently parse the JSON or hold divergent copies of the graph.
- Movement should update the highlighted room promptly when `currentRoomId` changes, without rebuilding everything unnecessarily. For small graphs, simple redraw is okay, but avoid pathological quadratic work for larger worlds.

### Integration and IPC

- Use QREEP's existing IPC and feature-controller conventions where appropriate. Useful public API: `toggleMinimap`, `showMinimap`, `hideMinimap`, `toggleAtlas`, `showAtlas`, `hideAtlas`, `refresh`, `recenter`. Expose only what is needed.
- Bar click actions should invoke the in-process feature API, not spawn shell commands.
- Allow optional IPC calls for keybindings/automation, reusing QREEP patterns.
- Don't introduce a background daemon, TCP server or Unix socket for Step 1. The JSON bridge is sufficient and easiest to debug. If a more reliable existing QREEP mechanism is found, compare and justify it before deviating.
- If bar can be collapsed/hidden, the minimap and atlas must still be functional and their controller should not disappear with bar UI lifecycle.

## Development fixture and tests

Build a realistic fixture containing **at least**:

- rooms 11, 12, 16, 17, 18, 19, 20, 21, 22 with repeated name `Newbie Tower: Forest`;
- a normal set of cardinal and diagonal room connections;
- a known irregular connection `22 northeast → 18` that does not fit the inferred coordinate grid;
- one unknown exit (`to: null`), and a named exit (`enter` / `out`);
- a note on room 22 (`Thieves here`) and another note on room 18;
- two floors, and at least one room with unknown/unplaced position;
- a distinct `currentRoomId` which can be changed to simulate movement.

Provide a convenient documented method to copy/write the fixture to the configured state path, and a second version with changed `currentRoomId`, so a developer can see both views update without Blightmud. Don't overwrite real user data during tests without explicit instruction. Fixture must not be committed to the live state path as a production default.

### Acceptance tests (actually run where feasible)

1. QREEP starts with **no snapshot**; bar stays functional and minimap/atlas show a useful waiting state.
2. Snapshot appears after QREEP is running; watcher detects it and current room appears.
3. Snapshot is **atomically replaced**, not simply edited in place; watcher still receives future updates and never gets stuck on old inode.
4. Current room ID changes 22→18→12; highlight changes without rearranging the underlying map; minimap recenters as designed; Atlas retains its viewport.
5. Left click opens/closes minimap, and right click opens/closes Atlas; neither triggers the other. Test with bar expanded, collapsed or overlay where supported.
6. Minimap dragging is smooth, doesn't drag map unintentionally, stays on-screen and restores after restart/monitor change as feasible. Clicking outside overlay still reaches Blightmud.
7. Notes are readable in Atlas; nodes show an unobtrusive indicator; room with repeated name is selected by **ID**.
8. Unknown exit, named exit, and `22 northeast → 18` irregular edge are all accessible; none silently becomes a fake regular compass connection.
9. Missing/malformed/unsupported JSON and a stale snapshot show graceful states, leave QREEP alive, and preserve last good data where appropriate.
10. Performance remains acceptable with a synthetic large graph; add reasonable limits if needed.
11. Theme toggling and scaling behave reasonably; current-room coloring remains distinguishable.
12. No regression to existing QREEP bar modules or other windows; run repository checks, QML tooling and relevant smoke tests. If GUI validation can't run in agent environment, say so and give exact manual commands.

## Documentation and final report

- Add a concise module README with user behavior, bar clicks, IPC (if provided), JSON schema, data path, supported Quickshell versions/API assumptions, manual fixture test, and limitations.
- Keep root documentation changes appropriate to QREEP's conventions and follow AGENTS.md synchronization requirements where triggered.
- Explain feature ownership, what remains deferred to Qreeper Step 2, and any deliberate compromises (especially Wayland draggable overlay semantics and watcher/atomic replacement behavior).
- Final report: list changed files, implementation decisions, verified tests with results, manual test instructions, and exact agreed final JSON contract.
- Keep unrelated code unchanged, no unnecessary dependencies or refactors.

## Out of scope: reserved for Step 2 (Qreeper Lua plugin)

Do **not** edit the Qreeper plugin in this step. Step 2 will implement the producer that:

1. derives a validated map snapshot from Qreeper SQLite, memory and its stable layout;
2. includes room metadata, notes, directed exits, geometry classifications and current-room ID;
3. atomically writes the agreed versioned JSON to the agreed path;
4. publishes after successful room observation, movement connection changes, notes/geography changes, and on plugin initialization as appropriate;
5. avoids publishing false movement/room identities and handles named exits/failures conservatively;
6. remains fully functional with QREEP turned off.

Step 1's most important deliverable is a **working, testable QREEP feature with a documented input contract**. Don't build the Lua publisher or assume it already exists.
