# Polkit Module

Qreep Polkit is currently a **demo surface only**.

It previews a Qreep-shaped authentication dialog without registering as the
session Polkit agent. The real password prompt is still provided by
`hyprpolkitagent`, which is a boring and acceptable thing to keep until this
module has earned real responsibilities.

## IPC

```bash
quickshell ipc call qreep-polkit demo
quickshell ipc call qreep-polkit showMe
quickshell ipc call qreep-polkit hideMe
quickshell ipc call qreep-polkit toggle
```

`demo` and `showMe` load the same fake request:

```text
pkexec pacman -Syu
```

No privileged command is run. The password field only proves focus, submit
states, error text, and the general shape of the dialog. This is a costume
rehearsal, not root access with nicer furniture.

## Artwork

The left column picks a random `icon_*` image from repo `assets/` each time a
demo request opens. Supported extensions are `webp`, `png`, `jpg`, and `jpeg`.
The artwork is treated as 1:1 and cropped inside the left rail so it fills the
dialog height. The outer dialog clips the image, because arguing with corner
radii is how a simple auth prompt becomes a zoning dispute.

## Logging

The module logs authentication lifecycle events through Qreep's normal console
logger:

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

## Current Ownership

Hyprland starts the real agent with:

```bash
systemctl --user start hyprpolkitagent
```

Do not disable that until Qreep has a real `PolkitAgent` implementation and a
tested failure path. A broken auth agent is not a visual bug; it is a desktop
paper cut with root-shaped teeth.

## Next Real Slice

When the look is settled:

1. Import `Quickshell.Services.Polkit`.
2. Add a real `PolkitAgent` behind the existing panel state.
3. Map the active auth flow into `PolkitService`.
4. Submit the password to the flow instead of `submitDemo`.
5. Test with one harmless `pkexec` command while `hyprpolkitagent` is stopped.

Keep the demo IPC around until the real agent has screenshots and regression
checks. Future tired Adam deserves a preview button.
