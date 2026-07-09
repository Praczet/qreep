import QtQuick
import Quickshell.Io

QtObject {
    id: rootCalendarReminder

    required property QtObject events
    required property QtObject theme

    property var firedReminderKeys: ({})

    readonly property Process notifyRunner: Process {}
    readonly property Timer reminderTimer: Timer {
        interval: rootCalendarReminder.theme.modules.bar.calendar.reminderCheckInterval
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: rootCalendarReminder.checkReminders()
    }

    function checkReminders() {
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const upcomingEvents = events.eventsForNextDays(today, 1);

        for (let index = 0; index < upcomingEvents.length; index++)
            checkEvent(upcomingEvents[index], now);
    }

    function checkEvent(event, now) {
        if (!event || event.allDay || !event.start)
            return;

        const start = events.eventStartDate(event);

        if (start === null || isNaN(start.getTime()) || start < now)
            return;

        const reminderMinutes = event.reminderMinutes.length > 0
            ? event.reminderMinutes
            : rootCalendarReminder.theme.modules.bar.calendar.useDefaultReminders
                ? [rootCalendarReminder.theme.modules.bar.calendar.defaultReminderMinutes]
                : [];

        for (let index = 0; index < reminderMinutes.length; index++)
            checkReminderMinute(event, start, now, reminderMinutes[index]);
    }

    function checkReminderMinute(event, start, now, minutesBefore) {
        const minutes = Number(minutesBefore);

        if (isNaN(minutes) || minutes < 0)
            return;

        const notifyAt = new Date(start.getTime() - minutes * 60000);
        const lateWindow = Math.max(rootCalendarReminder.theme.modules.bar.calendar.reminderCheckInterval, 60000);

        if (notifyAt > now || now.getTime() - notifyAt.getTime() > lateWindow)
            return;

        const key = event.id + ":" + event.date + ":" + event.start + ":" + minutes;

        if (firedReminderKeys[key])
            return;

        markFired(key);
        notify(event, minutes);
    }

    function markFired(key) {
        const updated = {};

        for (const existingKey in firedReminderKeys)
            updated[existingKey] = firedReminderKeys[existingKey];

        updated[key] = true;
        firedReminderKeys = updated;
    }

    function notify(event, minutesBefore) {
        const timeText = events.eventTimeLabel(event);
        const meta = events.eventMetaLabel(event);
        const bodyParts = [];

        bodyParts.push(timeText);

        if (minutesBefore > 0)
            bodyParts.push("starts in " + minutesBefore + " min");
        else
            bodyParts.push("starts now");

        if (meta.length > 0)
            bodyParts.push(meta);

        notifyRunner.running = false;
        notifyRunner.command = [
            "notify-send",
            "-a",
            "Qreep Calendar",
            "-i",
            "x-office-calendar-symbolic",
            "Calendar: " + event.title,
            bodyParts.join(" · ")
        ];
        notifyRunner.startDetached();
    }
}
