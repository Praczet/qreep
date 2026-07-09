# Qreep

Qreep is Adam's Quickshell bar and shell-toy pile. It started as a
Waybar-shaped learning project and has grown into a practical Hyprland desktop
surface with a bar, a few popups, and some larger optional panels.

The short version:

- it is a Quickshell config;
- the bar is the daily visible bit;
- bigger things like clipboard, dashboard, expose, notifications, and OSD live
  as their own modules;
- this repo is allowed to be useful, but not allowed to become a framework with
  feelings.

If you want the longer map, read
[`README_when_bored.md`](README_when_bored.md). That file has the module list,
theme notes, IPC inventory, layer-rule notes, and the other things future Adam
will want after pretending he remembers everything.

## Start

Install helper scripts and user units:

```bash
scripts/install
```

Run the installed Quickshell config:

```bash
quickshell -c qreep
```

For relaunching while testing:

```bash
quickshell -c qreep --no-duplicate
```

That second command refuses to spawn another copy if one is already running.
Useful if you do not want to debug your own duplicate bar.

## Where Things Live

```text
shell.qml                  # top-level shell entry
modules/bar/               # the bar
modules/bar/features/      # bar-owned pills, services, and popups
modules/clipboard/         # shell-level clipboard picker
modules/dashboard/         # shell-level dashboard
modules/expose/            # shell-level window overview
modules/notification/      # notification popups and center
modules/osd/               # shell-level OSD
theme/                     # public theme entry point and tokens
components/                # shared UI bits
```

If you need the full inventory, again:
[`README_when_bored.md`](README_when_bored.md). This README is the lobby, not
the municipal archive.

## Useful IPC

```bash
quickshell ipc call qreep-bar setMode reserved
quickshell ipc call qreep-bar setMode overlay
quickshell ipc call qreep-bar setMode collapsed

quickshell ipc call qreep-dashboard toggle
quickshell ipc call qreep-aegis toggle
quickshell ipc call qreep-clipboard toggle
quickshell ipc call qreep-expose toggle
quickshell ipc call qreep-notification toggleCenter

quickshell ipc call qreep-borg refresh
quickshell ipc call qreep-upchecker refresh
quickshell ipc call qreep-calendar refresh
quickshell ipc call qreep-expose toggle
quickshell ipc call osd showMessage "Qreep lives, somehow" 3000
```

Some Quickshell versions vary slightly in CLI syntax. If IPC gets annoying,
check:

```bash
quickshell ipc --help
```

## Validation

Small useful checks:

```bash
qmllint modules/bar/Bar.qml
qmllint theme/QreepTheme.qml
qmllint modules/bar/features/*/*.qml
git diff --check
```

Runtime smoke test:

```bash
quickshell -c qreep --no-duplicate
```

If that says an instance is already running, the command did its job. Rare, but
we take the wins we can get.

## Calendar Pulls

The clock calendar can read local events, Google Calendar, and Outlook via the
Microsoft ICS path. Install helpers with `scripts/install`, then run:

```bash
qreep-calendar-pull
```

The optional user timer runs quietly every ten minutes:

```bash
systemctl --user enable --now qreep-calendar-sync.timer
```

Manual right-click pulls from the clock use desktop notification feedback.
Status lands in `~/.cache/qreep/calendar/final.json`.

## Expose

Expose is the shell-level window overview:

```bash
quickshell ipc call qreep-expose toggle
```

Start typing to filter windows. Arrow keys move selection. `Enter` or click
switches workspace when needed, focuses the selected client, and closes the
overview.
