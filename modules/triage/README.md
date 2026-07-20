# Triage Module

Qreep Triage is a planned package-maintenance surface for Arch Linux systems.

Its job is not to become a package manager. Its job is to make package state
understandable before anything destructive happens: what is installed, what is
orphaned, what depends on a package, why a package exists, and what decision was
made about it.

The original `rusty-triage` Rust TUI is the reference prototype for the domain
model and safety stance. The Qreep version is an independent Qreep module with
its own helper contract, QML surface, IPC target, theme section, and docs.

## Purpose

Package maintenance often starts with a blunt list and ends with someone hoping
they removed the right thing.

This module should support a slower and more useful workflow:

- inspect package counts and update state;
- find orphaned packages;
- queue packages for review;
- explain why a package exists;
- show direct reverse dependencies;
- record human decisions;
- keep an append-only history of package queries and local decisions;
- export that history when future Adam wants evidence instead of vibes.

The important part is not automation. The important part is traceable intent.

## Scope

V1 is read-only against the system and writable only to Qreep-owned local state.

Allowed in v1:

- read installed package data;
- read explicit/dependency/orphan counts;
- check pending updates;
- inspect package metadata;
- inspect direct reverse dependencies;
- write Qreep triage state, decisions, and history files;
- export local triage history.

Not allowed in v1:

- remove packages;
- run `pacman -R`;
- run `paru -R`;
- run `sudo`;
- run `pkexec`;
- apply `plan-remove` decisions;
- hide command failures behind friendly-looking UI text.

If package removal is ever added, it should be a separate design pass with full
command preview, confirmation, logging, and a very clear boundary between
"planning removal" and "performing removal".

## Relationship to rusty-triage

`rusty-triage` provides the starting vocabulary:

- read-only command providers;
- command events with `id`, `provider`, `argv`, timestamp, success state, exit
  code, risk, and trigger;
- package explanations from `pacman -Qi` plus `pactree -r -d 1`;
- orphan queueing from `pacman -Qtdq`;
- decision kinds: `keep`, `investigate`, `plan-remove`, `skip`;
- local SQLite state with JSON/Markdown export;
- JSON/Markdown export.

Qreep should not port the Rust terminal UI. The ratatui layout, CLI event loop,
and Rust keymap system are not the target. They were useful for proving the
workflow. Qreep should rebuild the workflow using Qreep's own module pattern.

## Qreep Ownership

This should be a top-level shell module:

```text
modules/triage/
```

It should not live under `modules/bar/features/`. The bar can expose a small
entry point later, but triage is a work surface, not a pill.

Current/planned structure:

```text
modules/triage/
|-- Triage.qml          # Scope/controller: IPC, open state, lazy panel
|-- TriagePanel.qml     # large package triage surface
|-- TriageService.qml   # helper calls, JSON parsing, filtering, selection
|-- TriageCard.qml      # one package/review row or card
|-- TriageTheme.qml     # sizes, spacing, colors, animation timing
`-- README.md           # this file
```

Recommended IPC target:

```text
qreep-triage
```

Expected IPC:

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-triage toggle
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-triage showMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-triage hideMe
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-triage refresh
```

## Helper Contract

Use a helper command for pacman calls and persistence. QML can run commands, but
it should not become the place where JSON files, command history, pacman parsing,
and decision writes all go to argue.

Helper source:

```text
tools/triagectl/
```

Installed command:

```text
triagectl
```

Suggested helper commands:

```bash
triagectl summary
triagectl packages updates
triagectl packages orphans
triagectl packages dependencies
triagectl packages explicit
triagectl packages total
triagectl orphans
triagectl queue-orphans
triagectl why bash
triagectl decisions
triagectl decide bash keep --note "Required by my shell setup"
triagectl export-json
triagectl export-md
```

All helper output intended for QML should be JSON. Human text can exist for
`--help`, but service calls should not need fragile string parsing.

Build/install through the repo installer:

```bash
scripts/install
```

That builds `tools/triagectl` in release mode and installs the stable helper name
to `~/.local/bin/triagectl`.

## Data Files

Use Qreep-owned paths:

```text
~/.local/share/qreep/triage/triage.db
~/.local/share/qreep/triage/exports/
~/.config/qreep/triage/note-presets.json
```

`triage.db` is the source of truth. The helper owns schema setup and writes.
QML should not open the database directly. It should call `triagectl` and parse
JSON stdout, because QML does not need a side hustle as a database client.

Initial tables:

- `command_events`: append-only command history with command id, provider, argv,
  timestamp, success state, exit code, risk, trigger, stdout, and stderr.
- `review_items`: one row per queued package, keyed by package name.
- `decisions`: append-only package decisions with kind and optional note.

Exports are generated from SQLite into human-readable files under `exports/`.

## Package Commands

The initial provider set should stay boring:

```text
pacman -Qq             # all installed package names
pacman -Qqe            # explicitly installed packages
pacman -Qqd            # dependency-installed packages
pacman -Qtdq           # orphaned packages
pacman -Qi <package>   # package metadata and install reason
pactree -r -d 1 <pkg>  # direct reverse dependencies
checkupdates --nocolor # pending updates when available
pacman -Qu             # fallback pending update check
```

Every command result should become a structured event. Even failures are useful
state if they are explicit.

## UI Direction

This is a large panel, not a tooltip.

Suggested layout:

- header with package summary: total, explicit, dependencies, orphans, outdated;
- left review list with package name, source, and latest decision;
- details pane for selected package metadata;
- reverse-dependency section;
- notes/decision area;
- filter/search input;
- bottom action strip;
- status or history strip showing the latest command event.

The surface should be dense enough for repeated use, but not cramped. It should
feel like a Qreep work panel: quiet, themed, keyboard-friendly, and explicit
about failure.

Useful panel actions:

- refresh summary;
- queue orphans;
- inspect selected package;
- mark keep;
- mark investigate;
- mark plan-remove;
- mark skip;
- add note;
- export JSON;
- export Markdown.

Current panel behavior:

- opens through `qreep-triage` IPC;
- refreshes summary and decision data when shown;
- the top stats row filters real package lists in this order: Updates, Orphans,
  Deps, Explicit, Total;
- Updates rows show installed and available package versions when `checkupdates`
  reports them;
- the decision row filters the active package list by All, None, Keep,
  Investigate, Plan Remove, and Skip;
- filters the active package list by package, source, and decision;
- shows the latest decision note in the package row preview and the decision
  panel;
- inspects the selected package through `triagectl why <pkg>`;
- records local decisions through `triagectl decide`, appending a new history
  entry instead of overwriting older notes;
- colors decision action buttons with the same keep, investigate, plan-remove,
  and skip model used by decision labels, and highlights the current one;
- provides a compact History toggle in the decision panel for the selected
  package's append-only decision history;
- clears package metadata and reverse dependency details when selection moves to
  another package;
- shows a large clickable inspect hint overlay, inset inside the package detail
  box, that loads metadata through the same path as Enter and double-click;
- shows the latest command event in the bottom strip, including the exact argv
  that was executed, and copies that command to the clipboard with a notification
  when clicked;
- exports JSON and Markdown history from `triagectl`.

Keyboard behavior:

- `Escape` closes;
- arrow keys move selection;
- typing filters;
- `Enter` opens or refreshes selected package details;
- decision keys are acceptable if the visible UI names them;
- destructive system actions do not exist in v1.

## Existing Qreep Upchecker

Qreep already has `modules/bar/features/upchecker/`.

That feature answers the quick bar question:

```text
are updates available?
```

Triage should answer a different question:

```text
what should I understand, decide, and document about package state?
```

Do not merge these too early. Reasonable integration later:

- `upchecker` can open triage filtered to outdated packages;
- triage can reuse helper logic if a shared helper becomes worthwhile;
- dashboard or Aegis can show a small triage summary once the main panel exists.

Until duplication hurts, keep the boundary simple.

## Implementation Slices

### Slice 1: Module Plan

- Add this README under `modules/triage/`.
- Add a concise `AGENTS.md` note describing the module boundary and v1 safety
  rule.

### Slice 2: Helper

- Add `tools/triagectl` as a Rust helper.
- Store triage state in SQLite at `~/.local/share/qreep/triage/triage.db`.
- Implement JSON commands: `summary`, `orphans`, `queue-orphans`, `why`,
  `decisions`, `decide`, `export-json`, and `export-md`.
- Add install wiring in `scripts/install`.
- Verify helper output before QML exists.

### Slice 3: QML Skeleton

- Add `Triage.qml` as the controller. Done.
- Add `TriageService.qml` for helper calls and JSON parsing. Done.
- Add `TriagePanel.qml` as a lazy large surface. Done.
- Add `TriageTheme.qml`. Done.
- Wire `modules/ModulesTheme.qml`, `theme/QreepTheme.qml`, and `shell.qml`. Done.
- Add IPC target `qreep-triage`. Done.

### Slice 4: First Useful Panel

- Show summary counts.
- Show package lists from the clicked stat category.
- Show selected package details.
- Support decision writes.
- Support category, decision, search filtering, and selected-index clamping.
- Show command errors clearly.

### Slice 5: Export and Integration

- Add export actions.
- Add small dashboard/Aegis summary only if useful.
- Optionally add an `upchecker` route into triage.

## Definition of Done for V1

- `triagectl summary` returns valid JSON.
- `triagectl packages <category>` returns valid JSON package lists.
- Update package rows include old/new version fields when the backend provides
  them.
- `triagectl why <pkg>` returns metadata plus direct reverse dependencies.
- Qreep opens the triage panel through IPC.
- The panel lists packages for the active stat category.
- The panel shows details for the selected package.
- Decisions persist across Qreep restarts.
- The module README documents commands, files, IPC, and safety limits.
- `AGENTS.md` records the module boundary.
- Focused `qmllint` passes for touched QML.
- `quickshell -c qreep --no-duplicate` still launches.

## Design Principle

Package maintenance should be explainable before it is executable.

That is the part worth carrying from `rusty-triage` into Qreep.
