# Network Feature

## What It Does

Shows wired, Wi-Fi, and Bluetooth status in the right bar slot. Clicking opens
an anchored network panel with basic actions for refresh, wired reconnect,
Wi-Fi scanning/connection, and Bluetooth pairing/connection.

This is a bar feature, not a network manager replacement. It should remain a
useful shell control, not a second career.

## Files

* `NetworkButton.qml` - compact bar pill with wired/Wi-Fi/Bluetooth icons.
* `NetworkPanel.qml` - anchored popup panel for network actions.
* `NetworkService.qml` - Quickshell networking/Bluetooth state and actions.
* `NetworkAction.qml` - small reusable action button.
* `NetworkStatusIcon.qml` - active/inactive icon renderer.
* `NetworkTheme.qml` - panel, row, icon, and action tokens.

## Wiring

`modules/bar/Bar.qml` creates `NetworkService`, passes it to `NetworkButton`,
and hosts `NetworkPanel` anchored to the button.

This is a bar-owned feature. Sources live under
`modules/bar/features/network/`.

Theme is exposed through:

```qml
readonly property QtObject network: NetworkFeature.NetworkTheme {
    qreep: rootBarTheme.qreep
}
```

## Service Notes

`NetworkService.qml` uses:

```qml
import Quickshell.Networking
import Quickshell.Bluetooth
```

It also runs `nmcli` for wired IP/gateway/DNS details:

```bash
nmcli -t -f IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show <device>
```

The password helper copies an `nmcli` command to the clipboard. It does not
copy stored Wi-Fi secrets directly. That is the correct amount of suspicious.

There is no IPC target for network yet. The panel is opened from the bar button.
