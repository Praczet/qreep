# AGENTS.md

## Project identity

This repository is **Qreep**: a small Quickshell learning project that starts as a Waybar-like bar and may later grow into dashboard/popup/widget territory if nobody stops Adam in time.

Qreep is not trying to become a desktop environment, a framework, or a cathedral made of QML. It is a practical experiment: learn Quickshell, build useful pieces, keep the project understandable, and avoid turning every module into a mythological subsystem.

Current expected structure:

```text
qreep/
├── shell.qml
├── core/
├── components/
├── modules/
│   ├── bar/
│   ├── aegis/
│   ├── bloom/
│   ├── clipboard/
│   ├── dashboard/
│   ├── expose/
│   ├── notification/
│   └── osd/
├── scripts/
├── theme/
└── events.json
```

Keep this structure boring. The name is weird enough.

Current direction:

```text
bar first, useful modules second, larger surfaces only when they earn the rent
```

Qreep is moving from "a bar that owns everything" toward "a bar that hosts small controls and routes into feature-owned surfaces." The bar should remain the daily visible shell piece. Larger things such as update panels, power panels, dashboards, wallpaper selection, and clipboard history should become feature-owned controllers/surfaces instead of turning `Bar.qml` into a storage unit with imports.

Top-level modules are allowed when the feature is not naturally owned by the bar. `modules/osd/` is the current example: it is a shell-level surface with IPC, so `shell.qml` hosts it directly and the bar does not pretend to be its parent just because the bar exists.

## Voice and documentation style

Use Adam's preferred tone:

- dry, practical, slightly sarcastic;
- helpful, not motivational-poster-shaped;
- clear enough for future tired Adam;
- honest about uncertainty;
- no corporate foam;
- no exaggerated praise like “excellent question”;
- no fake enthusiasm, no “magic”, no “seamless developer experience” unless mocking it.

Documentation may be witty, but it must remain useful. The joke is allowed to sit in the corner; it must not drive the architecture.

When writing project documentation:

- prefer short sections with concrete commands;
- explain why a command is used, especially system commands;
- use comments that help future maintenance, not comments that narrate the obvious;
- if using callouts, every callout must have a title;
- preserve Adam's voice in notes/reflections instead of polishing everything into generic README soup.

Good tone:

```text
This module is deliberately boring. That is a feature, not a cry for help.
```

Bad tone:

```text
This amazing module empowers a delightful shell experience.
```

No. Absolutely not. Put it back.

## General agent rules

Before changing files:

1. Read `AGENTS.md`.
2. Inspect the relevant files.
3. Check the current tree and existing naming conventions.
4. Prefer the smallest change that solves the requested problem.
5. Do not invent architecture before there is pain that deserves architecture.

When working:

- keep edits focused;
- do not rewrite unrelated code;
- do not rename files casually;
- do not reformat entire files unless asked;
- do not silently change behavior outside the task;
- prefer boring, explicit code over clever QML origami;
- make assumptions visible when they matter;
- if something is uncertain, say so and leave a clear TODO or note.

If Adam asks for a plan, provide a useful plan. If Adam asks for code, provide code.

If Adam asks for both, do not spend three pages admiring the plan while the code dies of loneliness.

## Documentation refresh and synchronization ledger

When Adam asks to refresh or synchronize `README.md` files and `AGENTS.md`:

1. Read `AGENTS.md` first, because apparently this file is load-bearing now.
2. Inspect the current source tree and the module entry points before editing docs.
3. Keep root `README.md` short. It is for people who want "what is this, how do I start, where do I look next" and then would like to leave.
4. Keep the longer root project map in `README_when_bored.md`. Put inventories, detailed IPC lists, layer-rule notes, theme maps, and other "future Adam has time today" material there.
5. Do not merge the short README and the bored README back into one hydra-shaped document during a routine docs refresh. If both need updates, update both for their different jobs.
6. Update every stale module README that exists for the touched/current modules.
7. Add missing module READMEs when the code has grown a real feature surface and the absence of docs is now just laziness wearing a hat.
8. Update this synchronization ledger in the same change.
9. If Adam explicitly asks for memory too, add a small ad-hoc memory note under `/home/adam/.codex/memories/extensions/ad_hoc/notes/`; do not edit generated memory registry files directly.

The hash below is the repo commit the docs were synchronized against. If docs are edited before a commit exists for the docs themselves, use current `HEAD` and the refresh date. Future Adam can survive this.

| File | Synced against | Sync date |
| --- | --- | --- |
| `AGENTS.md` | `dcf825d` | `2026-07-09` |
| `README.md` | `dcf825d` | `2026-07-09` |
| `README_when_bored.md` | `dcf825d` | `2026-07-09` |
| `modules/aegis/README.md` | `1a769ca` | `2026-07-08` |
| `modules/bar/features/battery/README.md` | `1a769ca` | `2026-07-08` |
| `modules/bar/features/borg/README.md` | `1a769ca` | `2026-07-08` |
| `modules/bar/features/clock/README.md` | `dcf825d` | `2026-07-09` |
| `modules/bar/features/launcher/README.md` | `1a769ca` | `2026-07-08` |
| `modules/bar/features/monitorprofile/README.md` | `1a769ca` | `2026-07-08` |
| `modules/bar/features/mpris/README.md` | `1a769ca` | `2026-07-08` |
| `modules/bar/features/network/README.md` | `1a769ca` | `2026-07-08` |
| `modules/bar/features/power/README.md` | `1a769ca` | `2026-07-08` |
| `modules/bar/features/upchecker/README.md` | `1a769ca` | `2026-07-08` |
| `modules/bar/features/volume/README.md` | `1a769ca` | `2026-07-08` |
| `modules/bar/features/workspaces/README.md` | `1a769ca` | `2026-07-08` |
| `modules/bloom/README.md` | `1a769ca` | `2026-07-08` |
| `modules/clipboard/README.md` | `1a769ca` | `2026-07-08` |
| `modules/dashboard/README.md` | `1a769ca` | `2026-07-08` |
| `modules/dashboard/features/clock/README.md` | `1a769ca` | `2026-07-08` |
| `modules/dashboard/features/image/README.md` | `1a769ca` | `2026-07-08` |
| `modules/dashboard/features/weather/README.md` | `1a769ca` | `2026-07-08` |
| `modules/dashboard/features/wotd/README.md` | `1a769ca` | `2026-07-08` |
| `modules/expose/README.md` | `dcf825d` | `2026-07-09` |
| `modules/notification/README.md` | `1a769ca` | `2026-07-08` |
| `modules/osd/README.md` | `1a769ca` | `2026-07-08` |

## Quickshell / QML rules

Qreep is a Quickshell project. Prefer QML-first solutions unless there is a good reason not to.

Use this project layout:

- `modules/` for top-level Qreep modules (for example: `bar`, `clipboard`, `dashboard`);
- `modules/bar/features/` for bar-owned pills, panels, services, and popups;
- `modules/osd/` for the shell-level OSD surface and IPC service;
- `components/` for reusable UI pieces;
- `theme/` for the public theme object, shared theme sections, and generated colors;
- `core/` for truly shared services/state once they actually exist.

Current bar feature folders:

```text
modules/bar/features/
├── battery/
├── borg/
├── clock/
├── launcher/
├── monitorprofile/
├── mpris/
├── network/
├── power/
├── upchecker/
├── volume/
└── workspaces/
```

Current top-level module folders:

```text
modules/
├── aegis/
├── bar/
├── bloom/
├── clipboard/
├── dashboard/
├── expose/
├── notification/
└── osd/
```

Feature folders may contain their own QML UI, popup/panel pieces, state/service objects, and local theme section files. Keep shared wrappers and shared surfaces out of feature folders unless the ownership is obvious. The goal is fewer scavenger hunts, not a tiny bureaucracy with imports.

Guidelines:

- `shell.qml` should stay small.
- Put shared visible shell surfaces in an owning module folder; introduce a `panels/` folder only when shared panel surfaces actually exist.
- Put feature-owned visible surfaces in their feature folder.
- Put reusable wrappers in `components/`.
- Keep feature-owned files together where possible.
- Keep the public theme entry point centralized in `theme/QreepTheme.qml`.
- Put feature-specific size/spacing/timing tokens in the matching feature theme.
- Avoid hardcoding colors once a theme object/file exists.
- Prefer readable property names over clever abbreviations.
- If a bar pill can be refreshed through IPC, make the pill acknowledge that refresh with a subtle animation. The user should know the command landed; the bar should not perform dinner theatre.
- Use PascalCase for QML component files, for example `QreepModule.qml`.
- Name each QML root object `root` followed by the file name in PascalCase. For example, use `id: rootBar` in `Bar.qml`, `id: rootClock` in `Clock.qml`, and `id: rootShell` in `shell.qml`.
- Use lowercase/kebab-case for command names and scripts, for example `qreep-bar`.

Do not add TypeScript, JavaScript, shell scripts, or generated files unless the task actually needs them. Qreep is already a learning project; it does not need a side quest disguised as tooling.

## Scope, Loader, and LazyLoader rules

Use this rule of thumb:

```text
Scope      = always-alive feature controller / brain
Loader     = create/destroy an Item-like visual piece when needed
LazyLoader = create/destroy heavier Quickshell objects, windows, or non-Item feature surfaces when needed
```

A `Scope` should not be used because it looks serious. It should be used when a feature needs an always-alive controller for state, IPC, shortcuts, services, or one or more lazy windows.

A `Loader` or `LazyLoader` should not be used because hiding things feels too simple. Use loading when creating the object early is wasteful, risky, or makes `Bar.qml` own too much.

Prefer normal `visible` toggling when:

- the object is small;
- it is tightly anchored to a bar item;
- it needs to preserve local state while hidden;
- destroying/recreating it would make the code harder for no real gain.

Prefer `Scope` plus `Loader`/`LazyLoader` when:

- the feature is a full panel/window/layer surface;
- the feature is rarely opened;
- the feature owns expensive UI such as image grids, long lists, previews, or async data;
- the feature needs IPC or shortcuts even when its window is closed;
- `Bar.qml` is starting to know too much and looking proud of it.

The bar itself should not be lazy-loaded. At least one real shell window must exist normally. Do not put every visible thing behind lazy loaders and then wonder why the desktop became philosophical.

## Feature controller pattern

For larger features, prefer this shape inside the owning module:

```text
modules/bar/features/name/        # when the feature is bar-owned
modules/name/                     # when the feature is shell-level
├── Name.qml          # Scope/controller: state, IPC, loader, service ownership
├── NameButton.qml    # small bar-facing button, if the feature has one
├── NamePanel.qml     # actual PanelWindow/PopupWindow/large surface
├── NameService.qml   # command/data/service logic, if needed
└── NameTheme.qml     # feature-local sizes, spacing, timing, tokens
```

`Name.qml` is the feature's public entry point. It may expose a small API such as:

```qml
readonly property alias service: service
property bool open: false
function toggle(): void { open = !open }
function refresh(): void { service.refresh() }
```

`Bar.qml` should consume that public API instead of reaching into panel internals. The bar is the shelf, not the entire warehouse.

For existing features, do not force this structure immediately. Apply it only when a feature is large enough to deserve it, or when refactoring toward the planned larger surfaces.

## Surgical split / refactoring rules

The next architectural evolution is a **clean surgical split**:

```text
Bar.qml stops being the owner of every creature organ.
Feature folders become small self-contained modules.
Large panels become lazy feature surfaces.
The bar becomes a host/router, not a storage unit with rounded corners.
```

This must be done in unit-sized refactors. No big-bang rewrite. No “while I was here”. No renaming festival.

When splitting a feature:

1. Write down the current behavior first.
2. Move one ownership boundary at a time.
3. Keep the public behavior unchanged.
4. Keep existing IPC names unless Adam explicitly asks to change them.
5. Keep existing Hyprland layer namespaces unless the split requires a new one.
6. Add or update only the smallest theme section needed.
7. Run the smallest useful validation.
8. Commit only when asked, and keep it as one logical unit.

A good split is boring in the diff and obvious in the tree.

Bad split:

```text
refactor everything, rename three folders, change styling, add dashboard skeleton, fix a typo, and somehow break Escape.
```

Good split:

```text
refactor(upchecker): move panel ownership behind feature controller
```

Done means:

- `quickshell -c qreep --no-duplicate` still launches;
- the old click/IPC behavior still works;
- only the intended files changed;
- the diff can be reviewed without summoning an archaeologist.

## Planned large features

Qreep may grow larger optional surfaces. These should use the feature-controller pattern from the start.

### Dashboard / Aegis

Working names:

```text
qreep-dashboard
qreep-aegis
```

Use **Aegis**, not `Ageis`, unless Adam deliberately chooses the typo because the typo won the naming knife fight.

Purpose:

- `Dashboard` is the general overview surface.
- `Aegis` is the system-info / system-health / guardian variation of the dashboard.

Possible structure:

```text
modules/dashboard/
├── Dashboard.qml
├── DashboardButton.qml
├── DashboardPanel.qml
├── DashboardService.qml
└── DashboardTheme.qml

modules/aegis/
├── Aegis.qml

modules/dashboard/configs/
├── main_dashboard.json
└── aegis_dashboard.json

modules/dashboard/features/aegis/
├── AegisBlock.qml
├── AegisService.qml
└── AegisTheme.qml
```

Do not start by building a dashboard framework. Start with one useful view: system state, updates, backup status, media, monitor profile, or whatever makes the desktop feel less like a pile of unrelated goblins.

If `Aegis` is only a dashboard page, keep it inside `modules/dashboard/`. If it grows its own identity, IPC, service, or panel behavior, split it into `modules/aegis/`. Do not split because the folder tree looked lonely.

### Wallpaper selector

Working name:

```text
qreep-wallpaper
```

Purpose:

- browse wallpapers;
- preview wallpaper metadata;
- apply wallpaper/theme actions;
- eventually cooperate with Unclaimed Bloom / Matugen without pretending a wallpaper grid is a small tooltip.

Possible structure:

```text
modules/wallpaper/
├── Wallpaper.qml
├── WallpaperButton.qml
├── WallpaperPanel.qml
├── WallpaperService.qml
└── WallpaperTheme.qml
```

This is a strong `Scope + LazyLoader` candidate. Image grids, thumbnails, filesystem watchers, and previews should not be created at bar startup unless future Adam has been bad and needs consequences.

### Clipboard manager

Working name:

```text
qreep-clipboard
```

Goal: a Pano-like clipboard manager, but Qreep-shaped instead of “let us invent GNOME Shell in a trench coat”.

This is a top-level shell module, not a bar feature. It is opened by IPC
and a Hyprland binding such as `CTRL+SUPER+V`; do not add a bar button unless
Adam explicitly asks. The clipboard is a work surface, not another tiny object
trying to live in the right slot.

Current structure:

```text
modules/clipboard/
├── Clipboard.qml          # Scope/controller: IPC, open state, lazy panel
├── ClipboardPanel.qml     # PanelWindow UI, keyboard handling, grid/search
├── ClipboardService.qml   # clipvault calls, parsing, filtering, actions
├── ClipboardCard.qml      # one card/entry preview
├── ClipboardTheme.qml     # placement, sizes, spacing, colors, timing
└── README.md              # backend commands, IPC, keyboard model
```

Backend:

- use `clipvault`;
- do not invent QML clipboard persistence;
- use `clipvault list` for recent entries;
- use `clipvault get | wl-copy` to restore entries;
- use `clipvault delete` for deletion when available;
- keep the AGS-inspired pinned JSON idea at `~/.local/share/clipvault/pinned.json`;
- pinned entries sort first, but v1 must not try to solve clipvault pruning.

Pinned caveat:

Adam has seen `clipvault` prune old starred entries. Do not solve that in v1 by
quietly building a second clipboard database. Later options include backing up
pinned content outside clipvault, re-inserting missing pinned entries, or
separating “visual star” from “durable pin”. That is privacy-sensitive and
should be designed deliberately, not improvised because a star icon looked
lonely.

Panel behavior:

- default placement is bottom overlay;
- make placement theme-ready from the start, for example `position: "bottom"`;
- only bottom placement needs to work in v1;
- `shell.qml` hosts the module like dashboard and OSD;
- no bar button;
- Escape closes;
- outside click closes;
- refresh entries when shown.

IPC:

```bash
quickshell ipc call qreep-clipboard toggle
quickshell ipc call qreep-clipboard showMe
quickshell ipc call qreep-clipboard hideMe
quickshell ipc call qreep-clipboard refresh
```

Keyboard-first behavior is required:

- panel opens with search focused;
- typing filters immediately;
- `Down` moves focus from search into cards;
- arrow keys navigate cards;
- `Enter` restores the selected card and closes the panel;
- `Escape` closes the panel;
- `Ctrl+S` or `Alt+S` toggles star on the selected card;
- `Shift+Delete` deletes the selected card;
- printable typing while cards are focused returns focus to search and appends the typed character;
- after filtering, the selected index must remain valid or fall back to the first result.

Use a `GridView` for v1. Cards matter visually, and `GridView` gives current
index plus keyboard movement without hand-rolling a navigation system because
apparently we enjoy taxes.

Visual/content scope:

- card grid inspired by the AGS screenshot, not a one-to-one port;
- search is visible at the top for v1, with type-to-search overlay as a later improvement if it feels better;
- support text, code, color, and image cards first;
- image previews are exported to a runtime temp directory from `clipvault get`; do not turn that into a second clipboard store.
- keep the UI calm and graphite-ish like the rest of Qreep.

Current implementation:

- `Clipboard.qml` is the `Scope`/controller with IPC, open state, `ClipboardService`, and lazy `ClipboardPanel`.
- `ClipboardTheme.qml` is exposed through `modules/ModulesTheme.qml` and `theme/QreepTheme.qml`.
- `shell.qml` hosts `Clipboard` directly.
- `ClipboardService.qml` handles `clipvault list`, pinned JSON, filtering, selected index, image preview export, restore notifications, delete, and star/unstar actions.
- `ClipboardPanel.qml` is a bottom overlay `PanelWindow` with search, pins filter, outside-click close, and a keyboard-navigable `GridView`.
- `ClipboardCard.qml` renders text, code, color previews, and image previews.
- `modules/clipboard/README.md` documents IPC and backend requirements.

Next clipboard work:

1. Watch image preview cost with large screenshot history.
2. Decide whether pins should become durable content later, as a deliberate privacy-sensitive design.
3. Consider a type-to-search overlay if the visible search row starts feeling too chunky.

Minimum useful scope:

- list recent text entries;
- search/filter entries;
- paste selected entry;
- clear selected entry if the backend supports it;
- star/unstar entries using the pinned JSON;
- show image previews from runtime temp files exported out of `clipvault`.

Privacy rule: clipboard history is sensitive. Do not add persistence, indexing, previews, or logging beyond the existing backend behavior unless Adam explicitly asks for it. The clipboard does not need to become a diary with paste support.

### Expose / window overview

Working name:

```text
qreep-expose
```

Purpose:

- show a full-screen Expose-style overview;
- make current-workspace windows the primary, large preview targets;
- show other workspaces as smaller grouped clusters;
- focus a window by click, `Enter`, or arrow-key selection;
- later support type-to-search over class/title/app/workspace.

This is a top-level shell module, not a bar feature. It should be opened by IPC
and a Hyprland binding such as `SUPER+TAB`. Do not add a bar button unless Adam
explicitly asks. Expose is a work surface, not another tiny pill looking for a
chair.

Expected structure:

```text
modules/expose/
├── Expose.qml
├── ExposePanel.qml
├── ExposeService.qml
├── ExposeClientCard.qml
├── ExposeWorkspaceCluster.qml
├── ExposeTheme.qml
└── README.md
```

Use the existing shell-level pattern:

- `Expose.qml` is the `Scope`/controller with IPC, open state, service, and
  lazy panel.
- `ExposePanel.qml` is the full-screen overlay.
- `ExposeService.qml` owns Hyprland client/workspace data, grouping, selection,
  and focus dispatch.
- `shell.qml` hosts `Expose` directly, like Clipboard, Dashboard, and OSD.

IPC:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose showMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose hideMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose refresh
```

V1 behavior:

- full-screen `PanelWindow` overlay, `WlrLayer.Overlay`, exclusive zone `0`;
- refresh clients when shown;
- current workspace windows render as large cards;
- other workspaces render as smaller clusters;
- current workspace preview status is unresolved: `grim -g` works as a rectangle
  capture but lies when floating windows overlap normal windows;
- attempted live `ScreencopyView` previews from `Hyprland.toplevels` Wayland
  handles, but they did not work well enough to keep fighting today;
- current workspace cards may fall back to runtime `grim -g` thumbnails
  under `~/.cache/qreep/expose/`;
- click focuses the selected application/window and closes Expose;
- arrow keys move selection;
- `Enter` focuses the selected window and closes Expose;
- `Escape` closes;
- no search in v1, but keep the model ready for search filtering later.

Preview strategy:

1. Keep `Quickshell.Hyprland` / `hyprctl clients -j` as the reliable metadata
   and focus path because it gives geometry, class, floating state, workspace
   id/name, and address.
2. Use `Hyprland.toplevels` only where it helps; do not make selection/focus
   depend on it.
3. Do not assume `ScreencopyView` is solved. It was tested as the cleaner
   toplevel-preview path and did not behave well enough in this slice.
4. `grim -g` rectangle screenshots are usable only when overlapping windows do
   not matter. They are not true window screenshots.
5. Possible workaround to prototype later: create a temporary special workspace
   such as `special:qreep-expose-floaters`, move floating current-workspace
   windows there one by one, capture normal tiled windows without floaters
   covering them, then capture the floating windows separately, and finally
   restore every window to its original workspace/floating state. This needs to
   be treated as a careful transaction: collect original addresses/workspaces,
   avoid stealing focus more than necessary, handle failure, and always restore.
6. Store any generated thumbnails under `~/.cache/qreep/expose/`; do not create
   durable preview storage.

Layout direction:

- avoid making the overview a strict grid unless reality forces it;
- use a weighted layout where current workspace cards get the dominant area;
- group other workspaces into compact cards with mini client tiles/icons;
- keep enough geometry/ordering in the service for spatial navigation.

Keyboard navigation should be spatial, not spreadsheet-shaped:

```text
selected card center + direction -> nearest selectable card in that direction
```

Later search:

- printable typing opens/focuses a search field;
- filter by app label, class, title, and workspace name;
- keep selected index valid after filtering or fall back to the first result;
- `Escape` clears search first, then closes if search is already empty.

First useful unit:

```text
feat(expose): add window overview module
```

Acceptance criteria:

- `qreep-expose toggle` opens/closes;
- current workspace windows are big cards;
- other workspaces are compact clusters;
- click and `Enter` focus windows;
- arrow navigation works;
- `Escape` closes;
- `qmllint modules/expose/*.qml` passes.

## Refactor roadmap

Preferred next steps for the architectural split:

1. **Inventory current ownership in `Bar.qml`.** Done in `docs/bar-ownership-map.md`; keep it current or future Adam gets to cosplay as an archaeologist again.
2. **Split `Upchecker` first.** Done: `modules/bar/features/upchecker/Upchecker.qml` owns service and lazy panel wiring.
3. **Split `Power` second.** Done: `modules/bar/features/power/Power.qml` owns service and lazy panel wiring.
4. **Leave small anchored popups alone.** Calendar, MPRIS popup, network panel, and shared tooltips can stay visible-toggled until there is real pain.
5. **Create one large feature skeleton.** Dashboard exists as the first top-level surface; do not turn that into a framework audition unless the repetition earns it.

After the first split works, repeat the same pattern. Do not invent a generic feature framework until at least three features have repeated the same shape and the duplication is boring enough to deserve extraction.

## Shell commands and system commands

Adam works primarily on Arch Linux with Wayland/Hyprland.

When giving or adding commands:

- prefer Arch-friendly commands;
- explain what a command does and why when it is not obvious;
- avoid destructive commands unless explicitly requested;
- do not suggest deleting files without a review step;
- use `~/.local/bin` for personal helper scripts unless this project asks for project-local scripts.

For this project, common commands may include:

```bash
quickshell -c qreep
```

Use this to run the `qreep` Quickshell config from `~/.config/quickshell/qreep`.

```bash
quickshell -c qreep --no-duplicate
```

Use this when testing repeated launches and trying not to spawn a tiny panel colony.

If the exact command differs because of the installed Quickshell version, verify before changing docs.

## Git rules

### No co-author noise

Never add any of the following unless Adam explicitly asks:

```text
Co-authored-by:
Generated-by:
Created-by:
Signed-off-by:
AI-assisted
```

No bot signatures. No synthetic credit.

No “Claude helped.” No “ChatGPT helped.” No “Codex generated this.” The commit should look like Adam made the change because Adam owns the project.

### Unit commits

When Adam asks for **unit commits**, treat that as a strict workflow.

A unit commit means:

- one logical concern;
- one reason to exist;
- reviewable diff;
- no unrelated cleanup;
- no opportunistic formatting;
- no “while I was here” unless explicitly approved.

Before committing:

```bash
git status --short
```

Check what changed.

```bash
git diff
```

Review the actual patch.

If there are unrelated changes, do not stage them.

Use precise staging:

```bash
git add path/to/file
```

or, when useful:

```bash
git add -p
```

Use `git add -p` for splitting mixed changes into clean commits. It is mildly annoying, which is how you know it is probably doing something useful.

Recommended commit message style:

```text
type(scope): short imperative-ish summary
```

Examples:

```text
feat(bar): add centered clock module
style(theme): add qreep graphite tokens
refactor(modules): extract reusable module wrapper
docs(agents): document qreep workflow
fix(clock): avoid second-level refresh
```

Keep commit messages human and specific. Avoid generated-sounding sludge like:

```text
feat: enhance user experience with robust improvements
```

That says nothing, but with confidence. Dangerous combination.

### Commit only when asked

Do not create commits unless Adam explicitly asks for commits or the task specifically includes committing.

If asked to prepare commits:

1. inspect changes;
2. group them logically;
3. run relevant checks if available;
4. create one unit commit per group;
5. show the resulting commit list.

## Testing and validation

After code changes, run the smallest useful validation available.

For Qreep, that may mean:

```bash
quickshell -c qreep
```

or a syntax/check command if the project later adds one.

Useful small checks:

```bash
qmllint modules/bar/Bar.qml
qmllint theme/QreepTheme.qml
qmllint modules/bar/features/*/*.qml
```

If validation cannot be run in the current environment, say that clearly. Do not pretend it passed. Future Adam has enough problems without imaginary green checks.

When reporting results, include:

- what changed;
- what was tested;
- what was not tested;
- any risk or follow-up.

## File creation rules

When creating scripts for Adam:

- include a header with description/comment/documentation tags;
- use explicit versioned filenames for downloadable scripts, for example `script-name_v0.0.1`;
- provide install commands that copy the versioned file to the stable command name in `~/.local/bin`.

For project docs, prefer simple Markdown. Avoid YAML front matter unless Adam asks for it.

For notes, Adam usually prefers Logseq-friendly page properties, but `AGENTS.md` should stay a normal repository instruction file.

## Naming rules

Project names may be weird. Internal structure should not be.

Preferred names:

```text
qreep
qreep-bar
qreep-dashboard
qreep-aegis
qreep-wallpaper
qreep-clipboard
qreep-launcher
qreep-powermenu
qreep-theme
```

Avoid typo-branded names unless Adam explicitly blesses the typo. `dashboard`, not `dashbaord`, unless the project has fully surrendered.

Use:

- lowercase/kebab-case for commands, scripts, and config names;
- PascalCase for QML components;
- descriptive names for modules;
- boring folder names.

Good:

```text
modules/bar/features/clock/Clock.qml
components/QreepModule.qml
modules/bar/Bar.qml
theme/QreepTheme.qml
```

Bad:

```text
modules/bar/features/clock/ChronoGoblinFinal.qml
components/NiceThingNew2.qml
modules/bar/BarButActuallyDashboard.qml
```

## UI and theme rules

Qreep should eventually fit Adam's Hyprland desktop:

- graphite/nord-ish base;
- subtle Unclaimed Bloom / Matugen accent;
- practical, readable UI;
- not overbright;
- not childish;
- no rainbow confetti unless something has genuinely exploded.

For now, hardcoded colors are acceptable in early learning versions. Once theme integration exists, new modules should use theme tokens instead of raw color literals.

Prefer:

```qml
color: theme.foreground
```

over:

```qml
color: "#d8dee9"
```

unless working inside the theme file itself.

## Scope control

This project started with:

```text
bar → clock → colors → module wrapper → click action → real modules
```

That first phase is done enough to be dangerous. The current phase is:

```text
bar ownership map → feature controllers for large surfaces → one planned large feature → repeat only when boring
```

Do not jump straight to:

```text
state manager plugin framework IPC protocol theme compiler dashboard engine animation system small monarchy
```

Build the thing in visible, working slices.

Good first milestones:

```text
v0.0.1 - top bar with centered clock
v0.0.2 - reusable module styling and hover state
v0.0.3 - theme tokens loaded from one place
v0.0.4 - one practical module, such as updates or Borg status
v0.1.0 - usable enough to judge Waybar quietly
```

## Current state

Qreep currently has:

- a top `PanelWindow` bar with left, center, right, and overlay slots;
- bar mode runtime state in `modules/bar/BarModeService.qml`, exposed through IPC target `qreep-bar`;
- current bar modes:
  - `reserved`: normal bar, keeps layer-shell exclusive zone;
  - `overlay`: normal bar, no exclusive zone;
  - `collapsed`: compact top strip unless a visible pinned pill needs overlay space;
- runtime pill state in `modules/bar/BarPillStateService.qml`, exposed through IPC target `qreep-bar-pill`;
- current runtime pill IDs: `clock`, `workspaces`, `mpris`, `upchecker`, `monitorprofile`, `borg`, `battery`, `network`, and `volume`;
- enabled unpinned pills become 15px collapsed strips in collapsed mode; expanded pinned pills stay full-size, overlay content, use no top padding, and do not reserve Hyprland space;
- a reusable `QreepModule` wrapper with hover, left/middle/right click, overlay, and shared-tooltip request support;
- a launcher button in the left slot that delegates to `LauncherService`;
- a Hyprland workspaces module in the left slot with active/occupied workspace state, click/scroll switching, and a clickable client popup;
- a Borg status pill in the right bar slot with refresh, backup command, IPC, a structured tooltip, and a watched backup progress popup driven by `~/.cache/qreep/borg/state.json`;
- a clock with optional seconds, current-day event dots, and JSON-backed event tooltip content; event dots stay popup-based for placement and are suppressed while shell fullscreen surfaces are open;
- a calendar popup with a month grid, event markers, selected-day agenda, sync footer, and click behavior where left opens the calendar, middle toggles seconds, and right confirms a manual pull;
- calendar sync helpers for local cache JSON, Google OAuth read-only events, Microsoft ICS, and Microsoft Graph; `qreep-calendar-pull` wraps configured providers and writes `~/.cache/qreep/calendar/state.json` plus `~/.cache/qreep/calendar/final.json`;
- a user systemd calendar timer installed by `scripts/install`, quiet by default, while manual clock pulls call `qreep-calendar-pull --notify`;
- a MonitorProfile pill that watches runtime JSON, sorts monitors by position, and shows internal/external display icons plus a plain tooltip;
- an MPRIS pill in the center slot with current playback state, track columns, animated notes, preview tooltip, and right-click player popup;
- one shared popup tooltip with delayed show/hide and scale animations;
- a Battery pill in the right slot backed by `Quickshell.Services.UPower`;
- a Network pill and anchored panel for wired, Wi-Fi, and Bluetooth state/actions through Quickshell networking services plus a few boring `nmcli` details;
- a Volume pill backed by shared `core/SoundService.qml`, with click-to-mute, scroll-to-change volume, right-click `pavucontrol`, and OSD feedback through `shell.qml`;
- a Power feature controller in `modules/bar/features/power/Power.qml` that owns `PowerService` and lazy-loads the `qreep-popup-power` panel;
- the Power panel supports keyboard selection, confirmation navigation, normal right-side mode, and `qreep-power toggleFullscreen` for a full-screen layer surface;
- confirmed power actions wired through `modules/bar/features/power/PowerService.qml`;
- an Upchecker feature controller in `modules/bar/features/upchecker/Upchecker.qml` that owns `UpcheckerService` and lazy-loads the standalone `qreep-popup-upchecker` panel;
- a top-level Aegis module in `modules/aegis/`, hosted directly by `shell.qml`, exposed through IPC target `qreep-aegis`, using the shared dashboard renderer with `modules/dashboard/configs/aegis_dashboard.json` and the Aegis feature/service under `modules/dashboard/features/aegis/`;
- a top-level Dashboard module in `modules/dashboard/`, hosted directly by `shell.qml`, using `modules/dashboard/configs/main_dashboard.json` and not waking Aegis just because Aegis exists;
- a top-level Bloom module in `modules/bloom/`, hosted directly by `shell.qml`, exposed through IPC target `qreep-bloom`, and watching Unclaimed Bloom runtime cache files;
- a top-level Clipboard module in `modules/clipboard/`, hosted directly by `shell.qml`, exposed through IPC target `qreep-clipboard`, and backed by `clipvault`;
- the Clipboard panel currently supports a bottom overlay, search/filter, pins filter, keyboard navigation, text/code/color/image cards, runtime image previews, restore notifications, delete, and star/unstar metadata in `~/.local/share/clipvault/pinned.json`;
- a top-level Expose module in `modules/expose/`, hosted directly by `shell.qml`, exposed through IPC target `qreep-expose`, with parallel runtime thumbnails, centered manual layout motion, type-to-search filtering, spatial keyboard navigation, and keyboard/click activation that switches workspace before focusing the selected client;
- a top-level Notification module in `modules/notification/`, hosted directly by `shell.qml`, exposed through IPC target `qreep-notification`, and backed by `Quickshell.Services.Notifications.NotificationServer`;
- notification popups and the notification center use masked layer surfaces so transparent areas pass pointer input through; do not remove those masks just because the surface looks transparent;
- notification popup action handling is intentionally id-based because invoking an action can close/destroy the notification object before animations finish. Do not change action clicks back to delayed object-based dismiss unless crash reports are the desired feature;
- a top-level Quickshell OSD module in `modules/osd/` with IPC methods for plain messages, JSON-backed messages, progress displays, volume, microphone, brightness, and player controls;
- feature-local theme sections exposed through `theme/QreepTheme.qml`;
- an Unclaimed Bloom palette contract consisting of `theme/colors/template.qml` and `theme/colors/UnclaimedBloomColors.qml`;
- watched local/generated calendar sources loaded through `modules/bar/features/clock/EventStore.qml`: repo `events.json`, `~/.cache/qreep/calendar/events.json`, and `~/.cache/qreep/calendar/microsoft-events.json`.

Useful bar IPC commands:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar getMode
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar setReserved
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar setOverlay
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar setCollapsed
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar toggleOverlay
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar toggleCollapsed
```

Useful pill IPC commands:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar-pill state clock
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar-pill disablePill clock
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar-pill enablePill clock
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar-pill togglePill clock
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar-pill expandPill clock
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar-pill collapsePill clock
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar-pill togglePinned clock
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bar-pill listPills
```

Useful clipboard IPC commands:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard showMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard hideMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-clipboard refresh
```

Useful dashboard IPC commands:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-dashboard toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-dashboard showMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-dashboard hideMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-dashboard refresh
```

Useful Aegis IPC commands:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-aegis toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-aegis showMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-aegis hideMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-aegis refresh
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-aegis setMode full
```

Useful Bloom IPC commands:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bloom showBloom default ""
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bloom doneBloom
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bloom pickupBloom
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-bloom hideBloom
```

Useful Expose IPC commands:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose showMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose hideMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-expose refresh
```

Useful notification IPC commands:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-notification toggleCenter
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-notification showCenter
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-notification hideCenter
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-notification dismissAll
```

Notification testing helper:

```bash
scripts/qreep-notification-test-batch_v0.0.1 --delay 0.4
```

Current pickup point:

- The Clipboard v1 shell module is done enough for now: IPC, search/filter, keyboard navigation, restore notifications, delete, pins, and image previews are implemented and documented in `modules/clipboard/README.md`.
- The Notification v1 shell module is implemented and documented in `modules/notification/README.md`: popups, notification center, grouping, per-group dismissal, app-specific cards for Color Picker and Hyprshot, action buttons, popup animations, and a test batch script.
- The Aegis v1 shell module replaces the old AGS Aegis package for the common path: standalone `qreep-aegis` overlay, sysinfo service, dashboard-style enter/leave motion, and independent `modules/dashboard/configs/aegis_dashboard.json` layout. Aegis uses normal dashboard `blocks`, not legacy AGS `widgets`. Keep the main dashboard and Aegis configs separate.
- Do not continue expanding Clipboard unless Adam asks. The remaining clipboard items are follow-ups, not the next default project direction.
- The next default project direction is the bar/runtime stabilization pass described below. This supersedes the older MPRIS-first suggestion unless Adam explicitly asks for MPRIS.
- Do not rush persistence. Runtime state first, persisted layout second. Past Adam does not need a config file that explains a bug with confidence.

## Next-session priority

If a new session starts and Adam asks “what’s next?”, answer with this:

```text
The next best step is a small stabilization pass on the bar/runtime surface.
```

Do **not** default to splitting MPRIS or building another module. The repo now has enough shell-level surfaces that the daily visible bar deserves a sanity pass before more furniture arrives.

Recommended unit:

```text
fix(bar): clean up current bar wiring
```

Scope:

1. Inspect `modules/bar/Bar.qml` for duplicated bindings, stale `Connections`, and feature wiring drift. Known example from the 2026-07-08 source pass: `LauncherButton` had duplicate `visible: !rootBar.collapsed` bindings.
2. Verify every runtime pill ID matches `BarPillStateService.knownPills` and the registered pill wiring in `Bar.qml`.
3. Check that hiding runtime pills consistently closes related popups, panels, and tooltips.
4. Keep behavior unchanged unless a bug is found. This is stabilization, not a costume change.
5. Run focused validation:

```bash
qmllint modules/bar/Bar.qml
qmllint modules/bar/features/*/*.qml
git diff --check
```

If the live session allows it, also run:

```bash
quickshell -c qreep --no-duplicate
```

Avoid during this pass:

- splitting MPRIS;
- adding new modules;
- adding persistence/config machinery;
- visual restyling;
- “while here” cleanup outside bar runtime wiring.

After this pass, the next larger improvement can be making Power fullscreen feel like a deliberate full-screen layout instead of the same small card on a full-screen layer.

## Suggested next five steps

1. **Run the bar/runtime stabilization pass first.** This is the default answer to “what’s next?” in the next session.
2. **Preserve current visible behavior during that pass.** The expected output is boring wiring cleanup, not a redesigned bar.
3. **Decide whether `launcher` and `power` should join runtime pill state only after the sanity pass.** Both are technically easy. Launcher and Power are also useful escape hatches, so hiding them should be a deliberate choice, not a side effect with icons.
4. **Keep the ownership map current if the stabilization pass changes ownership boundaries.** The map is only useful if it tells the truth, which is apparently a demanding requirement.
5. **Leave Clipboard alone unless a real issue appears.** The follow-ups live in `modules/clipboard/README.md`; they are not an invitation to build a tiny paste empire today.

Keep these steps independent and reviewable. Qreep has enough moving pieces now that “one tiny cleanup while here” can reproduce when left unattended.

## Communication with Adam

Adam likes direct explanations, practical examples, and dry honesty.

When responding:

- use concise explanations first;
- include commands when useful;
- explain commands when they matter;
- show file paths clearly;
- avoid hiding important details in vague prose;
- do not ask unnecessary clarification questions if a reasonable assumption can be made;
- mention risks before destructive actions;
- provide downloadable files when creating substantial scripts, docs, prompts, or notes.

If Adam writes messy English, understand the intent and answer the task.

A small English correction can be added separately if appropriate, but do not derail the technical answer into a grammar tribunal.

## Final reminder

Qreep should remain small enough that Adam can open it after three tired evenings and still understand what past Adam was thinking. Past Adam is not available for questioning. Plan accordingly.
