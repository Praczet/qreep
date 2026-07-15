# Qreep

Qreep is Adam's Quickshell learning bar. It started as a Waybar-shaped
experiment and is now exactly the sort of thing that needs documentation before
future Adam starts guessing. Guessing is how tiny panels become archaeology.

## Run

From the Quickshell config install location:

```bash
quickshell -c qreep
```

Use this when relaunching during tests:

```bash
quickshell -c qreep --no-duplicate
```

That second command refuses to spawn another copy if one is already running.
Useful if you do not want a bar colony.

## Layout

```text
shell.qml
core/
components/
modules/
theme/
```

Top-level Qreep modules live under `modules/`. The bar module lives at
`modules/bar/` and bar-owned pills, panels, services, and popups live under
`modules/bar/features/`. Reusable wrappers remain in `components/`. Theme
entry points remain in `theme/`.

Current top-level module folders:

```text
modules/
├── aegis/
├── bar/
├── bloom/
├── clipboard/
├── dashboard/
├── expose/
├── fastpassword/
├── notification/
├── osd/
├── polkit/
└── timer/
```

Current bar-owned feature folders:

```text
modules/bar/features/
├── battery/
├── borg/
├── clock/
├── launcher/
├── language/
├── monitorprofile/
├── mpris/
├── network/
├── power/
├── potatofast/
├── timer/
├── upchecker/
├── volume/
└── workspaces/
```

## Bar

The main bar is `modules/bar/Bar.qml`.

It owns:

* the left, center, right, and overlay slots;
* shared services used by bar modules;
* shared tooltip surfaces;
* feature panels/popups that are opened from bar buttons.

The detailed ownership map lives in
[`docs/bar-ownership-map.md`](docs/bar-ownership-map.md). Read that before
moving feature surfaces around. It is cheaper than guessing, which remains a
popular but poorly reviewed debugging strategy.

The bar layer namespace is:

```qml
WlrLayershell.namespace: "qreep-bar"
```

Do not blur this layer unless you enjoy transparent edge artifacts and follow-up
questions from yourself.

## Hyprland Layer Rules

Use separate layer rules for separate surfaces. The bar is not the power panel.
This is a useful fact, despite everything trying to make it annoying.

Example shape:

```lua
hl.layer_rule({
    name = "qreep-bar",
    match = { namespace = "qreep-bar" },
    animation = "popin 85%",
})

hl.layer_rule({
    name = "qreep-power",
    match = { namespace = "qreep-popup-power" },
    blur = true,
    animation = "popin 85%",
    ignore_alpha = 0.5,
})

hl.layer_rule({
    name = "qreep-upchecker",
    match = { namespace = "qreep-popup-upchecker" },
    blur = true,
    animation = "popin 85%",
    ignore_alpha = 0.5,
})

hl.layer_rule({
    name = "qreep-notification",
    match = { namespace = "qreep-notification" },
    blur = true,
    ignore_alpha = 0.1,
})

hl.layer_rule({
    name = "qreep-notification-center",
    match = { namespace = "qreep-notification-center" },
    blur = true,
    ignore_alpha = 0.1,
})

hl.layer_rule({
    name = "qreep-polkit",
    match = { namespace = "qreep-polkit" },
    blur = true,
    ignore_alpha = 0.1,
})
```

`ignore_alpha` tells Hyprland not to blur behind pixels at or below that alpha
threshold. Higher values ignore more soft/transparent pixels. Good for avoiding
blur halos around rounded transparent surfaces.

## Theme

The public theme object is `theme/QreepTheme.qml`.

Root theme files:

* `theme/colors/UnclaimedBloomColors.qml`
* `theme/colors/template.qml`

Module theme files live with their owning module:

* `modules/ModulesTheme.qml`
* `modules/aegis/AegisTheme.qml`
* `modules/bar/BarTheme.qml`
* `modules/bar/BarPillTheme.qml`
* `modules/bar/TooltipTheme.qml`
* `modules/bloom/BloomTheme.qml`
* `modules/clipboard/ClipboardTheme.qml`
* `modules/dashboard/DashboardTheme.qml`
* `modules/expose/ExposeTheme.qml`
* `modules/fastpassword/FastPasswordTheme.qml`
* `modules/notification/NotificationTheme.qml`
* `modules/osd/OsdTheme.qml`
* `modules/polkit/PolkitTheme.qml`
* `modules/timer/TimerTheme.qml`

`QreepTheme.qml` exposes global semantic colors and the aggregated module theme:

```qml
readonly property QtObject modules: Modules.ModulesTheme {
    qreep: rootQreepTheme
}
```

Old paths such as `theme.module`, `theme.tooltip`, and `theme.dashboard` remain
as compatibility aliases for now. New module-specific code should prefer paths
like `theme.modules.aegis`, `theme.modules.bar.pill`,
`theme.modules.bar.tooltip`, `theme.modules.dashboard`, and
`theme.modules.notification`.

If a feature needs sizes, spacing, timing, or command names, put them in that
feature's theme file. Hardcoding in the button is how the next tweak becomes a
search warrant.

## IPC

Useful current targets:

```bash
quickshell ipc call qreep-borg refresh
quickshell ipc call qreep-borg showProgress
quickshell ipc call qreep-borg hideProgress
quickshell ipc call qreep-borg toggleProgress
quickshell ipc call qreep-potato-fast refresh
quickshell ipc call qreep-upchecker refresh
quickshell ipc call qreep-upchecker toggle
quickshell ipc call qreep-monitor-profile refresh
quickshell ipc call qreep-calendar refresh
quickshell ipc call qreep-calendar notifyChangedAll
quickshell ipc call qreep-calendar notifyChanged EVENT_ID
quickshell ipc call qreep-power toggle
quickshell ipc call qreep-power toggleFullscreen
quickshell ipc call qreep-aegis toggle
quickshell ipc call qreep-dashboard toggle
quickshell ipc call qreep-bloom pickupBloom
quickshell ipc call qreep-clipboard toggle
quickshell ipc call qreep-expose toggle
quickshell ipc call qreep-notification toggleCenter
quickshell ipc call qreep-polkit demo
quickshell ipc call qreep-polkit registrationState
quickshell ipc call qreep-timer toggle
quickshell ipc call osd showMessage "Hello from the questionable future" 3000
```

Notification center commands:

```bash
quickshell ipc call qreep-notification toggleCenter
quickshell ipc call qreep-notification showCenter
quickshell ipc call qreep-notification hideCenter
quickshell ipc call qreep-notification dismissAll
```

Aegis commands:

```bash
quickshell ipc call qreep-aegis toggle
quickshell ipc call qreep-aegis showMe
quickshell ipc call qreep-aegis hideMe
quickshell ipc call qreep-aegis refresh
quickshell ipc call qreep-aegis setMode full
```

Dashboard commands:

```bash
quickshell ipc call qreep-dashboard toggle
quickshell ipc call qreep-dashboard showMe
quickshell ipc call qreep-dashboard hideMe
quickshell ipc call qreep-dashboard refresh
```

Clipboard commands:

```bash
quickshell ipc call qreep-clipboard toggle
quickshell ipc call qreep-clipboard showMe
quickshell ipc call qreep-clipboard hideMe
quickshell ipc call qreep-clipboard refresh
```

Expose commands:

```bash
quickshell ipc call qreep-expose toggle
quickshell ipc call qreep-expose showMe
quickshell ipc call qreep-expose hideMe
quickshell ipc call qreep-expose refresh
```

Fast Password commands:

```bash
quickshell ipc call qreep-fast-password toggle
quickshell ipc call qreep-fast-password showMe
quickshell ipc call qreep-fast-password hideMe
quickshell ipc call qreep-fast-password refresh
quickshell ipc call qreep-fast-password copy "Work/DB"
```

The panel first authenticates through `qreep-pass-auth`, then lists allowed
entry names through `qreep-pass-list`, and copies through `qreep-pass-copy`.
The copy helper checks for the existing Polkit authorization without opening a
second prompt, enforces the same allowlist, and copies with
`wl-copy --sensitive`. All three use or support the same Polkit action:
`art.druzd.adam.qreep.pass.copy`. The installed policy uses `auth_self_keep` so
the copy step can reuse the short-lived authorization from opening the chooser.

Visible entries come from:

```text
~/.config/qreep/fast-password.json
```

Example:

```json
{
  "entries": [
    "Work/DB"
  ]
}
```

QML does not receive the password value. If direct `passw` is still callable, it
remains a bypass; this module protects the Qreep path, not the entire user
session from itself.

Polkit commands:

```bash
quickshell ipc call qreep-polkit demo
quickshell ipc call qreep-polkit showMe
quickshell ipc call qreep-polkit hideMe
quickshell ipc call qreep-polkit toggle
quickshell ipc call qreep-polkit registrationState
quickshell ipc call qreep-polkit showLog
quickshell ipc call qreep-polkit logPath
```

The Polkit module in `modules/polkit/` now creates a real Quickshell
`PolkitAgent`. It only becomes the actual password prompt when it successfully
registers for the session. If `hyprpolkitagent` is already running, Qreep loses
that registration race and the existing agent still owns the real prompts.

For a focused test:

```bash
systemctl --user stop hyprpolkitagent
quickshell -c qreep --no-duplicate
quickshell ipc call qreep-polkit registrationState
pkexec true
systemctl --user start hyprpolkitagent
```

`pkexec true` asks for authentication and then does nothing interesting, which
is exactly the sort of test command an auth prompt deserves.

Artwork is pulled from repo `assets/icon_*` images and cropped into the left
side of the dialog. Runtime log lines land in the Quickshell log for the active
instance:

```bash
find "/run/user/$UID/quickshell/by-id" -name log.qslog -print
```

Look for `Qreep info: Polkit ...`. Do not log passwords. This is not a diary.

Timer commands:

```bash
quickshell ipc call qreep-timer toggle
quickshell ipc call qreep-timer showMe
quickshell ipc call qreep-timer hideMe
quickshell ipc call qreep-timer startTimer "Focus"
quickshell ipc call qreep-timer startCountdown 25m "Pomodoro"
quickshell ipc call qreep-timer startCountdownUntil 15:03 "Tea"
quickshell ipc call qreep-timer setNotificationMode osd
quickshell ipc call qreep-timer pause
quickshell ipc call qreep-timer resume
quickshell ipc call qreep-timer toggleRunning
quickshell ipc call qreep-timer stop
```

The timer panel is a top-level shell surface in `modules/timer/`. It supports a
count-up timer, countdowns, finish-at times, duration presets, labels,
pause/resume, stop, Tab navigation, and selectable completion feedback through
either `notify-send` or Qreep OSD. Duration parsing accepts plain minutes (`25`)
or `h`/`m`/`s` strings such as `1h30m` and `45s`. Finish-at parsing accepts
local `HH:MM` such as `15:03`.

Timer OSD completion uses bottom-center placement, the `Time's up` title, a
128px `alarm-symbolic` icon, and a 10 second display duration. Subtle? No.
Useful from across the room? More likely.

The active timer is shown by `modules/bar/features/timer/TimerButton.qml`.
Countdowns use a circular pie fill from empty to full. Count-up timers show the
elapsed time as plain text because sometimes the correct UI is not a tiny
festival.

When a countdown completes, the timer pill shakes and pulses three times, then
stays warning-colored until any pill click acknowledges it. Left, middle, and
right click still clear that visual warning; middle click restarts a completed
countdown from empty, otherwise it keeps the usual pause/resume job.

Timer state is persisted at `~/.cache/qreep/timer/state.json`, so count-ups,
countdowns, and the selected completion feedback mode survive Quickshell
restarts.

Expose behavior:

```text
current workspace windows -> large cards
other workspaces          -> compact cluster cards
typing                   -> reveal search and filter clients
arrow keys               -> spatial selection, including cluster mini-cards
Enter / click            -> switch workspace if needed, focus client, close
```

Current-workspace thumbnails are captured in parallel with `grim -g` before
the overlay opens. The overview layout is manual and grid-shaped, not a QML
`Grid`, so filtered cards can animate into their new positions instead of
teleporting because a layout object felt helpful.

Clock event dots are still popup-based so they sit neatly under the pill. The
bar suppresses them while Dashboard, Expose, or fullscreen Power is open,
because separate popup windows do not politely hide behind fullscreen shell
surfaces by themselves.

Bloom commands:

```bash
quickshell ipc call qreep-bloom showBloom default ""
quickshell ipc call qreep-bloom doneBloom
quickshell ipc call qreep-bloom pickupBloom
quickshell ipc call qreep-bloom hideBloom
```

The notification test helper sends a mixed batch for popup and center layout
checks:

```bash
scripts/qreep-notification-test-batch_v0.0.1
scripts/qreep-notification-test-batch_v0.0.1 --delay 0.4
```

Qreep must own `org.freedesktop.Notifications` for that helper to test Qreep.
If another notification daemon owns it, Qreep logs that it could not register
and the notifications go somewhere else. Very democratic. Not helpful.

Install stable helper names and the calendar user units:

```bash
scripts/install
```

That copies the current versioned helper scripts to `~/.local/bin`, including:

```text
qreep-calendar-sync
qreep-calendar-google-sync
qreep-calendar-microsoft-ics-sync
qreep-calendar-microsoft-sync
qreep-calendar-pull
qreep-region-screenshot-delay
```

It also installs:

```text
~/.config/systemd/user/qreep-calendar-sync.service
~/.config/systemd/user/qreep-calendar-sync.timer
```

Enable the timer only when wanted:

```bash
systemctl --user enable --now qreep-calendar-sync.timer
```

Pill state commands use two separate ideas:

```bash
quickshell ipc call qreep-bar-pill enablePill clock    # add pill to the bar
quickshell ipc call qreep-bar-pill disablePill clock   # remove pill from the bar
quickshell ipc call qreep-bar-pill expandPill clock    # full-size in collapsed mode
quickshell ipc call qreep-bar-pill collapsePill clock  # collapsed strip in collapsed mode
quickshell ipc call qreep-bar-pill listPills           # list known pill state
```

So in collapsed mode, `enablePill` makes the pill present, and `expandPill`
makes it full-size. Separate switches. Fewer surprise side effects, which is a
lifestyle choice.

Current known runtime pills are `clock`, `workspaces`, `mpris`, `timer`,
`upchecker`, `monitorprofile`, `borg`, `potato-fast`, `battery`, `network`,
`language`, and `volume`.
Unknown pill IDs return an error instead of inventing state for `banana`, which
is growth.

The POTATO fasting pill lives first in the center slot, before the clock and
MPRIS. It polls `potato-fast --json`, renders `percentage` as an actual bar
fill, and refreshes through:

```bash
quickshell ipc call qreep-potato-fast refresh
```

The `potato-sync` helper also calls that IPC target after writing
`~/.cache/potato/health.json`, using the `qreep` Quickshell config by default.
That is the small acknowledgement pulse after the paperwork changes, not a new
state store. POTATO owns the data; Qreep displays it.

Some Quickshell versions vary slightly in CLI syntax. If this bites, check:

```bash
quickshell ipc --help
```

## Event JSON

Clock events are loaded from:

```text
events.json
~/.cache/qreep/calendar/events.json
~/.cache/qreep/calendar/microsoft-events.json
```

Expected shape:

```json
{
  "events": [
    {
      "date": "2026-06-25",
      "title": "Meeting",
      "start": "14:00",
      "end": "15:00",
      "allDay": false
    }
  ]
}
```

The clock shows current-day dots. The calendar popup shows a month grid, a
selected-day agenda, optional next personal-event hints, and a footer with last
pull status:

```text
Google: yyyy-MM-dd HH-mm-ss (status) | Microsoft: yyyy-MM-dd HH-mm-ss (status)
```

Personal events are still detected by the deliberately small `AD...` title
prefix rule. When `CalendarTheme.showUpcomingPersonalEvents` is enabled, the
clock tooltip and today's agenda append up to
`CalendarTheme.upcomingPersonalEventLimit` upcoming personal events after the
normal remaining-today events. Already-listed today events are skipped. Nobody
needs a duplicate appointment pretending to be insight.

Clock click behavior:

```text
left   -> open calendar
middle -> toggle seconds
right  -> confirm a manual calendar pull
```

Manual pulls run:

```bash
qreep-calendar-pull --notify
```

The timer uses the quiet default:

```bash
qreep-calendar-pull
```

Pull state is written to:

```text
~/.cache/qreep/calendar/state.json
~/.cache/qreep/calendar/final.json
```

`state.json` is updated while the pull runs. `final.json` is the last finished
summary. The wrapper runs configured providers, prefers Microsoft ICS over the
Microsoft Graph route when both configs exist, and leaves the provider scripts
to do the actual fetch/cache-refresh work. Boring boundaries. Useful boundaries.

## Monitor Profile JSON

Monitor profile state is read from:

```text
${XDG_RUNTIME_DIR:-/tmp}/hypr-monitor-profile-qreep.json
```

QML does not expand shell syntax, so the service builds that path with
`Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"`.

The service expects a `layout` array with `position`, `display_name`,
`external`, and optional `display.mode`/`display.scale` values. It sorts monitors
by position and renders a compact icon summary.

## Validation

Small useful checks:

```bash
qmllint modules/bar/Bar.qml
qmllint theme/QreepTheme.qml
qmllint modules/bar/features/mpris/MprisService.qml
qmllint modules/aegis/*.qml
qmllint modules/dashboard/*.qml
qmllint modules/notification/*.qml
```

For broader changes:

```bash
qmllint modules/bar/Bar.qml theme/QreepTheme.qml modules/bar/features/*/*.qml
```

Runtime smoke test:

```bash
quickshell -c qreep --no-duplicate
```

If it says an instance is already running, that is not a failed launch. It is the
command doing what the flag says. Suspiciously rare behavior.
