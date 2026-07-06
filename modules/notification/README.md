# Notification Module

## What It Does

Owns Qreep notifications through `Quickshell.Services.Notifications`.

It provides:

* transient popup cards;
* a right-side notification center;
* grouped center view by app, enabled by default;
* fold/unfold per group;
* per-notification dismiss;
* per-group dismiss;
* dismiss all;
* app-specific cards for Color Picker and Hyprshot;
* action buttons when the notification exposes named actions;
* popup enter/exit animations that try not to make the whole stack twitch.

This is a shell-level module, not a bar feature. The bar already has a job.
Several, unfortunately.

## Files

* `Notification.qml` - scope/controller, IPC, service ownership, popup/center
  lazy loading.
* `NotificationService.qml` - `NotificationServer`, tracked notifications,
  popup model, grouping, dismiss actions, action invocation, text cleanup.
* `NotificationPopupList.qml` - non-invasive popup layer surface.
* `NotificationCenter.qml` - non-invasive right-side center panel.
* `NotificationCard.qml` - generic and app-specific notification card UI.
* `NotificationTheme.qml` - placement, sizes, timing, colors, and animation
  tokens.

## Wiring

`shell.qml` hosts `Notification.qml` directly:

```qml
NotificationModule.Notification {
    theme: qreepTheme
}
```

Theme is exposed through `modules/ModulesTheme.qml`:

```qml
readonly property QtObject notification: NotificationModule.NotificationTheme {
    qreep: rootModulesTheme.qreep
}
```

Layer namespaces:

```text
qreep-notification
qreep-notification-center
```

Hyprland blur example:

```ini
layerrule = blur, qreep-notification
layerrule = ignorealpha 0.1, qreep-notification

layerrule = blur, qreep-notification-center
layerrule = ignorealpha 0.1, qreep-notification-center
```

## IPC

```bash
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-notification toggleCenter
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-notification showCenter
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-notification hideCenter
quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc call qreep-notification dismissAll
```

Legacy aliases also exist for `toggle`, `showMe`, and `hideMe`.

## Behavior Notes

Popups:

* use `WlrLayer.Overlay`;
* use `WlrKeyboardFocus.None`;
* mask input to the visible popup stack only;
* animate new cards in;
* animate normal timeout/manual dismiss out;
* keep action notifications open until an action or close is clicked.

Notification center:

* uses `WlrLayer.Overlay`;
* uses `WlrKeyboardFocus.OnDemand` so `Escape` can close the panel;
* masks input to the panel only, so the rest of the screen stays clickable;
* groups by app by default;
* folds groups by default;
* shows only the newest notification in a folded group;
* has per-group trash and global clear controls.

Action notifications are touchy. Invoking an action can close/destroy the
underlying notification object immediately. Popup action handling therefore
renders from a plain snapshot and removes the popup by stable notification id
before invoking the action by index on the live notification. Do not turn that
back into direct live action objects in the popup model unless you are
collecting segfaults as a hobby.

## App-Specific Cards

Color Picker:

* detected from `Color Picker` title/app plus a `#rrggbb` color in the body;
* renders a color badge on the right;
* suppresses generic image preview behavior.

Hyprshot:

* detected by app name containing `hyprshot`;
* renders the screenshot image in the left visual slot instead of the app icon.

Generic notifications:

* render app/priority header;
* render app icon on the left;
* render title/body on the right;
* do not render `notification.image` as a large preview. Some apps expose icons
  there. Trusting that blindly is how an info icon becomes a billboard.

## Test Batch

Use the project-local helper:

```bash
scripts/qreep-notification-test-batch_v0.0.1
scripts/qreep-notification-test-batch_v0.0.1 --delay 0.4
```

It sends Color Picker, Hyprshot, grouped `notify-send`, critical, Ghostty, and
action-button examples.

Qreep must own `org.freedesktop.Notifications` for this to test Qreep. If
another daemon is running, Qreep will log that it could not register the
notification server and the test batch will go somewhere else. Rude, but
accurate.

## Validation

```bash
qmllint modules/notification/*.qml
git diff --check
timeout 10 quickshell --path . --no-duplicate
```

For action-notification changes, test with:

```bash
scripts/qreep-notification-test-batch_v0.0.1 --delay 0.4
```
