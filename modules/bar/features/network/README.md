# Network Feature

## What It Does

Shows wired, Wi-Fi, and Bluetooth status in the right bar slot. Clicking opens
an anchored network panel with basic actions for refresh, wired reconnect,
Wi-Fi scanning/connection, and Bluetooth pairing/connection.

The Wi-Fi section also has an `Add Wi-Fi` action. That opens the larger Wi-Fi
manager for discovery, saved-network reconnects, password entry, connection
errors, and optional QR input. The small popup remains the quick control; it
has not been promoted into a municipal networking department.

## Files

* `NetworkButton.qml` - compact bar pill with wired/Wi-Fi/Bluetooth icons.
* `NetworkPanel.qml` - anchored popup panel for network actions.
* `WifiManagerPanel.qml` - dedicated floating Wi-Fi discovery and connection surface.
* `WifiQrService.qml` - local ZBar camera/image decoding and Wi-Fi QR parsing.
* `NetworkService.qml` - shared Quickshell networking/Bluetooth state and actions.
* `NetworkAction.qml` - small reusable action button.
* `NetworkStatusIcon.qml` - active/inactive icon renderer.
* `NetworkTheme.qml` - panel, row, icon, and action tokens.

## Wiring

`modules/bar/Bar.qml` creates one `NetworkService`, passes it to
`NetworkButton`, and hosts both panels. The quick panel stays anchored to the
button and closes before the floating Wi-Fi manager opens. The manager is not a
`PopupWindow`: camera processes and native file dialogs take focus, and making
that close the network manager was a brief but educational mistake.

This is a bar-owned feature. Sources live under
`modules/bar/features/network/`.

Theme is exposed through:

```qml
readonly property QtObject network: NetworkFeature.NetworkTheme {
    qreep: rootBarTheme.qreep
}
```

## Service Notes

`NetworkService.qml` uses Quickshell's NetworkManager-backed API:

```qml
import Quickshell.Networking
import Quickshell.Bluetooth
```

Wi-Fi state, discovery, saved profiles, connections, and failures flow through
those objects. The manager keeps scanning enabled while it is open and forces
a scanner restart for explicit rescans. Networks are grouped by SSID and the
strongest visible entry wins, because showing three copies of the same coffee
shop is technically accurate and practically useless.

The service still runs `nmcli` only for wired IP/gateway/DNS details:

```bash
nmcli -t -f IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show <device>
```

The password helper copies an `nmcli` command to the clipboard. It does not
copy stored Wi-Fi secrets directly. That is the correct amount of suspicious.

## Wi-Fi QR

QR support is optional and local. Install ZBar on Arch Linux if wanted:

```bash
sudo pacman -S zbar
```

Qreep never installs it automatically. `zbarcam` opens its live camera preview
with D-Bus disabled and draws its own detected-code outline; Qreep holds the
successful frame for one second before closing the scanner and continuing.
The QR section also turns green during that success state. `zbarimg` handles
selected images without opening a display. Both paths feed one parser and then
the same `NetworkService.connectWifi()` path used by the list. The camera
process is stopped on success, cancellation, or panel close.

Supported payloads use the common form:

```text
WIFI:T:WPA;S:HomeWifi;P:secret123;;
```

WPA-family, WEP, and open (`nopass`) payloads are parsed, including escaped
separators. Hidden-network metadata is recognized, but this first version can
only connect when NetworkManager exposes a matching network in the discovered
list. Passwords are transient and are neither logged nor persisted by Qreep;
NetworkManager remains responsible for saved credentials.

Without `zbarcam` or `zbarimg`, normal Wi-Fi behavior continues and the QR
actions explain what is missing. No terminal window appears to ask for a
password. We have standards, modest though they may be.

There is no IPC target for network yet. The panel is opened from the bar button.
