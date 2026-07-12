import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../core" as Core

QtObject {
    id: rootEventStore

    property QtObject log
    required property QtObject theme
    property var events: []
    property int revision: 0
    readonly property string localEventPath: Quickshell.shellDir + "/events.json"
    readonly property string generatedEventPath: Quickshell.env("HOME") + "/.cache/qreep/calendar/events.json"
    readonly property string microsoftGeneratedEventPath: Quickshell.env("HOME") + "/.cache/qreep/calendar/microsoft-events.json"

    signal eventChangeNotified(string eventId)

    readonly property Core.Log fallbackLog: Core.Log {}

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-calendar"

        function refresh(): string {
            rootEventStore.reloadFiles();
            return "Calendar cache refresh requested";
        }

        function notifyChangedAll(): string {
            rootEventStore.eventChangeNotified("");
            return "Calendar change notification requested";
        }

        function notifyChanged(eventId: string): string {
            const normalizedId = rootEventStore.trimmedString(eventId);

            rootEventStore.eventChangeNotified(normalizedId);
            return normalizedId.length > 0
                ? "Calendar change notification requested for " + normalizedId
                : "Calendar change notification requested";
        }
    }

    readonly property Timer generatedCacheRefreshTimer: Timer {
        interval: rootEventStore.theme.modules.bar.calendar.eventCacheRefreshInterval
        repeat: true
        running: true
        onTriggered: rootEventStore.loadEvents()
    }

    readonly property FileView localEventFile: FileView {
        path: rootEventStore.localEventPath
        preload: true
        watchChanges: true

        onLoaded: rootEventStore.loadEvents()
        onTextChanged: rootEventStore.loadEvents()
        onLoadFailed: error => {
            rootEventStore.reportLoadError("Qreep local event error:", error, path);
            rootEventStore.loadEvents();
        }
    }

    readonly property FileView generatedEventFile: FileView {
        path: rootEventStore.generatedEventPath
        preload: true
        watchChanges: true

        onLoaded: rootEventStore.loadEvents()
        onTextChanged: rootEventStore.loadEvents()
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                rootEventStore.reportLoadError("Qreep generated event error:", error, path);

            rootEventStore.loadEvents();
        }
    }

    readonly property FileView microsoftGeneratedEventFile: FileView {
        path: rootEventStore.microsoftGeneratedEventPath
        preload: true
        watchChanges: true

        onLoaded: rootEventStore.loadEvents()
        onTextChanged: rootEventStore.loadEvents()
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                rootEventStore.reportLoadError("Qreep Microsoft event error:", error, path);

            rootEventStore.loadEvents();
        }
    }

    function loadEvents() {
        const sourceEvents = [];

        appendEventsFromFile(localEventFile, "local", sourceEvents);
        appendEventsFromFile(generatedEventFile, "generated", sourceEvents);
        appendEventsFromFile(microsoftGeneratedEventFile, "microsoft", sourceEvents);
        events = sortedEvents(normalizeEvents(sourceEvents));
        revision++;
    }

    function reloadFiles() {
        localEventFile.reload();
        generatedEventFile.reload();
        microsoftGeneratedEventFile.reload();
        loadEvents();
    }

    function appendEventsFromFile(file, sourceName, targetEvents) {
        const contents = file.text();

        if (contents.length === 0)
            return;

        try {
            const document = JSON.parse(contents);
            const documentEvents = Array.isArray(document.events) ? document.events : [];

            for (let index = 0; index < documentEvents.length; index++) {
                const event = Object.assign({}, documentEvents[index]);

                if (!event.source)
                    event.source = sourceName;

                targetEvents.push(event);
            }
        } catch (error) {
            reportError("Qreep " + sourceName + " event JSON error:", error);
        }
    }

    function reportLoadError(prefix, error, path) {
        reportError(prefix, FileViewError.toString(error), path);
    }

    function reportError() {
        (log || fallbackLog).error(messageText(arguments));
    }

    function messageText(messages) {
        const parts = [];

        for (let index = 0; index < messages.length; index++)
            parts.push(String(messages[index]));

        return parts.join(" ");
    }

    function dateKey(date) {
        return Qt.formatDate(date, "yyyy-MM-dd");
    }

    function normalizeEvents(sourceEvents) {
        const normalizedEvents = [];

        for (let index = 0; index < sourceEvents.length; index++) {
            const event = normalizeEvent(sourceEvents[index], index);

            if (event !== null)
                normalizedEvents.push(event);
        }

        return normalizedEvents;
    }

    function normalizeEvent(event, index) {
        if (!event)
            return null;

        const status = trimmedString(event.status).toLowerCase();

        if (status === "cancelled" || status === "canceled" || status === "deleted")
            return null;

        const date = normalizedDate(event.date || event.startDate || event.day || event.start);

        if (date.length === 0)
            return null;

        const title = trimmedString(event.title || event.summary || event.subject || "Untitled event");
        const source = trimmedString(event.source || "local");
        const calendar = trimmedString(event.calendar || event.calendarName || event.calendarId || "Local");
        const id = trimmedString(event.id || event.uid || source + ":" + calendar + ":" + date + ":" + index);
        const allDay = event.allDay === true || event.isAllDay === true || isAllDayStart(event.start);

        return {
            id: id,
            source: source,
            calendar: calendar,
            title: title.length > 0 ? title : "Untitled event",
            date: date,
            start: allDay ? "" : normalizedTime(event.start || event.startTime || event.startDateTime),
            end: allDay ? "" : normalizedTime(event.end || event.endTime || event.endDateTime),
            allDay: allDay,
            location: trimmedString(event.location),
            url: trimmedString(event.url || event.htmlLink || event.webLink),
            color: trimmedString(event.color || event.colorId || event.calendarColor),
            reminderMinutes: normalizedReminderMinutes(event.reminderMinutes || event.reminders),
            busy: event.busy === undefined ? true : event.busy === true
        };
    }

    function trimmedString(value) {
        return String(value || "").trim();
    }

    function normalizedDate(value) {
        if (!value)
            return "";

        if (value instanceof Date && !isNaN(value.getTime()))
            return dateKey(value);

        if (typeof value === "object") {
            if (value.date)
                return normalizedDate(value.date);

            if (value.dateTime)
                return normalizedDate(value.dateTime);
        }

        const text = trimmedString(value);
        const match = text.match(/^(\d{4}-\d{2}-\d{2})/);
        return match ? match[1] : "";
    }

    function isAllDayStart(value) {
        return value && typeof value === "object" && value.date && !value.dateTime;
    }

    function normalizedTime(value) {
        if (!value)
            return "";

        if (value instanceof Date && !isNaN(value.getTime()))
            return Qt.formatTime(value, "HH:mm");

        if (typeof value === "object") {
            if (value.dateTime)
                return normalizedTime(value.dateTime);

            return "";
        }

        const text = trimmedString(value);
        const timeMatch = text.match(/T(\d{2}:\d{2})/);

        if (timeMatch)
            return timeMatch[1];

        const shortTimeMatch = text.match(/^(\d{1,2}):(\d{2})/);

        if (!shortTimeMatch)
            return "";

        const hour = Number(shortTimeMatch[1]);

        if (hour < 0 || hour > 23)
            return "";

        return (hour < 10 ? "0" : "") + hour + ":" + shortTimeMatch[2];
    }

    function normalizedReminderMinutes(value) {
        if (!value)
            return [];

        if (typeof value === "object" && Array.isArray(value.overrides))
            return normalizedReminderMinutes(value.overrides);

        const source = Array.isArray(value) ? value : [value];
        const minutes = [];

        for (let index = 0; index < source.length; index++) {
            const item = source[index];
            const minuteValue = typeof item === "object" ? item.minutes : item;
            const number = Number(minuteValue);

            if (!isNaN(number) && number >= 0)
                minutes.push(Math.floor(number));
        }

        return minutes;
    }

    function eventsForDate(date) {
        const key = dateKey(date);
        return sortedEvents(events.filter(event => event.date === key));
    }

    function eventCountForDate(date) {
        return visibleEventsForDate(date, new Date()).length;
    }

    function visibleEventsForDate(date, now) {
        const selectedKey = dateKey(date);
        const todayKey = dateKey(now);

        if (selectedKey < todayKey)
            return [];

        if (selectedKey === todayKey)
            return visibleEventsForToday(now);

        return eventsForDate(date);
    }

    function eventsForNextDays(now, daysAhead) {
        const firstDate = new Date(
            now.getFullYear(),
            now.getMonth(),
            now.getDate()
        );
        const lastDate = new Date(firstDate);
        lastDate.setDate(lastDate.getDate() + daysAhead);

        const firstKey = dateKey(firstDate);
        const lastKey = dateKey(lastDate);

        return events
            .filter(event =>
                event.date >= firstKey && event.date <= lastKey
            )
            .slice()
            .sort(compareEvents);
    }

    function upcomingPersonalEvents(now, limit, excludedEvents) {
        if (limit <= 0)
            return [];

        const excludedIds = excludedEventIdMap(excludedEvents);
        const result = [];

        for (let index = 0; index < events.length; index++) {
            const event = events[index];

            if (!isPersonalEvent(event) || excludedIds[event.id] || !isUpcomingEvent(event, now))
                continue;

            result.push(event);

            if (result.length >= limit)
                break;
        }

        return result;
    }

    function excludedEventIdMap(excludedEvents) {
        const result = {};

        if (!Array.isArray(excludedEvents))
            return result;

        for (let index = 0; index < excludedEvents.length; index++) {
            const event = excludedEvents[index];

            if (event && event.id)
                result[event.id] = true;
        }

        return result;
    }

    function isUpcomingEvent(event, now) {
        const todayKey = dateKey(now);

        if (event.date < todayKey)
            return false;

        if (event.date > todayKey)
            return true;

        return isVisibleTodayEvent(event, now);
    }

    function sortedEvents(sourceEvents) {
        const sorted = [];

        for (let index = 0; index < sourceEvents.length; index++) {
            const event = sourceEvents[index];
            let insertIndex = 0;

            while (insertIndex < sorted.length && compareEvents(sorted[insertIndex], event) <= 0)
                insertIndex++;

            sorted.splice(insertIndex, 0, event);
        }

        return sorted;
    }

    function compareEvents(left, right) {
        if (left.date !== right.date)
            return compareText(left.date, right.date);

        if (left.allDay !== right.allDay)
            return left.allDay ? -1 : 1;

        return compareText(left.start || "", right.start || "");
    }

    function compareText(left, right) {
        if (left < right)
            return -1;

        if (left > right)
            return 1;

        return 0;
    }

    function eventTimeLabel(event) {
        if (event.allDay)
            return "All day";

        if (!event.start)
            return "No time";

        return event.end
            ? event.start + "–" + event.end
            : event.start;
    }

    function eventDateLabel(event, now) {
        const todayKey = dateKey(now);
        const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
        const tomorrowKey = dateKey(tomorrow);

        if (event.date === todayKey)
            return "Today";

        if (event.date === tomorrowKey)
            return "Tomorrow";

        return Qt.formatDate(new Date(event.date + "T00:00:00"), "ddd dd MMM");
    }

    function eventMetaLabel(event) {
        const parts = [];

        if (event.location)
            parts.push(event.location);

        if (event.calendar && event.calendar !== "Local")
            parts.push(event.calendar);

        if (event.source && event.source !== "local")
            parts.push(event.source);

        return parts.join(" · ");
    }

    function eventColor(event, fallbackColor) {
        return validColorValue(event.color) ? event.color : fallbackColor;
    }

    function isPersonalEvent(event) {
        if (!event)
            return false;

        return trimmedString(event.title).match(/^AD($|[: +])/i) !== null;
    }

    function isMicrosoftEvent(event) {
        if (!event)
            return false;

        return trimmedString(event.source).toLowerCase() === "microsoft";
    }

    function eventStartDate(event) {
        if (!event || event.allDay || !event.start)
            return null;

        return new Date(event.date + "T" + event.start + ":00");
    }

    function eventEndDate(event) {
        if (!event || event.allDay || !event.end)
            return null;

        return new Date(event.date + "T" + event.end + ":00");
    }

    function validColorValue(value) {
        const text = trimmedString(value);
        return text.match(/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/) !== null
            || text.indexOf("rgb(") === 0
            || text.indexOf("rgba(") === 0;
    }

    function visibleEventsForToday(now) {
        return sortedEvents(eventsForDate(now).filter(event => {
            return isVisibleTodayEvent(event, now);
        }));
    }

    function isVisibleTodayEvent(event, now) {
        if (event.allDay)
            return true;

        if (!event.start)
            return true;

        const start = eventStartDate(event);

        if (!event.end)
            return start >= now;

        const end = eventEndDate(event);
        return end >= now;
    }
}
