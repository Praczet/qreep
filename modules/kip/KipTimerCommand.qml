import QtQuick

// /timer: plans and previews against the Qreep timer service; nothing runs
// until Enter. Durations and finish times use the timer's own parsers, so
// KIP accepts exactly what the bar/panel accept.
//
//   /timer                 status of the current timer
//   /timer 25m Tea         countdown (25, 25m, 1h30m, 45s)
//   /timer 15:03 Tea       countdown until a clock time
//   /timer up Focus        count-up timer
//   /timer pause | resume | stop
QtObject {
    id: rootKipTimerCommand

    property QtObject timerService: null

    // Returns { action, valid, label, seconds, finishAt, preview, error }.
    // action: status | countdown | until | up | pause | resume | stop
    function plan(argument) {
        const text = String(argument || "").trim();
        const words = text.length > 0 ? text.split(/\s+/) : [];
        const first = (words[0] || "").toLowerCase();
        const rest = words.slice(1).join(" ");

        if (!timerService)
            return result("status", false, "", 0, 0, "", "The Qreep timer is not available to KIP.");

        if (words.length === 0)
            return result("status", false, "", 0, 0, statusMarkdown(), "");

        if (first === "pause" || first === "resume" || first === "stop") {
            if (!timerService.hasState)
                return result(first, false, "", 0, 0, statusMarkdown(), "There is no timer to " + first + ".");
            return result(first, true, "", 0, 0, "## " + first.charAt(0).toUpperCase() + first.slice(1) + " " + current() + "\n\nEnter to " + first + ".", "");
        }

        if (first === "up")
            return result("up", true, label(rest, "Timer"), 0, 0, "## Count up · " + label(rest, "Timer") + "\n\nStarts at 00:00 when you press Enter." + replaces(), "");

        const finishAt = timerService.parseFinishAt(words[0]);

        if (finishAt > 0) {
            const seconds = Math.max(1, Math.ceil((finishAt - Date.now()) / 1000));

            return result("until", true, label(rest, "Countdown"), seconds, finishAt, "## Until " + words[0] + " · " + label(rest, "Countdown") + "\n\n" + timerService.formatSeconds(seconds) + " from now, ends " + clock(finishAt) + "." + replaces(), "");
        }

        const seconds = timerService.parseDuration(words[0]);

        if (seconds > 0) {
            const ends = Date.now() + seconds * 1000;

            return result("countdown", true, label(rest, "Countdown"), seconds, ends, "## " + timerService.formatSeconds(seconds) + " · " + label(rest, "Countdown") + "\n\nEnds at " + clock(ends) + "." + replaces(), "");
        }

        return result("status", false, "", 0, 0, statusMarkdown(), "Use 25m, 1h30m, 45s, 15:03, up, pause, resume or stop.");
    }

    // Runs a valid plan. Returns a short line for the notice.
    function run(planned) {
        if (!planned || !planned.valid || !timerService)
            return "";

        switch (planned.action) {
        case "countdown":
            timerService.startCountdown(String(planned.seconds) + "s", planned.label);
            return "Countdown started: " + planned.label + ".";
        case "until":
            timerService.startCountdownUntil(clock(planned.finishAt), planned.label);
            return "Countdown started until " + clock(planned.finishAt) + ": " + planned.label + ".";
        case "up":
            timerService.startTimer(planned.label);
            return "Timer started: " + planned.label + ".";
        case "pause":
            return timerService.pause();
        case "resume":
            return timerService.resume();
        case "stop":
            return timerService.stop();
        }
        return "";
    }

    function statusMarkdown() {
        if (!timerService || !timerService.hasState)
            return "No timer running.\n\n`/timer 25m Tea`, `/timer 15:03 Tea`, `/timer up Focus`.";

        return "## " + current() + "\n\n" + (timerService.running ? "Running." : "Paused.") + " `/timer pause`, `resume` or `stop`.";
    }

    function current() {
        const seconds = timerService.isCountdown ? timerService.remainingSeconds : timerService.elapsedSeconds;

        return timerService.labelText + " · " + timerService.formatSeconds(seconds) + (timerService.isCountdown ? " left" : "");
    }

    // Starting a new timer replaces the current one; say so before Enter.
    function replaces() {
        return timerService.hasState ? "\n\nReplaces **" + current() + "**." : "";
    }

    function label(text, fallback) {
        const value = String(text || "").trim();
        return value.length > 0 ? value : fallback;
    }

    function clock(epoch) {
        const date = new Date(epoch);
        return String(date.getHours()).padStart(2, "0") + ":" + String(date.getMinutes()).padStart(2, "0");
    }

    function result(action, valid, planLabel, seconds, finishAt, preview, error) {
        return {
            action: action,
            valid: valid,
            label: planLabel,
            seconds: seconds,
            finishAt: finishAt,
            preview: preview,
            error: error
        };
    }
}
