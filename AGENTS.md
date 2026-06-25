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
├── features/
├── panels/
└── theme/
```

Keep this structure boring. The name is weird enough.

## Voice and documentation style

Use Adam's preferred tone:

* dry, practical, slightly sarcastic;
* helpful, not motivational-poster-shaped;
* clear enough for future tired Adam;
* honest about uncertainty;
* no corporate foam;
* no exaggerated praise like “excellent question”;
* no fake enthusiasm, no “🚀”, no “magic”, no “seamless developer experience” unless mocking it.

Documentation may be witty, but it must remain useful. The joke is allowed to sit in the corner; it must not drive the architecture.

When writing project documentation:

* prefer short sections with concrete commands;
* explain why a command is used, especially system commands;
* use comments that help future maintenance, not comments that narrate the obvious;
* if using callouts, every callout must have a title;
* preserve Adam's voice in notes/reflections instead of polishing everything into generic README soup.

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

* keep edits focused;
* do not rewrite unrelated code;
* do not rename files casually;
* do not reformat entire files unless asked;
* do not silently change behavior outside the task;
* prefer boring, explicit code over clever QML origami;
* make assumptions visible when they matter;
* if something is uncertain, say so and leave a clear TODO or note.

If Adam asks for a plan, provide a useful plan.
If Adam asks for code, provide code.
If Adam asks for both, do not spend three pages admiring the plan while the code dies of loneliness.

## Quickshell / QML rules

Qreep is a Quickshell project. Prefer QML-first solutions unless there is a good reason not to.

Use this project layout:

* `features/` for feature-owned UI, state, services, and feature theme sections;
* `panels/` for shared top-level surfaces such as the bar and shared tooltip;
* `components/` for reusable UI pieces;
* `theme/` for the public theme object, shared theme sections, and generated colors;
* `core/` for truly shared services/state once they actually exist.

Current feature folders:

```text
features/
├── borg/
├── clock/
├── osd/
└── power/
```

Feature folders may contain their own QML UI, popup/panel pieces, state/service
objects, and local theme section files. Keep shared wrappers and shared surfaces
out of feature folders unless the ownership is obvious. The goal is fewer
scavenger hunts, not a tiny bureaucracy with imports.

Guidelines:

* `shell.qml` should stay small.
* Put shared visible shell surfaces in `panels/`.
* Put feature-owned visible surfaces in their feature folder.
* Put reusable wrappers in `components/`.
* Keep feature-owned files together where possible.
* Keep the public theme entry point centralized in `theme/QreepTheme.qml`.
* Put feature-specific size/spacing/timing tokens in the matching feature theme.
* Avoid hardcoding colors once a theme object/file exists.
* Prefer readable property names over clever abbreviations.
* If a bar pill can be refreshed through IPC, make the pill acknowledge that
  refresh with a subtle animation. The user should know the command landed;
  the bar should not perform dinner theatre.
* Use PascalCase for QML component files, for example `QreepModule.qml`.
* Name each QML root object `root` followed by the file name in PascalCase.
  For example, use `id: rootBar` in `Bar.qml`, `id: rootClock` in
  `Clock.qml`, and `id: rootShell` in `shell.qml`.
* Use lowercase/kebab-case for command names and scripts, for example `qreep-bar`.

Do not add TypeScript, JavaScript, shell scripts, or generated files unless the task actually needs them. Qreep is already a learning project; it does not need a side quest disguised as tooling.

## Shell commands and system commands

Adam works primarily on Arch Linux with Wayland/Hyprland.

When giving or adding commands:

* prefer Arch-friendly commands;
* explain what a command does and why when it is not obvious;
* avoid destructive commands unless explicitly requested;
* do not suggest deleting files without a review step;
* use `~/.local/bin` for personal helper scripts unless this project asks for project-local scripts.

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
🤖
AI-assisted
```

No bot signatures.
No synthetic credit.
No “Claude helped.”
No “ChatGPT helped.”
No “Codex generated this.”
The commit should look like Adam made the change because Adam owns the project.

### Unit commits

When Adam asks for **unit commits**, treat that as a strict workflow.

A unit commit means:

* one logical concern;
* one reason to exist;
* reviewable diff;
* no unrelated cleanup;
* no opportunistic formatting;
* no “while I was here” unless explicitly approved.

Before committing:

```bash
git status --short
```

Check what changed.

```bash
git diff
```

Review the actual patch.

If there are unrelated changes, do not stage them. Use precise staging:

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

If validation cannot be run in the current environment, say that clearly. Do not pretend it passed. Future Adam has enough problems without imaginary green checks.

When reporting results, include:

* what changed;
* what was tested;
* what was not tested;
* any risk or follow-up.

## File creation rules

When creating scripts for Adam:

* include a header with description/comment/documentation tags;
* use explicit versioned filenames for downloadable scripts, for example `script-name_v0.0.1`;
* provide install commands that copy the versioned file to the stable command name in `~/.local/bin`.

For project docs, prefer simple Markdown. Avoid YAML front matter unless Adam asks for it. For notes, Adam usually prefers Logseq-friendly page properties, but `AGENTS.md` should stay a normal repository instruction file.

## Naming rules

Project names may be weird. Internal structure should not be.

Preferred names:

```text
qreep
qreep-bar
qreep-dashboard
qreep-launcher
qreep-powermenu
qreep-theme
```

Avoid typo-branded names unless Adam explicitly blesses the typo.
`dashboard`, not `dashbaord`, unless the project has fully surrendered.

Use:

* lowercase/kebab-case for commands, scripts, and config names;
* PascalCase for QML components;
* descriptive names for modules;
* boring folder names.

Good:

```text
features/clock/Clock.qml
components/QreepModule.qml
panels/Bar.qml
theme/QreepTheme.qml
```

Bad:

```text
features/clock/ChronoGoblinFinal.qml
components/NiceThingNew2.qml
panels/BarButActuallyDashboard.qml
```

## UI and theme rules

Qreep should eventually fit Adam's Hyprland desktop:

* graphite/nord-ish base;
* subtle Unclaimed Bloom / Matugen accent;
* practical, readable UI;
* not overbright;
* not childish;
* no rainbow confetti unless something has genuinely exploded.

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

This project starts with:

```text
bar → clock → colors → module wrapper → click action → real modules
```

Do not jump straight to:

```text
state manager
plugin framework
IPC protocol
theme compiler
dashboard engine
animation system
small monarchy
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

* a top `PanelWindow` bar with left, center, right, and overlay slots;
* a reusable `QreepModule` wrapper with hover, click, right-click, overlay, and
  shared-tooltip request support;
* an initial Borg status pill placeholder in the right bar slot;
* a clock with optional seconds, current-day event dots, and JSON-backed event
  tooltip content;
* a calendar popup with a month grid, event markers, and a six-day agenda
  covering today plus the next five days;
* one shared popup tooltip with delayed show/hide and scale animations;
* a full-height power popup with themed system icons and outside-click/Escape
  dismissal;
* confirmed power actions wired through `features/power/PowerService.qml`;
* a Quickshell OSD with IPC methods for plain and JSON-backed messages;
* feature-local theme sections exposed through `theme/QreepTheme.qml`;
* an Unclaimed Bloom palette contract consisting of
  `theme/colors/template.qml` and
  `theme/colors/UnclaimedBloomColors.qml`;
* a watched `events.json` source loaded through `features/clock/EventStore.qml`.

## Suggested next five steps

1. **Build the Borg status feature properly.**
   Prefer structured JSON from `borg-pulse` over parsing Waybar/Pango output.
   Render the rich tooltip in QML, because that is the point of this little
   migration-shaped incident.
2. **Add IPC refresh for Borg.**
   Let backup scripts call a Qreep IPC method after a backup finishes, while
   keeping Waybar compatibility during the transition.
3. **Finish the Unclaimed Bloom Qreep target.**
   Add the matching recipe, template deployment, and profile entry in
   Unclaimed Bloom so generated colors replace the current checked-in palette
   safely.
4. **Finish the MonitorProfile feature.**
   Wire the monitor profile button through `QreepModule`, keep its state and
   theme bits in `features/monitorprofile/`, and make the active profile
   obvious without turning the bar into a control panel with ambitions.
5. **Add basic project documentation and validation notes.**
   Fill `README.md` with the run command, current feature layout, event JSON
   format, required icon/theme assumptions, Hyprland popup blur rule, IPC
   examples, and known Wayland limitations.

Keep these steps independent and reviewable. Qreep has enough moving pieces now
that “one tiny cleanup while here” can reproduce when left unattended.

## Communication with Adam

Adam likes direct explanations, practical examples, and dry honesty.

When responding:

* use concise explanations first;
* include commands when useful;
* explain commands when they matter;
* show file paths clearly;
* avoid hiding important details in vague prose;
* do not ask unnecessary clarification questions if a reasonable assumption can be made;
* mention risks before destructive actions;
* provide downloadable files when creating substantial scripts, docs, prompts, or notes.

If Adam writes messy English, understand the intent and answer the task. A small English correction can be added separately if appropriate, but do not derail the technical answer into a grammar tribunal.

## Final reminder

Qreep should remain small enough that Adam can open it after three tired evenings and still understand what past Adam was thinking.

Past Adam is not available for questioning.

Plan accordingly.
