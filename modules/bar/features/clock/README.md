# Clock Feature

## What It Does

Shows time/date in the center bar slot. Left click opens the calendar popup.
Right click toggles seconds. Current-day events are shown as small dots on the
module edge.

The calendar popup shows the current month, lets you move between months, and
uses the selected day for the agenda column. It opens on today because that is
usually the point of a clock. Rare moment of cooperation from reality.

## Files

* `Clock.qml` - bar clock module.
* `CalendarPopup.qml` - month grid, selected-day agenda, and popup keyboard handling.
* `CalendarReminder.qml` - runtime reminder notifications for upcoming timed events.
* `EventStore.qml` - watches and parses `events.json`.
* `ClockTheme.qml` - clock sizes and event-dot tokens.
* `CalendarTheme.qml` - calendar layout tokens.

## Where To Change Things

Change time/date sizing in `ClockTheme.qml`. Change calendar layout, selected
day colors, and month navigation sizing in `CalendarTheme.qml`. Change event
parsing/filtering in `EventStore.qml`.

Reminder defaults live in `CalendarTheme.qml`:

* `useDefaultReminders` - when true, events without reminder data still notify.
* `defaultReminderMinutes` - fallback minutes when `useDefaultReminders` is true.
* `reminderCheckInterval` - how often Qreep scans upcoming events.

## Wiring

`modules/bar/Bar.qml` creates `EventStore`, passes it to `Clock`, and hosts
`CalendarPopup`.

`EventStore.qml` exposes IPC for manual cache reloads:

```bash
quickshell -c qreep ipc call qreep-calendar refresh
```

It also exposes a visual change notification for the clock dots:

```bash
quickshell -c qreep ipc call qreep-calendar notifyChangedAll
quickshell -c qreep ipc call qreep-calendar notifyChanged EVENT_ID
```

If `EVENT_ID` matches one of the visible clock dots, that dot pulses. If
`notifyChangedAll` is called, or the id is not currently visible, the visible
dots pulse in sequence.

Pulse size, duration, loop count, and the primary/warning/error/warning color
sequence live in `ClockTheme.qml`.

Provider sync scripts compare the previous generated cache with the newly
downloaded one before writing. Future/remaining events for today that are added,
edited, or removed trigger the dot notification after the script asks Qreep to
reload the calendar cache. Past events are ignored. Multiple changed events use
the all-dots sequence because tiny dots are not a changelog.

Note: This is a bar-owned feature. Sources live under `modules/bar/features/clock/`.

Theme is exposed through:

```qml
readonly property QtObject clock: ClockFeature.ClockTheme {}
readonly property QtObject calendar: ClockFeature.CalendarTheme {}
```

## Service Notes

`EventStore.qml` uses `FileView` to watch three event files:

```text
events.json
~/.cache/qreep/calendar/events.json
~/.cache/qreep/calendar/microsoft-events.json
```

`events.json` is the repo-local/manual source. The generated cache files are
where provider sync helpers write normalized read-only events. If a cache file
does not exist, Qreep ignores it. Very mature. Did not even panic.

The old tiny shape still works:

```json
{ "events": [{ "date": "2026-06-25", "title": "Meeting" }] }
```

Timed events may use `start`, `end`, and `allDay`.

Internally, events are normalized into the shape Qreep expects future sync
helpers to write:

```json
{
  "events": [
    {
      "id": "local:work:2026-07-09:standup",
      "source": "local",
      "calendar": "Work",
      "title": "Standup",
      "date": "2026-07-09",
      "start": "09:30",
      "end": "09:45",
      "allDay": false,
      "location": "Desk, allegedly",
      "url": "",
      "color": "#88c0d0",
      "reminderMinutes": [10],
      "busy": true
    }
  ]
}
```

`source`, `calendar`, `location`, `url`, `color`, `reminderMinutes`, and
`busy` are optional for hand-written local events. External sync should prefer
writing the normalized fields instead of making QML learn provider dialects.
If a cache event omits `source`, Qreep marks it as `generated`.

## Reminder Notes

`CalendarReminder.qml` sends `notify-send` reminders for timed events. All-day
events and events without a start time are skipped. If an event has
`reminderMinutes`, those offsets are used. Otherwise Qreep uses
`defaultReminderMinutes` only when `useDefaultReminders` is true.

Reminder de-duplication is runtime-only for now. Restarting Qreep inside the
same reminder window can notify again. Annoying, but less annoying than inventing
persistence before the provider sync exists.

## Generated Cache Helper

`scripts/qreep-calendar-sync_v0.0.1` normalizes event JSON and writes the
generated cache:

```bash
scripts/qreep-calendar-sync_v0.0.1 --input provider-events.json
```

The default output is:

```text
~/.cache/qreep/calendar/events.json
```

For testing without touching the live cache:

```bash
scripts/qreep-calendar-sync_v0.0.1 --input events.json --output /tmp/qreep-calendar-events.json
```

Install the stable command name with:

```bash
install -Dm755 scripts/qreep-calendar-sync_v0.0.1 "$HOME/.local/bin/qreep-calendar-sync"
```

This helper does not authenticate to Google or Microsoft yet. It is the boring
cache writer that provider-specific sync code can feed. Boring is the point;
OAuth will bring enough paperwork by itself.

## Google Calendar Sync

`scripts/qreep-calendar-google-sync_v0.0.1` fetches Google Calendar events with
the read-only Calendar Events scope and writes the generated cache.

It expects config outside the repo:

```text
~/.config/qreep/calendar/google.json
```

Minimal config:

```json
{
  "client_id": "your-google-oauth-client-id",
  "client_secret": "optional-for-installed-client",
  "calendars": [
    { "id": "primary", "name": "Google" }
  ]
}
```

Tokens are stored outside the repo:

```text
~/.local/state/qreep/calendar/google-token.json
```

Run:

```bash
scripts/qreep-calendar-google-sync_v0.0.1
```

After writing the cache, the script asks a running Qreep instance to reload
calendar caches through `qreep-calendar refresh`. If Qreep is not running, the
cache is still written and will be loaded on next start. Use
`--no-qreep-refresh` to skip the IPC call.

For a terminal-only auth URL:

```bash
scripts/qreep-calendar-google-sync_v0.0.1 --no-browser
```

The script uses a local loopback OAuth callback and requests:

```text
https://www.googleapis.com/auth/calendar.events.readonly
```

It fetches a bounded window by default: seven days back and forty-five days
forward. That is enough for the bar without asking Google for your entire
temporal autobiography.

Install the stable command name with:

```bash
install -Dm755 scripts/qreep-calendar-google-sync_v0.0.1 "$HOME/.local/bin/qreep-calendar-google-sync"
```

## Microsoft Calendar Sync

There are two Microsoft paths because Entra permissions are a little kingdom
with a clipboard.

Use `scripts/qreep-calendar-microsoft-ics-sync_v0.0.1` when the tenant blocks
app registrations but Outlook lets you share a read-only `.ics` URL. It writes
the Microsoft cache file:

```text
~/.cache/qreep/calendar/microsoft-events.json
```

It expects config outside the repo:

```text
~/.config/qreep/calendar/microsoft-ics.json
```

Minimal config:

```json
{
  "url": "https://outlook.office365.com/owa/calendar/.../reachcalendar.ics",
  "calendar": "Outlook"
}
```

Treat the `.ics` URL like a password-adjacent object. Anyone with the URL may
be able to read that shared calendar.

Run:

```bash
scripts/qreep-calendar-microsoft-ics-sync_v0.0.1
```

After writing the cache, the script asks a running Qreep instance to reload
calendar caches through `qreep-calendar refresh`. If Qreep is not running, the
cache is still written and will be loaded on next start. Use
`--no-qreep-refresh` to skip the IPC call.

Install the stable command name with:

```bash
install -Dm755 scripts/qreep-calendar-microsoft-ics-sync_v0.0.1 "$HOME/.local/bin/qreep-calendar-microsoft-ics-sync"
```

`scripts/qreep-calendar-microsoft-sync_v0.0.1` is the Microsoft Graph route. It
fetches Outlook calendar events with delegated read-only calendar access. Use it
when you can create an app registration or an admin gives you a client ID.

It expects config outside the repo:

```text
~/.config/qreep/calendar/microsoft.json
```

Minimal config:

```json
{
  "client_id": "your-microsoft-application-client-id",
  "tenant": "common",
  "calendars": [
    { "id": "default", "name": "Outlook" }
  ]
}
```

Use `tenant: "organizations"` for work/school-only sign-in, or a tenant ID if
that is what the office paperwork demands today. The app registration needs a
public/native redirect URI for loopback auth, such as:

```text
http://localhost
```

Tokens are stored outside the repo:

```text
~/.local/state/qreep/calendar/microsoft-token.json
```

Run:

```bash
scripts/qreep-calendar-microsoft-sync_v0.0.1
```

After writing the cache, the script asks a running Qreep instance to reload
calendar caches through `qreep-calendar refresh`. If Qreep is not running, the
cache is still written and will be loaded on next start. Use
`--no-qreep-refresh` to skip the IPC call.

For a terminal-only auth URL:

```bash
scripts/qreep-calendar-microsoft-sync_v0.0.1 --no-browser
```

The default output is:

```text
~/.cache/qreep/calendar/microsoft-events.json
```

The script requests:

```text
offline_access https://graph.microsoft.com/Calendars.Read
```

It fetches a bounded window by default: seven days back and forty-five days
forward.

Install the stable command name with:

```bash
install -Dm755 scripts/qreep-calendar-microsoft-sync_v0.0.1 "$HOME/.local/bin/qreep-calendar-microsoft-sync"
```

## Scheduled Pulls

`scripts/qreep-calendar-pull_v0.0.1` is the boring wrapper for regular pulls.
It runs configured providers, then writes:

```text
~/.cache/qreep/calendar/state.json
~/.cache/qreep/calendar/final.json
```

`state.json` is updated while the pull is running. `final.json` is the last
finished pull summary. Provider scripts still own provider-specific fetching
and Qreep refresh/notification; the wrapper owns the readable "what happened
last time" report.

By default the wrapper runs providers that have config files. If both Microsoft
configs exist, it prefers the ICS route because both Microsoft routes write the
same cache file. Pass `--provider microsoft` explicitly if you want to test the
Graph route instead.

Install stable helper names and the user systemd unit/timer:

```bash
scripts/install
```

Enable the ten-minute calendar timer:

```bash
systemctl --user enable --now qreep-calendar-sync.timer
```

Or do install plus timer enable/start in one go:

```bash
scripts/install --start-calendar-timer
```

Useful checks:

```bash
qreep-calendar-pull
systemctl --user status qreep-calendar-sync.timer
journalctl --user -u qreep-calendar-sync.service
```
