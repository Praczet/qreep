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
* `EventStore.qml` - watches and parses `events.json`.
* `ClockTheme.qml` - clock sizes and event-dot tokens.
* `CalendarTheme.qml` - calendar layout tokens.

## Where To Change Things

Change time/date sizing in `ClockTheme.qml`. Change calendar layout, selected
day colors, and month navigation sizing in `CalendarTheme.qml`. Change event
parsing/filtering in `EventStore.qml`.

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

`EventStore.qml` uses `FileView` to watch:

```text
events.json
```

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
