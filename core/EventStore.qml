import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: rootEventStore

    property var events: []

    readonly property FileView eventFile: FileView {
        path: Quickshell.shellDir + "/events.json"
        preload: true
        watchChanges: true

        onLoaded: rootEventStore.loadEvents()
        onTextChanged: rootEventStore.loadEvents()
        onLoadFailed: error => {
            console.error(
                "Qreep event error:",
                FileViewError.toString(error),
                path
            )
            rootEventStore.events = []
        }
    }

    function loadEvents() {
        const contents = eventFile.text()

        if (contents.length === 0) {
            events = []
            return
        }

        try {
            const document = JSON.parse(contents)
            events = Array.isArray(document.events) ? document.events : []
        } catch (error) {
            console.error("Qreep event JSON error:", error)
            events = []
        }
    }

    function dateKey(date) {
        return Qt.formatDate(date, "yyyy-MM-dd")
    }

    function eventsForDate(date) {
        const key = dateKey(date)
        return events.filter(event => event.date === key)
    }

    function eventCountForDate(date) {
        return eventsForDate(date).length
    }

    function visibleEventsForToday(now) {
        return eventsForDate(now).filter(event => {
            if (event.allDay)
                return true

            if (!event.start)
                return true

            const start = new Date(event.date + "T" + event.start + ":00")

            if (!event.end)
                return start >= now

            const end = new Date(event.date + "T" + event.end + ":00")
            return end >= now
        })
    }
}
