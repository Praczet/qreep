# KIP — Implementation Brief for Coding Agent

You are implementing **KIP — Knowledge & Intelligence Presence** inside the existing **QREEP** QuickShell/Qt Quick project on Arch Linux + Hyprland.

**Read this entire brief before editing anything.** Treat it as a staged implementation, not permission to implement every future idea immediately.

## Vision

KIP is a small, responsive, playful **desktop presence**, not a generic chatbot window. It starts as a summonable animated prompt and later becomes an adaptive gateway to local knowledge and system capabilities. Its interface should feel as if it **materializes from a single line**, then unfolds organically around the input — restrained Tony Stark/J.A.R.V.I.S.-style motion, not an overwhelming HUD.

KIP is the **QuickShell front end**. The existing `~/.local/bin/jarvis` Python executable is the **temporary backend**. Do not rename Jarvis, rewrite its retrieval engine, or merge KIP into the old launcher in this task.

**Primary keyboard shortcut: `SUPER + K`** (not `SUPER + SHIFT + J`).

## Existing project and environment — inspect, do not assume

- Repository: QREEP (`Praczet/qreep`), implemented with QuickShell/QML and existing theme, components and modules.
- Environment: Arch Linux, Hyprland, Ghostty; the user prefers keyboard-first operation.
- Jarvis indexes **all of `~/Notes`**, including `~/Notes/Logseq` and legacy notes under `~/Notes/toreview`; the index lives separately in SQLite.
- Jarvis uses `nomic-embed-text-v2-moe` for semantic retrieval and Ollama/Qwen for answers.
- Jarvis currently exposes `--json -search-notes <query>` as a single JSON result and `--json -ask-notes <question>` plus `--json <general question>` as newline-delimited streaming JSON (NDJSON). Confirm the *actual installed* output before depending on it.

**Mandatory reconnaissance:** Read repository `AGENTS.md`, project README, `shell.qml` and any relevant QREEP instructions. Inspect how existing modules register with the shell; find working examples of independent panels, IPC toggle methods, keyboard focus, panel dismissal, styling, colors, animations, `Quickshell.Io.Process`, `StdioCollector`, and command launchers. Reuse conventions and shared components. Don't invent APIs or paths. Inspect current Hyprland keybind organization and avoid overwriting existing `SUPER + K` behavior silently; raise a conflict if present. Produce a brief architecture/implementation plan before code edits.

## Scope / delivery order

**Two explicit phases. Phase 1 must be demonstrable and approved before Phase 2 begins.** Do not skip ahead to backend integration because the JSON protocol seems easy.

### PHASE 1 — KIP's animated UI and its soul (FIRST PRIORITY)

Implement a self-contained QuickShell module or equivalent aligned with actual QREEP architecture. It must run convincingly **without Ollama or Jarvis** using simulated local data and actions. No heavy dependencies.

#### Opening motion — single originating shape

The interface should appear through a coordinated sequence:

1. `SUPER + K` invokes a **toggle**. An initial **thin horizontal luminous line** appears at or near the upper screen edge. Do not display an ordinary window abruptly.
2. The line **descends** to an adjustable vertical anchor, initially **100 px from the top** of the active monitor (configurable; DPI/scaling-aware). The line may expand horizontally during descent.
3. The line **morphs into a rounded input box**, with continuous changes in height, width, border radius, opacity and optional subtle glow. Avoid disconnected hard cuts.
4. From behind this input, the surrounding UI **assembles outward**: the KIP label emerges above, an icon reveals toward the left, a `Local AI` status toward the right, and a body unfolds downward, revealing status/hints. The input is the visual origin point for the whole composition; other elements should feel attached to its motion.
5. After the assembly, KIP is compact and ready for typing. On demand it can grow downwards to display search hits or AI output. The input remains visually anchored; result content expands around/below it.
6. Closing should reverse/retract naturally (faster than opening), but **rapid repeated toggles** must never leave the panel stuck or ghosted.

Use one coordinated state machine or a similarly explicit transition coordinator, not loosely competing animations. Suggested phases: `hidden → signal → descend → morph → assemble → ready → processing → results`, plus closing/error paths. Timing can be tuned (roughly 700–950 ms full opening, faster closing), but judge by feel rather than rigid values. Use Qt Quick animation primitives and clip reveal regions where appropriate. Keep animations performant on Intel Iris Xe; avoid expensive shaders or animation-driven layouts that thrash every frame.

**Critical:** The text input obtains keyboard focus immediately on toggle; users can begin typing *during* the opening animation without dropped keystrokes. Escape closes; `SUPER + K` toggles. Clicking outside should dismiss if consistent with QREEP conventions. Keep positioning correct across monitor sizes, HiDPI scale and multi-monitor placement. Provide reduced-motion / no-animation configuration.

#### Command-aware live interaction

The input is not a static prompt. **KIP reacts as the user types**, with no LLM roundtrip.

- Typing `/` reveals available commands, with sensible suggestions.
- Typing `/ask` recognizes a command candidate.
- Typing `/ask ` (note the trailing space) **activates** `ask.ready`: instantly highlight the recognized command and morph the lower body into contextual help. No Enter needed.
- Text typed after the space is treated as the argument; the UI shows a clear Enter-to-submit action. Avoid resetting the recognition state on each keystroke.
- `/notes ` activates `notes.ready` with an explanation of semantic notes search.
- `/help` can show the command palette/help.
- Unknown `/...` commands get helpful, calm feedback rather than routing silently to an AI model.
- Plain text can be assigned a general-question mode in later phases; in Phase 1 simulate its behavior and make the mode explicit.
- Show command-specific icon, label, status, helper text and any relevant model/source hint; coordinate subtle transitions of the lower region as modes change.
- Support keyboard navigation and a reliable multiline or single-line submission policy; document it. Do not hijack editor shortcuts unexpectedly.

Make command definitions **data-driven** (registry: name, aliases if needed, description, event key, argument placeholder, icon, execution kind) so the UI can grow without hardcoding logic in the visual component.

#### KIP's 'soul' — tasteful rotating microcopy

KIP should have a recognizable voice: observant, playful, dry, occasionally theatrical, mildly self-important but genuinely helpful. It must **demonstrate wit rather than announce that it is witty**. Keep it compact and avoid condescension, endless sarcasm, repetitive greetings, fake actions and alarming jokes. If no playful line fits, prefer a neutral helpful one.

Use event keys, for example:

- `kip.open`, `kip.ready`
- `ask.ready`, `ask.submitted`, `ask.generating`, `ask.completed`
- `notes.ready`, `notes.searching`, `notes.found`, `notes.empty`
- `error.backend`, `error.generic`

For each state, supply a curated set of short, event-correct messages and select one when **entering the state**, not on every keystroke. Allow future tonal modes (neutral / dry / flavored) without implementing a complex personality engine now. Messages are **instant and offline**. A possible future feature is background generation and curation via Qwen 3.5 2B, but **do not block the UI on AI generation and do not implement online generation in Phase 1**.

Example `ask.ready` messages (seed variants; revise for quality):
- “A question? Splendid. I was running out of things to judge.”
- “Go ahead. I'll consult the notes before consulting my imagination.”
- “Ask away. I have an alarming amount of confidence.”
- “Your question, please. The archives are pretending to be organized.”
- Neutral: “Ask a question. I'll search your indexed notes for context.”

**Truthful state language:** When `/ask ` is typed, KIP may explain its intended workflow, but must not say “Searching...” or “Found three notes” until real backend events establish it in Phase 2.

#### Visual direction

Use the QREEP shared theme and current component vocabulary, optionally embracing Tokyonight-Moon-like tones when they correspond to existing tokens. Distinguish icon, folder, filename, status and hints subtly. Prefer legibility and hierarchy over neon decoration. Keep a compact minimum width (e.g. 700–850 px on spacious monitors), but **responsively clamp** to smaller displays. Do not hardcode giant fixed panels. Hover/focus/selection states should feel polished. Animations should be cancellable and keyboard interactions immediate.

#### Phase 1 demo and exit criteria

Provide a standalone way to summon KIP with `SUPER + K` (after handling any keybinding collision), with mock data. Demonstrate:

1. Hidden → thin line → descent → morph → outward assembly.
2. Input accepts text during animation.
3. `/ask ` instantly changes command state and lower content; rotating message remains stable while the user continues typing.
4. `/notes ` changes to notes mode; unknown commands receive an explanation.
5. Enter shows mock searching/loading/results; results can be navigated; no Jarvis required.
6. Escape and repeated fast toggles work reliably.
7. Reduced motion, different resolutions/scaling and backend-absent states don't break the layout.

**STOP HERE for visual review.** Present what was implemented, how to run it and what design choices remain. Don't start Phase 2 until Phase 1 is accepted.

### PHASE 2 — Connect KIP to the existing Jarvis backend

After Phase 1 approval, replace mocked command execution with a small, testable adapter. Keep KIP and Jarvis separate.

#### Backend protocol

- Notes search: `jarvis --json -search-notes "<query>"` → one valid JSON object containing ranked results and source metadata.
- Notes-based answer: `jarvis --json -ask-notes "<question>"` → NDJSON events such as `response.start`, `response.sources`, `response.delta`, `response.done`.
- General question: `jarvis --json "<question>"` → NDJSON response events.

**Verify** the installed version's exact schema with real invocations. Do not assume the examples are normative if actual fields differ. Keep **stdout machine-readable only**, error/log diagnostics on stderr. For KIP, route `/notes` to note search and `/ask` to note-grounded answers. Plain text can route to general chat after explicit UX review. Do not trigger full re-indexing on each query.

#### Process control and responsiveness

Use existing QuickShell process/IO patterns to invoke Jarvis safely. Pass argv items as separate arguments — no shell interpolated command strings. Capture process exit status and stderr separately from JSON. Parse complete NDJSON lines incrementally, buffering partial lines. `response.delta` fragments append to **one growing answer**, not separate UI bubbles. Preserve sources with path and line range independent of model-generated citations. Cancel/stale-response-protect running processes on dismiss, replacement requests or new submissions; never let late responses overwrite newer state. Show real progress only for received events. Distinguish Ollama unavailable, index missing, malformed JSON and zero results. Provide retry/helpful diagnostics without crashing the shell.

#### Search UI and answer UI

- `/notes`: show ranked notes with **folder in one theme color, basename in another**, matching text/excerpt, line numbers and origin (Logseq/legacy). Group repeated chunks by file where sensible. Keyboard Up/Down, Enter to open the source at the relevant position via QREEP's existing safe opener/editor convention; copy path/action as appropriate. Do not invent files or links.
- `/ask`: show source references and a concise streamed answer, updating smoothly without reflow flicker. For code or SQL, offer original retrieved source snippet rather than trusting the model to reconstruct it perfectly. Avoid showing “SOURCE 3” alone when a real path/line range is available.
- Continue to use local, curated personality messages for instant state changes. Jarvis provides substantive results, not decorative UI timing.

#### Phase 2 exit criteria

1. Actual `/notes MariaDB permissions` returns selectable results from `~/Notes` (including `Logseq` and `toreview`).
2. Actual `/ask How do I inspect MariaDB user privileges?` shows sourced answer and original notes/code where applicable.
3. All normal terminal Jarvis commands still work; do not break `-search-notes`, `-ask-notes` or general chat.
4. KIP handles a slow or unavailable backend gracefully, with cancellation and no frozen input.
5. Multi-monitor, hotkey toggle, and animated transitions remain stable with streaming content.

## Out of scope for these first two phases

No app-launcher replacement or app launching; no arbitrary shell execution; no automatic file deletion/editing; no autonomous agent loops; no document reorganization; no voice assistant; no renaming `jarvis` to `kip`; no reimplementing Nomic/SQLite; no Rust/Ratatui rewrite; no new long-running daemon unless a concrete need is demonstrated. KIP may eventually unify launcher, window switching, desktop automation, file search and AI, but **do not implement that future scope now**.

## Quality constraints and handoff

- Prefer small, cohesive modules and follow existing QREEP module/service/theme patterns. Avoid circular dependencies or duplicating launcher logic.
- Make geometry, timings, message sets, and hotkey configurable through the repository's established approach.
- Keep every state observable and testable; separate command parsing, view state, animation coordination and backend transport.
- Accessibility: strong focus indicators, readable contrast, reduced motion, graceful keyboard-only use.
- Run applicable format/lint/QML validation and any repository tests. For manual-only animation behaviors, provide a precise manual checklist and note what was not tested.
- Do not claim a command or visual result was tested unless it was actually run/observed.
- Maintain any repository documentation / changelog conventions and explain new IPC methods, paths and keybinds.
- At each phase handoff: summarize modified files, commands to run, screenshots/video instructions for manual visual verification, test outcomes, known limitations, and recommended next changes. Do not silently over-expand scope.

## Immediate instruction

**Start with repository reconnaissance and a concise Phase 1 implementation plan. Then implement ONLY the animated KIP interface, reactive slash-command recognition, curated microcopy and mock result displays. Stop for design review before connecting Jarvis.**
