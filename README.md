# Qreep

> A Quickshell-based desktop creature that is odd, small, memorable, slightly cursed, but friendly enough to become mine.

Qreep is my personal desktop shell for Hyprland.

It started as a Waybar-shaped learning project: one bar, a few pills, and the innocent belief that it would remain small. It has since grown into the place where I build the desktop surfaces I actually want to use — without trying to become a desktop environment, a universal framework, or a cathedral made entirely of QML.

![Qreep desktop](docs/assets/screenshots/qreep-bloom.png)

<https://github.com/user-attachments/assets/5e9fb318-65b9-4e78-a690-dedf9e144d90>

*A quiet desktop until I ask it to do something.*

## Why this creature exists

I like using things, but I also like understanding how they work.

Qreep is not an argument against Waybar, AGS, or somebody else's idea of a good desktop. Those projects helped me get here.

This one exists because learning is fun, experimentation is useful, and sometimes the best way to understand a shell is to build your own slightly questionable version of it.

It is the continuation of many ideas from my older AGS setup, now rebuilt around Quickshell and allowed to grow in a direction that feels more mine.

## What lives here

### The bar

The daily visible part of Qreep includes:

- Hyprland workspaces;
- clock and calendar;
- timer and countdown pill;
- POTATO fasting progress;
- MPRIS media controls;
- network, volume, battery, and power controls;
- launcher and monitor-profile controls;
- update checking;
- Borg backup state and progress.

The bar can run in `reserved`, `overlay`, or `collapsed` mode. Individual pills may also be enabled or expanded independently, because apparently even a bar can have moods.

#### Workspaces

The workspace pill shows the active workspace, occupied workspaces, and the windows living inside them.

![Qreep workspace menu](docs/assets/screenshots/qreep-workspace.png)

Workspace switching:

<https://github.com/user-attachments/assets/69f106ff-27a7-43da-b368-63fe93683370>

Workspace windows and taskbar behaviour:

<https://github.com/user-attachments/assets/33156a92-77e8-4b91-993a-25a1dbc9ff07>

#### MPRIS

The media pill stays compact until it has something useful to say.

![Qreep MPRIS tooltip](docs/assets/screenshots/qreep-mpris-tooltip.png)

<https://github.com/user-attachments/assets/5ad0ffaf-7cfa-4d5d-90c4-0612791ea183>

#### POTATO fasting

The POTATO fasting pill shows the current fast as a real progress bar, not a tiny terminal cosplay.

![Qreep POTATO fasting tooltip](docs/assets/screenshots/qreep-potato-tt.png)

#### Borg backup status

Qreep keeps an eye on Borg backups and can show both the last known state and live progress.

![Qreep Borg backup status](docs/assets/screenshots/qreep-borg.png)

<https://github.com/user-attachments/assets/b59055c3-1343-4cb4-a83b-8c5546354b1e>

#### Monitor profiles

The monitor-profile pill shows the active Hyprland monitor profile and keeps the switcher close by.

![Qreep monitor profile](docs/assets/screenshots/qreep-monitor.png)

<https://github.com/user-attachments/assets/9e4ecac1-b0f4-4320-a177-f031f07f1c14>

#### Network

Wired networking, Wi-Fi, and Bluetooth share one practical surface.

![Qreep network controls](docs/assets/screenshots/qreep-network.png)

#### Update checker

The bar tooltip gives the quick answer:

![Qreep update checker tooltip](docs/assets/screenshots/qreep-upchecker-tt-v2.png)

The larger surface handles the less quick answer:

![Qreep update checker](docs/assets/screenshots/qreep-upchecker-v2.png)

### Larger shell surfaces

Some things are too large to pretend they are bar widgets:

- **Expose** — a searchable, keyboard-friendly window overview;
- **Clipboard** — clipboard history with search and selection;
- **Notifications** — transient popups and a grouped notification centre;
- **OSD** — quiet on-screen feedback for volume and other shell messages;
- **Timer** — an IPC-opened count-up/countdown panel;
- **Dashboard** — a larger surface for useful blocks and experiments;
- **Aegis** — system information and monitoring;
- **Bloom** — progress feedback for my Unclaimed Bloom tooling.

They live as their own modules. The bar is allowed to open them, but it is not allowed to adopt all of them.

#### Expose

Expose groups windows by workspace, supports searching, and keeps keyboard navigation useful rather than ceremonial.

![Qreep Expose](docs/assets/screenshots/qreep-expose.png)

#### Clipboard

The clipboard picker supports text, images, colour values, searching, and keyboard navigation.

![Qreep clipboard picker](docs/assets/screenshots/qreep-clipboard.png)

#### Notifications

The notification centre groups notifications by application and keeps actions close enough to be useful.

![Qreep notification centre](docs/assets/screenshots/qreep-notification-center.png)

#### Dashboard

The dashboard gives larger blocks room to breathe without pretending they belong in a bar popup.

![Qreep dashboard](docs/assets/screenshots/qreep-dashboard.png)

#### Aegis

Aegis collects system, hardware, storage, memory, network, Borg, and Bloom information into one larger surface.

![Qreep Aegis system surface](docs/assets/screenshots/qreep-aegis.png)

Dashboard and Aegis in motion:

<https://github.com/user-attachments/assets/c17d8637-8525-4d2f-ade9-21c63748ae00>

### A clock that became a calendar

The clock popup grew into a calendar with local events, Google Calendar and Outlook/Microsoft calendar pulls, reminders, event dots, next personal-event hints, and change feedback.

This was not necessarily the plan. It is, however, useful.

<https://github.com/user-attachments/assets/ad8cf34a-fd57-4501-9b7c-3cd49073d6c7>

### Unclaimed Bloom

Qreep also listens to my [Unclaimed Bloom](https://github.com/Praczet/unclaimed-bloom) tooling and shows progress while the desktop changes its clothes.

![Qreep with an Unclaimed Bloom theme](docs/assets/screenshots/qreep-bloom.png)

<https://github.com/user-attachments/assets/264ad41b-b444-43d1-80a7-9058c3ac9ebe>

## The rules, approximately

Qreep follows a few practical rules:

- useful before universal;
- understandable before clever;
- personal before configurable for every hypothetical computer;
- small controls may live in the bar;
- larger surfaces must earn their own space;
- animations are welcome, provided they do not make the desktop drunk;
- learning is part of the purpose;
- the repository is allowed to grow, but not into a framework with feelings.

## Current condition

Qreep is alive, used, and still changing.

It is a personal configuration rather than a polished drop-in product. You are welcome to inspect it, borrow ideas, reuse pieces, or adapt it to your own desktop. Running the whole thing unchanged may also import several assumptions about my monitor layout, scripts, backups, calendars, and tolerance for animated details.

That seems unfair to both of us.

## Start

Install the helper scripts and user units:

```bash
scripts/install
```

Run Qreep:

```bash
quickshell -c qreep
```

For relaunching during development without accidentally spawning another copy:

```bash
quickshell -c qreep --no-duplicate
```

## A few useful IPC calls

```bash
quickshell ipc call qreep-bar setMode reserved
quickshell ipc call qreep-bar setMode overlay
quickshell ipc call qreep-bar setMode collapsed

quickshell ipc call qreep-expose toggle
quickshell ipc call qreep-clipboard toggle
quickshell ipc call qreep-notification toggleCenter
quickshell ipc call qreep-timer toggle
quickshell ipc call qreep-dashboard toggle
quickshell ipc call qreep-aegis toggle

quickshell ipc call osd showMessage "Qreep lives, somehow" 3000
```

Some Quickshell versions vary slightly in CLI syntax.

When IPC becomes philosophical:

```bash
quickshell ipc --help
```

## Where things live

```text
shell.qml                  top-level shell entry

modules/bar/               the bar
modules/bar/features/      bar-owned pills, services, and popups

modules/aegis/             system dashboard
modules/bloom/             Bloom progress surface
modules/clipboard/         clipboard picker
modules/dashboard/         dashboard engine and surface
modules/expose/            window overview
modules/notification/      notification server, popups, and centre
modules/osd/               on-screen display
modules/timer/             timer and countdown panel

components/                shared UI pieces
core/                      shared shell machinery
theme/                     public theme entry point and tokens
scripts/                   helpers and user services
```

## Documentation

This README is the lobby, not the municipal archive.

For the longer map — module inventory, theme notes, IPC details, layer rules, calendar setup, and the things future Adam will need after pretending he remembers everything — see [`README_when_bored.md`](README_when_bored.md).

## Why “Qreep”?

Because it is odd, small, memorable, slightly cursed, and somehow became mine.

## License

Qreep is free software licensed under the GNU General Public License
version 3 or later (`GPL-3.0-or-later`). See [LICENSE](LICENSE).
