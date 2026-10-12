# System tray

Hosts StatusNotifier items in the right bar slot. This is the piece applications
such as Flameshot mean when they say they can be reached through a notification
tray. It is separate from Qreep's notification daemon because desktop naming
was apparently considered finished before clarity arrived.

All registered items are shown inside one bar pill:

- left click runs the primary action, or opens the menu for menu-only items;
- middle click runs the secondary action;
- right click opens the item's menu;
- scrolling is forwarded to the item.

The pill only appears when at least one tray item is registered. It participates
in the normal runtime pill controls under the `tray` ID:

```bash
quickshell ipc call qreep-bar-pill disablePill tray
quickshell ipc call qreep-bar-pill enablePill tray
```

Qreep does not start tray applications. Flameshot or another application must
already be running and publishing a StatusNotifier item.
