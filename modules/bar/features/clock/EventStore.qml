import QtQuick
import Quickshell
import Quickshell.Io
import "../../core" as Core

QtObject {
    id: rootEventStore

    property QtObject log
    property var events: []

    readonly property Core.Log fallbackLog: Core.Log {}

    readonly property FileView eventFile: FileView {
        path: Quickshell.shellDir + "/events.json"
        preload: true
        watchChanges: true

        onLoaded: rootEventStore.loadEvents()
        onTextChanged: rootEventStore.loadEvents()
        onLoadFailed: error => {
            rootEventStore.reportError("Qreep event error:", FileViewError.toString(error), path);
            rootEventStore.events = [];
        }
    }

    function loadEvents() {
        const contents = eventFile.text();

        if (contents.length === 0) {
            events = [];
            return;
        }

        try {
            const document = JSON.parse(contents);
            events = Array.isArray(document.events) ? document.events : [];
        } catch (error) {
            reportError("Qreep event JSON error:", error);
            events = [];
        }
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

    function eventsForDate(date) {
        const key = dateKey(date);
        return events.filter(event => event.date === key);
    }

    function eventCountForDate(date) {
        return eventsForDate(date).length;
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
            .sort((left, right) => {
                if (left.date !== right.date)
                    return left.date.localeCompare(right.date);

                if (left.allDay !== right.allDay)
                    return left.allDay ? -1 : 1;

                return (left.start || "").localeCompare(right.start || "");
            });
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

    function visibleEventsForToday(now) {
        return eventsForDate(now).filter(event => {
            if (event.allDay)
                return true;

            if (!event.start)
                return true;

            const start = new Date(event.date + "T" + event.start + ":00");

            if (!event.end)
                return start >= now;

            const end = new Date(event.date + "T" + event.end + ":00");
            return end >= now;
        });
    }
}
