# Timer

`modules/timer/` is Qreep's timer surface.

It is a top-level shell module, not a bar pill. The panel opens by IPC and lets
Adam start either a count-up timer or a countdown with a label. The old Waybar
script remains useful as a feature sketch, but this version owns the UI in QML
instead of outsourcing the whole thing to rofi/yad and a tiny text blob.

## Files

- `Timer.qml` owns IPC, open state, and lazy panel loading.
- `TimerService.qml` owns timer state, duration parsing, ticking, and done notifications.
- `TimerPanel.qml` is the centered setup/control surface.
- `TimerTheme.qml` owns timer-specific sizing, colors, and timing.
- `TimerModeButton.qml`, `TimerActionButton.qml`, and `TimerTextField.qml` are local controls.
- `modules/bar/features/timer/TimerButton.qml` is the bar pill that displays the active timer.

## IPC

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

Duration parsing follows the old helper's practical shape:

- plain numbers mean minutes: `25`;
- unit strings support `h`, `m`, and `s`: `1h30m`, `45s`, `10m`.
- finish-at times use local `HH:MM`, for example `15:03`.

## Behavior

- The panel starts focused on the duration field.
- Countdown can be started from a duration or from `finish at HH:MM`.
- Completion feedback can use either `notify-send` or Qreep's OSD.
- OSD completion uses bottom-center placement for 10 seconds with a 128px alarm icon.
- `Enter` starts the selected mode from the active input.
- Starting a timer closes the panel and shows the center bar pill.
- `Space` pauses or resumes the current timer.
- `Escape` closes the panel.
- Countdown completion sends a `notify-send` notification.
- The pill shows countdown progress as a circular pie and count-up timers as plain elapsed time.

The ticking model uses absolute timestamps while Qreep is running. That means
sleep and short stalls do not make the display count fake seconds one by one.
Timer state is persisted to:

```text
~/.cache/qreep/timer/state.json
```

That keeps count-up timers, countdowns, and the selected notification mode alive
across Quickshell restarts.
