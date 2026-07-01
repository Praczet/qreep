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

## Quickshell / QML rules

Qreep is a Quickshell project. Prefer QML-first solutions unless there is a good reason not to.

Use this project layout:

- `modules/` for top-level Qreep modules (for example: `bar`, `dashboard`);
- `modules/bar/features/` for bar-owned pills, panels, services, and popups;
- `modules/osd/` for the shell-level OSD surface and IPC service;
- `components/` for reusable UI pieces;
- `theme/` for the public theme object, shared theme sections, and generated colors;
- `core/` for truly shared services/state once they actually exist.

Current bar feature folders:

```text
modules/bar/features/
├── borg/
├── clock/
├── launcher/
├── monitorprofile/
├── mpris/
├── power/
├── upchecker/
└── workspaces/
```

Current top-level module folders:

```text
modules/
├── bar/
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

Qreep may grow three larger optional surfaces. These should use the feature-controller pattern from the start.

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
├── AegisPanel.qml
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

Possible structure:

```text
modules/clipboard/
├── Clipboard.qml
├── ClipboardButton.qml
├── ClipboardPanel.qml
├── ClipboardService.qml
└── ClipboardTheme.qml
```

Start with a small, useful scope:

- list recent text entries;
- search/filter entries;
- paste selected entry;
- clear selected entry if the backend supports it;
- keep image/history handling for later unless the first version actually needs it.

Privacy rule: clipboard history is sensitive. Do not add persistence, indexing, previews, or logging beyond the existing backend behavior unless Adam explicitly asks for it. The clipboard does not need to become a diary with paste support.

## Refactor roadmap

Preferred next steps for the architectural split:

1. **Inventory current ownership in `Bar.qml`.** List every feature object the bar creates directly, what it owns, and whether it is small, anchored, full-surface, or service-like.
2. **Split `Upchecker` first.** It is already a standalone full-screen-ish panel with service behavior and IPC, so it is the best candidate for a clean `Scope + LazyLoader` extraction.
3. **Split `Power` second.** Keep `PowerService` always available if needed, but let the full power panel be owned by a feature controller instead of the bar.
4. **Leave small anchored popups alone.** Calendar, MPRIS popup, and shared tooltips can stay visible-toggled until there is real pain.
5. **Create one large feature skeleton.** Start with `Dashboard`/`Aegis`, `Wallpaper`, or `Clipboard`, but only one. Skeleton first, behavior second, polish third. Confusing those steps is how “simple panel” becomes “legacy panel” before lunch.

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
- current runtime pill IDs: `clock`, `workspaces`, `mpris`, `upchecker`, `borg`, `battery`, and `volume`;
- enabled unpinned pills become 15px collapsed strips in collapsed mode; expanded pinned pills stay full-size, overlay content, use no top padding, and do not reserve Hyprland space;
- a reusable `QreepModule` wrapper with hover, click, right-click, overlay, and shared-tooltip request support;
- a launcher button in the left slot that delegates to `LauncherService`;
- a Hyprland workspaces module in the left slot with active/occupied workspace state, click/scroll switching, and a clickable client popup;
- a Borg status pill in the right bar slot with refresh, backup command, IPC, and a structured tooltip;
- a clock with optional seconds, current-day event dots, and JSON-backed event tooltip content;
- a calendar popup with a month grid, event markers, and a six-day agenda covering today plus the next five days;
- a MonitorProfile pill that watches runtime JSON, sorts monitors by position, and shows internal/external display icons plus a plain tooltip;
- an MPRIS pill in the center slot with current playback state, track columns, animated notes, preview tooltip, and right-click player popup;
- one shared popup tooltip with delayed show/hide and scale animations;
- a full-height power layer panel with its own `qreep-popup-power` namespace, themed system icons, outside-click/Escape dismissal, margin, and rounded sidebar;
- confirmed power actions wired through `modules/bar/features/power/PowerService.qml`;
- an Upchecker button and standalone `qreep-popup-upchecker` layer panel;
- a top-level Quickshell OSD module in `modules/osd/` with IPC methods for plain messages, JSON-backed messages, progress displays, volume, microphone, brightness, and player controls;
- feature-local theme sections exposed through `theme/QreepTheme.qml`;
- an Unclaimed Bloom palette contract consisting of `theme/colors/template.qml` and `theme/colors/UnclaimedBloomColors.qml`;
- a watched `events.json` source loaded through `modules/bar/features/clock/EventStore.qml`.

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

Current pickup point:

- Today’s bar mode/pill-state work is intentionally a small runtime slice, not the final bar layout config system.
- Next session should pick up from `BarModeService.qml`, `BarPillStateService.qml`, and the registered pill wiring in `Bar.qml`.
- The next likely step is to decide whether `network`, `monitorprofile`, `launcher`, and `power` should join runtime pill state or stay normal-mode-only for now.
- Do not rush persistence. Runtime state first, persisted layout second. Past Adam does not need a config file that explains a bug with confidence.

## Suggested next five steps

1. **Document the current `Bar.qml` ownership map in the repo docs.** List services, small anchored modules, anchored popups, standalone layer panels, and shell-level modules. This is boring and therefore suspiciously useful.
2. **Refactor `Upchecker` into a feature controller.** Add `modules/bar/features/upchecker/Upchecker.qml` as the `Scope` entry point, keep `UpcheckerService` always available for IPC, and move `UpcheckerPanel` creation behind a loader/lazy loader without changing existing click or IPC behavior.
3. **Refactor `Power` the same way.** Keep `PowerService` clear and boring; let a controller own `PowerButton`/`PowerPanel` wiring if that reduces `Bar.qml` ownership without breaking Escape/outside-click dismissal.
4. **Review whether `MPRIS` deserves a controller.** It already has a service, button, tooltip, panel, and controls. It is not urgent, but it is large enough to be watched before it starts wearing a little crown.
5. **Create one planned large feature skeleton.** Prefer `Dashboard`/`Aegis` for system overview, `Wallpaper` for theme/wallpaper workflow, or `Clipboard` for daily utility. Pick one. One is plenty. The first version should be a useful surface, not a framework audition.

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
