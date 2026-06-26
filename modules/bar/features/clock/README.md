# Clock Feature

## What It Does

Shows time/date in the center bar slot. Clicking toggles seconds. Right click
opens the calendar popup. Current-day events are shown as small dots on the
module edge.

## Files

* `Clock.qml` - bar clock module.
* `CalendarPopup.qml` - month grid and six-day agenda.
* `EventStore.qml` - watches and parses `events.json`.
* `ClockTheme.qml` - clock sizes and event-dot tokens.
* `CalendarTheme.qml` - calendar layout tokens.

## Where To Change Things

Change time/date sizing in `ClockTheme.qml`. Change calendar layout in
`CalendarTheme.qml`. Change event parsing/filtering in `EventStore.qml`.

## Wiring

`panels/Bar.qml` creates `EventStore`, passes it to `Clock`, and hosts
`CalendarPopup`.

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

Expected shape:

```json
{ "events": [{ "date": "2026-06-25", "title": "Meeting" }] }
```

Timed events may use `start`, `end`, and `allDay`.
