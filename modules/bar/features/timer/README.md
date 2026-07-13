# Timer Pill

`modules/bar/features/timer/` is the bar-facing control for the top-level Timer
module.

It does not own timer state. The real state lives in `modules/timer/`, and
`shell.qml` passes that controller/service into `Bar.qml`. The bar gets a pill;
the timer keeps its brain. This is healthier for everyone involved.

## Behavior

- The pill appears only when a timer or countdown exists.
- Left click opens the timer panel.
- Middle click pauses or resumes; when a countdown is done, it restarts that
  countdown from empty.
- Right click stops the timer.
- Countdown mode shows a circular pie fill from empty to full.
- Count-up mode shows the elapsed time without the pie.
- When a countdown completes, the pill shakes and pulses three times, then stays
  warning-colored until any pill click acknowledges it.

The pill is in the center slot after POTATO Fast. POTATO was explicitly told to
sit first; nobody needs another seating chart argument.
