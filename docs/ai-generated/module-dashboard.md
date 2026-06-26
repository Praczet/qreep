# Dashboard Module Plan

## Purpose

Build a Qreep dashboard: a full-screen-ish Quickshell overlay for glanceable desktop state, small actions, and personal workflow widgets.

This should be inspired by the AGS dashboard at:

```text
/home/adam/Development/Hyprland/ags-hyprland/packages/dashboard
```

It should not be a direct port. That package is TypeScript/AGS/GTK with a widget registry, CSS animation classes, Google/TickTick/weather services, sticky notes, custom JavaScript widgets, and Aegis integration. Qreep is QML. Dragging all of that across at once would be less a migration and more a paperwork incident.

The Qreep version should start as a useful native surface and grow in slices.

## Source Analysis

The AGS dashboard is built around these parts:

- `src/windows/Dashboard.tsx`: overlay window, grid layout, widget wrappers, open/close API, Escape close, staged widget animations.
- `src/config.ts`: JSON-backed dashboard config loaded from `~/.config/ags/dashboard.json`.
- `src/windows/widgetRegistry.tsx`: maps widget `type` values to widget factories.
- `src/widgets/*`: clock, analog clock, calendar, next event, tasks, TickTick, weather, sticky notes, word of the day, custom widgets, Aegis widgets.
- `src/services/*`: Google Calendar/Tasks, TickTick, weather, markdown rendering, auth state, HTTP helpers.
- `src/styles.css`: dashboard overlay background, widget cards, card toggles, grid spacing, entry/exit animation classes.

Important behavior worth keeping:

- Dashboard is an overlay layer surface.
- It opens and closes through an external command/request.
- Escape closes it.
- Widgets are configured as separate cards/blocks with type, size, chrome, and animation direction.
- The AGS version uses a grid because GTK made the organic layout painful. That was a compromise, not a sacred text.
- Widget chrome is configurable: background, border, shadow/title.
- Widgets animate in from different directions.
- Services refresh only when needed, or on a timer when justified.
- External integrations show useful auth/error states instead of quietly becoming empty rectangles. Bold strategy, working software.

Important behavior to avoid copying immediately:

- Custom JS widget loading.
- Google OAuth.
- TickTick OAuth.
- Weather particle animations.
- Markdown parser complexity.
- A generic framework before there are enough native widgets to justify one.

## Qreep Direction

Dashboard should be a top-level module:

```text
modules/dashboard/
├── Dashboard.qml
├── DashboardPanel.qml
├── DashboardService.qml
├── DashboardTheme.qml
├── DashboardWidgetFrame.qml
├── widgets/
│   ├── DashboardClock.qml
│   ├── DashboardCalendar.qml
│   ├── DashboardAgenda.qml
│   ├── DashboardBorg.qml
│   ├── DashboardMpris.qml
│   ├── DashboardUpchecker.qml
│   └── DashboardSystem.qml
└── README.md
```

Why top-level:

- It is a shell surface, not a bar pill.
- It should be hosted from `shell.qml`, like `modules/osd/`.
- The bar may get a dashboard button later, but the bar should not own the panel.
- IPC/shortcuts should work even if no bar button exists.

Expected `shell.qml` shape:

```qml
DashboardModule.Dashboard {
    id: dashboard
    theme: qreepTheme
}
```

Expected public API:

```qml
property bool open: false
function show(): void
function hide(): void
function toggle(): void
function refresh(): void
```

Expected IPC names:

```bash
quickshell ipc call qreep-dashboard toggle
quickshell ipc call qreep-dashboard show
quickshell ipc call qreep-dashboard hide
quickshell ipc call qreep-dashboard refresh
```

Keep these names boring. Future Adam has better uses for memory than remembering a dashboard command called `summon-overview`.

## First Useful Version

The first Qreep dashboard should prove the surface and configurable block system before it tries to become useful in every possible direction.

Version 0 should include:

- a full-screen transparent overlay panel;
- blurred/dimmed background through Hyprland layer rules where possible;
- theme-controlled overlay opacity;
- a configurable list of fake dashboard elements/cards;
- per-card title or titleless mode;
- per-card size;
- per-card position;
- per-card preset/config object;
- per-card animation source/target;
- Escape closes;
- outside click closes, if the click is outside an interactive card;
- IPC toggle/show/hide/refresh;
- feature-local theme tokens;
- a `DashboardCard.qml` wrapper;
- enough fake blocks to prove layout, sizing, animation, and theme behavior.

The first real widgets can come after the block system works. Suggested early real widgets:

- clock/date widget, using local time;
- calendar/agenda widget reusing `events.json` through a dashboard-owned or shared event store;
- Borg status widget using the existing Borg service behavior or a small dashboard-specific read-only service;
- Upchecker summary widget showing update count and restart status;
- MPRIS summary widget showing current track/player;
- system summary widget with uptime/load/memory/disk, if this can be implemented locally without inventing Aegis first.

Do not start with Google, TickTick, or weather. They are useful later, but the first dashboard should prove the panel, freeform block layout, animation model, service ownership, and visual language first.

## Visual Design

Dashboard should feel related to the existing Qreep surfaces:

- use `theme.overlaySurfaceBackground` and `theme.overlaySurfaceBorder` for main surfaces where appropriate;
- use feature-local dashboard tokens for card radius, padding, animation duration, default card size, and placement bounds;
- keep the overlay dim subtle;
- do not make a fake landing page;
- avoid decorative filler;
- prioritize scannable information.

Suggested theme entry:

```qml
readonly property QtObject dashboard: DashboardFeature.DashboardTheme {
    backgroundColor: rootQreepTheme.overlaySurfaceBackground
    borderColor: rootQreepTheme.overlaySurfaceBorder
}
```

Suggested `DashboardTheme.qml` tokens:

```qml
property color backgroundColor: "#242933"
property color borderColor: "#3b4252"
readonly property real overlayOpacity: 0.35
readonly property int panelPadding: 24
readonly property int defaultCardGap: 16
readonly property int cardPadding: 20
readonly property int cardRadius: 18
readonly property int cardBorderWidth: 1
readonly property int animationDuration: 220
readonly property int defaultCardWidth: 320
readonly property int defaultCardHeight: 180
readonly property int placementMargin: 24
```

The AGS dashboard uses card toggles like `showBackground`, `showBorder`, and `showShadow`. Qreep should support `showBackground` and `showBorder` eventually. Shadows can wait. Quickshell layer surfaces already have enough ways to become visually weird.

## Block Layout Model

AGS uses JSON:

```json
{
  "layout": { "columns": 6, "gap": 16, "padding": 24 },
  "widgets": [
    { "id": "clock", "type": "clock", "col": 1, "row": 1, "colSpan": 2, "rowSpan": 1 }
  ]
}
```

That grid was a compromise. Qreep should not inherit it as a personality trait.

Qreep should use a block layout model. A block is a dashboard feature instance: clock, weather, note, Aegis system card, Potato chart, fake test block, whatever earns its rectangle.

The config should describe:

- what block to use;
- where it should sit;
- how large it should be;
- whether it has title/background/border;
- which preset/config it uses;
- how it animates in and out.

This should feel closer to placing cards on a canvas than filling a spreadsheet.

Recommended progression:

1. JSON config from the start, but with fake blocks only.
2. `DashboardService.qml` loads and validates block config.
3. `DashboardPanel.qml` renders positioned cards.
4. Real block components replace fake blocks one by one.
5. Registry-like model only after multiple blocks repeat the same shape.

QML-friendly widget model shape:

```qml
[
    {
        "id": "clock",
        "type": "clock",
        "title": "Clock",
        "showTitle": false,
        "anchorPoint": "top-left",
        "dx": 64,
        "dy": 64,
        "width": 360,
        "height": 180,
        "preset": "large",
        "from": "top",
        "to": "center",
        "showBackground": true,
        "showBorder": true,
        "config": {}
    }
]
```

Placement should prefer anchor-relative offsets so layouts can describe intent without caring whether the monitor is sensible or absurd:

```json
{
  "anchorPoint": "middle-center",
  "dx": -220,
  "dy": 72,
  "width": 420,
  "height": 220
}
```

Supported anchors: `top-left`, `top-center`, `top-right`, `middle-left`, `middle-center`, `middle-right`, `bottom-left`, `bottom-center`, and `bottom-right`. Legacy `x`/`y` can stay as fallback during the draft. Do not start with flexbox, constraint solving, or a layout engine that wants a LinkedIn profile. A simple canvas with cards is enough for v0.

## Live AGS Config Notes

The live AGS config at:

```text
/home/adam/.config/ags/dashboard.json
```

currently uses:

- Google calendars and tasks;
- weather for Bergem, Luxembourg;
- sticky notes;
- clock;
- weather;
- word of the day;
- analog clock;
- Google calendar;
- three custom Potato SVG widgets for weight, steps, and fasting.

The custom widget folder:

```text
/home/adam/.config/ags/dashboard-widgets
```

contains:

- `potato-svg.js`: renders an SVG from `~/.cache/potato/*.svg` with explicit width/height and a controlled scroller/viewport.
- `my-widget.js`: tiny test widget.

The important lesson is not "Qreep needs custom JavaScript widgets." It is that Adam wants cards with controlled dimensions and content presets. Potato charts are a good example: they are not normal grid cells; they are visual blocks that need deliberate size and placement.

Qreep should model this as native block presets:

```json
{
  "id": "potato-weight",
  "type": "image",
  "title": "POTATO / Weight",
  "showTitle": false,
  "showBackground": false,
  "showBorder": false,
  "anchorPoint": "top-right",
  "dx": -80,
  "dy": 80,
  "width": 800,
  "height": 307,
  "from": "right",
  "config": {
    "source": "~/.cache/potato/weight.svg",
    "fit": "contain"
  }
}
```

That gives the dashboard the useful part of custom widgets without turning Qreep into a JavaScript hostel.

## Service Model

`Dashboard.qml` should be the controller:

- owns `DashboardService`;
- owns the lazy panel loader;
- exposes public methods;
- owns IPC.

`DashboardPanel.qml` should be visual:

- no command execution;
- no auth logic;
- no direct subprocesses;
- receives service/theme/model data;
- handles Escape/outside click;
- emits user actions upward where needed.
- positions block cards according to resolved config.

`DashboardService.qml` should own:

- block model;
- config loading and validation;
- refresh fan-out;
- simple local data collection;
- default fake block config.

Do not reuse bar service instances directly unless they are moved into `core/` or exposed through an intentional shared API. Reaching sideways into `modules/bar/features/*` from `modules/dashboard` should be treated as suspicious. Importing a bar feature from a top-level dashboard is how ownership starts wearing a fake moustache.

Better options:

- promote genuinely shared services to `core/`;
- keep dashboard widgets read-only and duplicate tiny command wrappers temporarily;
- later extract common state once two or three modules need it.

## Widget Candidates

### Clock

First-class v0 widget.

Behavior:

- show time and date;
- optional seconds;
- use QML `Timer`;
- no external service.

### Calendar / Agenda

Good v0 or v0.1 widget.

Behavior:

- show current month or six-day agenda;
- reuse the existing event JSON shape from `events.json`;
- show event markers and upcoming events.

Implementation note:

- Existing `modules/bar/features/clock/EventStore.qml` is bar-owned today.
- For dashboard, either duplicate a minimal event store first or move the event store to `core/EventStore.qml` in a separate refactor.
- Do not move it while also building the whole dashboard. That is how a planned module becomes a pile of unrelated diffs wearing a coat.

### Borg

Good v0.1 widget.

Behavior:

- show current backup status;
- allow refresh;
- maybe allow run backup later, but not first.

Implementation note:

- Existing Borg service is bar-owned.
- Prefer a read-only dashboard status initially or extract shared Borg service to `core/` in its own unit.

### Upchecker

Good v0.1 widget.

Behavior:

- show update count/status;
- show restart status;
- open the existing Upchecker panel or refresh updates later.

Implementation note:

- Do not make Dashboard own Upchecker.
- If Dashboard needs actions, use IPC between features or promote shared update state later.

### MPRIS

Good v0.1 widget.

Behavior:

- show current player, title, artist, album;
- show play/pause/next/previous if easy;
- no album-art-heavy layout in the first version unless it is already stable.

### Aegis / System

Good v0.2+ widget.

Behavior:

- system overview;
- memory/disk/network/battery;
- maybe CPU graph.

Implementation note:

- The AGS dashboard imports Aegis widgets directly from another package.
- Qreep should either build a small native `DashboardSystem.qml` first or create `modules/aegis/` as its own top-level module later.
- If Aegis gets its own identity, do not bury it inside Dashboard.

### Weather

Later.

Behavior:

- Open-Meteo current weather and optional forecast.

Implementation note:

- Quickshell/QML can call external helpers or use process-based fetches, but network services need error states and refresh control.
- Do not put network fetch complexity in the first dashboard version.

### Tasks / TickTick / Google

Later.

Behavior:

- Google Calendar/Tasks and TickTick are useful, but they bring auth, tokens, refresh timers, and error states.

Implementation note:

- Build dashboard structure first.
- Add local/static tasks before OAuth-backed tasks.
- If OAuth returns, use helper scripts or a small separate service. Do not teach QML to become an OAuth client unless there is no adult alternative.

### Sticky Notes

Later, but promising.

Behavior:

- read selected markdown/plaintext notes;
- render compact note cards;
- open note in editor.

Implementation note:

- This is a better early external-data widget than Google/TickTick because it can be local-file based.
- Markdown rendering should start plain. Rich markdown can wait until the plain version proves useful.

### Custom Widgets

No for v0 as arbitrary JavaScript.

The AGS dashboard supports custom JS widgets. Qreep should not. If Qreep eventually needs custom dashboard widgets, prefer QML components in a known folder over arbitrary dynamic JavaScript loading.

For v0, support fake/test blocks and maybe an image block. Image blocks cover the current Potato SVG use case better than generic custom code.

## Implementation Roadmap

### Phase 0 - Dashboard Skeleton

Files:

```text
modules/dashboard/Dashboard.qml
modules/dashboard/DashboardPanel.qml
modules/dashboard/DashboardService.qml
modules/dashboard/DashboardTheme.qml
modules/dashboard/DashboardCard.qml
modules/dashboard/README.md
```

Work:

- add `modules/dashboard/`;
- add theme import to `theme/QreepTheme.qml`;
- host `Dashboard.qml` from `shell.qml`;
- add IPC target `qreep-dashboard`;
- add `Scope + LazyLoader`;
- create full-screen overlay `PanelWindow`;
- use Hyprland layer namespace `qreep-dashboard`;
- Escape closes;
- outside click closes;
- load a small JSON-like fake block model from `DashboardService`;
- render several positioned fake cards;
- support title/titleless, width, height, `anchorPoint`/`dx`/`dy`, legacy x/y fallback, background, border, and animation direction.

Validation:

```bash
qmllint shell.qml theme/QreepTheme.qml modules/dashboard/*.qml
quickshell -c qreep --no-duplicate
```

### Phase 1 - First Real Widgets

Work:

- add `DashboardCard.qml`;
- add `DashboardClock.qml`;
- add `DashboardImage.qml` for Potato-style SVG/image blocks;
- add `DashboardAgenda.qml` using copied/minimal event loading if the event-store extraction has not happened yet.

Definition of done:

- dashboard opens from IPC;
- Escape closes;
- click outside closes;
- clock updates;
- fake/image blocks respect configured size and position;
- animation direction works per block;
- no dependency on AGS files.

### Phase 2 - Config File and Block Model

Work:

- load dashboard config from a real file;
- support model-driven block creation;
- support `anchorPoint`, `dx`, `dy`, `width`, `height`;
- keep `x`/`y` as a legacy top-left fallback during the draft;
- support `preset`;
- support `from` and later `to`;
- support `showTitle`, `showBackground`, `showBorder`.

Implementation options:

- use `Repeater` plus `Loader` delegates;
- map widget types explicitly in QML;
- keep unknown widget type as an error card.

Do not build a plugin framework here. It will whisper. Ignore it.

### Phase 3 - Qreep-Native Status Widgets

Work:

- add Borg summary;
- add Upchecker summary;
- add MPRIS summary;
- decide whether shared services move to `core/`.

Rule:

- each service extraction is a separate unit refactor;
- no moving Borg, Upchecker, MPRIS, and event store in the same commit.

### Phase 4 - Optional Config File

Possible path:

```text
~/.config/quickshell/qreep/dashboard.json
```

or repo-local during development:

```text
dashboard.json
```

Work:

- load JSON with `FileView`;
- validate fields defensively;
- fall back to default layout on missing/invalid config;
- log bad config through `core/Log.qml`.

Suggested config:

```json
{
  "overlay": {
    "opacity": 0.35,
    "blur": true
  },
  "blocks": [
    {
      "id": "clock",
      "type": "clock",
      "anchorPoint": "top-left",
      "dx": 64,
      "dy": 64,
      "width": 360,
      "height": 180,
      "from": "top",
      "showTitle": false
    }
  ]
}
```

### Phase 5 - Larger Integrations

Candidates:

- Aegis/system module;
- sticky notes;
- weather;
- tasks;
- Google/TickTick.

Rule:

- each external integration gets its own service and failure UI;
- no token logging;
- no persistence beyond the existing backend behavior unless explicitly requested;
- no network polling without a theme/config refresh interval.

## Suggested First Commit Split

If this becomes code, use unit commits:

```text
docs(dashboard): plan qreep dashboard module
feat(dashboard): add dashboard controller and empty panel
feat(dashboard): add dashboard clock and agenda widgets
refactor(events): extract shared event store
feat(dashboard): add model-driven widget layout
feat(dashboard): add qreep status widgets
```

Do not combine the planning doc, event-store extraction, dashboard skeleton, and three widgets into one commit. That is not a commit. That is a suitcase with a license plate.

## Open Questions

- Should the first dashboard be named `Dashboard` or `Aegis`?
- Should there be a bar button in the first version, or IPC only?
- Should block layout be hardcoded until useful, or should JSON config start immediately?
- Should `events.json` move to `core/` now, or should Dashboard duplicate a small event reader first?
- Should Dashboard start as one freeform canvas, or should it support named zones later?
- Should the dashboard replace any existing popups, or only summarize them?

Recommended answers for v0:

- use `Dashboard`, not `Aegis`;
- IPC first, bar button later;
- JSON config with fake blocks first;
- duplicate minimal event loading first or postpone agenda until an event-store extraction;
- one freeform canvas;
- summarize existing features, do not replace them.

## Risks

- Importing bar feature services into a top-level dashboard would blur ownership.
- Starting with OAuth/network widgets will delay the actual dashboard surface.
- Dynamic custom widgets invite complexity before Qreep has a stable native widget shape.
- A block layout model can become a framework if built beyond the first practical positioning needs.
- Heavy widgets should not be created at shell startup. Use `Scope + LazyLoader`.

## Validation Plan

For docs-only work:

```bash
git diff -- docs/ai-generated/module-dashboard.md
```

For the first implementation:

```bash
qmllint shell.qml theme/QreepTheme.qml modules/dashboard/*.qml
quickshell -c qreep --no-duplicate
quickshell ipc call qreep-dashboard toggle
quickshell ipc call qreep-dashboard hide
```

Manual checks:

- opens on the correct monitor or acceptable default monitor;
- closes with Escape;
- closes on outside click;
- does not block the bar after closing;
- does not create dashboard windows at startup unless needed;
- reload does not duplicate IPC targets;
- theme colors match Power/Upchecker overlay surfaces.

## Module Summarry info

`Dashboard` should be a top-level Qreep module hosted by `shell.qml`. It should behave as a lazy full-screen overlay opened by IPC, closed by Escape or outside click, with theme-controlled transparency and Hyprland-managed blur. The first version should load a config of fake/freeform blocks, where each block controls title visibility, size, position, card chrome, preset/config, and animation direction. Later those blocks become real dashboard features; `Aegis` can then be a dashboard preset or sibling module focused on system information. Do the block canvas first. The widgets can stand in line like everyone else.
