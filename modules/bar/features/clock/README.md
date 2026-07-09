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

* `defaultReminderMinutes` - used when an event has no `reminderMinutes`.
* `reminderCheckInterval` - how often Qreep scans upcoming events.

## Wiring

`modules/bar/Bar.qml` creates `EventStore`, passes it to `Clock`, and hosts
`CalendarPopup`.

Note: This is a bar-owned feature. Sources live under `modules/bar/features/clock/`.

Theme is exposed through:

```qml
readonly property QtObject clock: ClockFeature.ClockTheme {}
readonly property QtObject calendar: ClockFeature.CalendarTheme {}
```

## Service Notes

`EventStore.qml` uses `FileView` to watch two event files:

```text
events.json
~/.cache/qreep/calendar/events.json
```

`events.json` is the repo-local/manual source. The cache file is where future
Google/Microsoft sync helpers should write normalized read-only events. If the
cache file does not exist, Qreep ignores it. Very mature. Did not even panic.

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
`defaultReminderMinutes`.

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
