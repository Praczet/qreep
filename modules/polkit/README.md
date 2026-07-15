# Polkit Module

Qreep Polkit is a real Quickshell Polkit agent surface, with the old demo mode
kept around for styling.

On startup Qreep tries to register a `PolkitAgent` at:

```text
/org/qreep/Polkit
```

Polkit allows one graphical authentication agent for the session. If
`hyprpolkitagent` is already running, Qreep will not register and the existing
agent keeps doing the real work. That is not a QML tragedy; that is Polkit
refusing to let two prompts fight over the same password.

Check the current state with:

```bash
quickshell ipc call qreep-polkit registrationState
```

## IPC

```bash
quickshell ipc call qreep-polkit demo
quickshell ipc call qreep-polkit showMe
quickshell ipc call qreep-polkit hideMe
quickshell ipc call qreep-polkit toggle
quickshell ipc call qreep-polkit registrationState
quickshell ipc call qreep-polkit showLog
quickshell ipc call qreep-polkit logPath
```

`demo` and `showMe` load the same fake request:

```text
pkexec pacman -Syu
```

No privileged command is run. The password field only proves focus, submit
states, error text, and the general shape of the dialog. This is a costume
rehearsal, not root access with nicer furniture.

Real Polkit requests are opened by Polkit itself when Qreep is registered. The
panel maps the active `AuthFlow` into the same UI:

- action id, message, prompt, icon name, and selected identity come from Polkit;
- the title is a small local label derived from the action/message, because
  Polkit exposes policy data, not Adam-approved copywriting;
- submit sends the entered value to `AuthFlow.submit(...)`;
- cancel and Escape call `cancelAuthenticationRequest()`.

On the tested Quickshell 0.3.0 Arch build, `AuthFlow.isSuccessful` can remain
false even when `pkexec` exits successfully. Qreep therefore treats a completed
flow as successful when it is completed, not cancelled, not marked failed, and
has no supplementary error. That is not beautiful. It is, however, what the
real command result proved.

## Artwork

The left column picks a random `icon_*` image from repo `assets/` each time a
demo request opens. Supported extensions are `webp`, `png`, `jpg`, and `jpeg`.
The artwork is treated as 1:1 and cropped inside the left rail so it fills the
dialog height. The outer dialog clips the image, because arguing with corner
radii is how a simple auth prompt becomes a zoning dispute.

## Logging

The module logs authentication lifecycle events through Qreep's normal console
logger:

- agent registration changes;
- request called: caller, source label, action id, selected user, and title;
- failed authentication attempts, counted without logging the submitted value;
- request ended: `cancel`, `failed`, or `success`, with the same request
  metadata;
- password contents are never logged, because that would be impressively stupid.

When Qreep is launched in the foreground, Quickshell prints the exact log path:

```text
Saving logs to "/run/user/1000/quickshell/by-id/<instance-id>/log.qslog"
```

For the current user session, recent logs can be found with:

```bash
find "/run/user/$UID/quickshell/by-id" -name log.qslog -print
```

The Polkit lines start with `Qreep info: Polkit ...`.

The module also exposes two small IPC helpers:

```bash
quickshell ipc call qreep-polkit showLog
quickshell ipc call qreep-polkit logPath
```

`showLog` returns the `quickshell --path ... log --tail 120` command for this
checkout. `logPath` returns a shell command that finds the newest
`log.qslog`. It returns commands instead of dumping the whole log through IPC,
because using an auth module as a terminal pager would be a very avoidable
mistake.

The Quickshell `AuthFlow` currently gives Qreep the policy action, selected
identity, prompt/message, and result state. It does not expose a neat caller
process name or PID through this QML API, so the logs do not invent one. The
action id is the useful forensic handle for now.

## Current Ownership

Hyprland starts the real agent with:

```bash
systemctl --user start hyprpolkitagent
```

If that service is running, Qreep's `registrationState` should report
`not registered`. To let Qreep own Polkit for a test session:

```bash
systemctl --user stop hyprpolkitagent
quickshell -c qreep --no-duplicate
quickshell ipc call qreep-polkit registrationState
pkexec true
systemctl --user start hyprpolkitagent
```

`pkexec true` is a harmless authentication trigger. It asks for credentials and
then exits successfully if authentication works. Restart `hyprpolkitagent` after
testing unless Qreep has become the permanent agent on purpose.

## Module Integration

Other Qreep modules should not import or poke the Polkit panel directly. They
should run a Polkit-aware command, usually through `pkexec`, and let the session
agent do its job.

The first real consumer is Upchecker through Adam's local
`~/.local/bin/update-btw` wrapper:

```bash
paru --sudo /usr/bin/pkexec -Syu --needed
```

Upchecker still launches `ghostty -e update-btw`; the only important part is
that the privileged package-manager step uses `pkexec`. Running the whole AUR
helper as root would be a bad way to make a pretty password prompt feel useful.

## Next Real Slice

Before replacing `hyprpolkitagent` in the real session:

1. Run one focused test with `pkexec true`.
2. Run one package-management-shaped test.
3. Check success, wrong password, Escape, outside click, and Cancel.
4. Confirm logs show start, failed attempts, and terminal outcome.
5. Only then remove or disable the old agent startup.

Keep the demo IPC around until the real agent has screenshots and regression
checks. Future tired Adam deserves a preview button.
