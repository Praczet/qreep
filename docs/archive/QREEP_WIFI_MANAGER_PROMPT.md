# QREEP Network / Wi-Fi Manager --- implementation prompt

You are working in the existing **QREEP** project, a Quickshell/QML
desktop environment project.

Your task is to **inspect the current network/Wi-Fi implementation
first**, understand how QREEP is structured and how its existing
components/services are written, and then improve or replace the current
Wi-Fi solution with a polished Wi-Fi manager.

Do **not** assume the current implementation is useless and do not
blindly rewrite it. Reuse existing architecture, components, styling,
helpers, process wrappers, services, and conventions wherever they are
good. Remove or refactor parts that make the Wi-Fi experience
unreliable, awkward, or difficult to maintain.

## 1. Start with investigation

Before changing code:

1.  Read the project's agent/developer instructions and relevant
    documentation.
2.  Locate the existing network/Wi-Fi module.
3.  Inspect:
    -   current QML UI;
    -   network service/backend;
    -   how scanning is performed;
    -   how connections/disconnections are performed;
    -   how passwords are currently requested;
    -   whether `nmcli`, D-Bus, NetworkManager APIs, or another
        mechanism is used;
    -   how asynchronous processes and state changes are handled;
    -   how errors are surfaced;
    -   how other QREEP panels/windows are implemented;
    -   existing reusable UI components, dialogs, overlays,
        notifications, icons, animations, and styling.
4.  Identify why the current experience feels unreliable or unpolished.
5.  Preserve QREEP conventions unless there is a strong technical reason
    to change them.

After understanding the current implementation, implement the solution
below.

------------------------------------------------------------------------

# 2. Goal

Create a polished **QREEP Wi-Fi manager panel/window**.

It should feel like a proper desktop Wi-Fi interface rather than a
graphical wrapper around terminal commands.

The user should be able to:

-   see nearby Wi-Fi networks;
-   see the currently connected network;
-   see signal strength;
-   see security/locked state;
-   refresh/rescan networks;
-   connect to an open network;
-   connect to a secured network;
-   enter a password when required;
-   reconnect to known/saved networks without unnecessarily asking for
    the password again;
-   disconnect from the current network;
-   see useful connecting/error states;
-   recover cleanly from a wrong password or failed connection;
-   scan a Wi-Fi QR code using the computer camera;
-   select an image containing a Wi-Fi QR code and connect using
    credentials extracted from it.

The interaction should be smooth and asynchronous. Avoid UI freezes,
unnecessary panel closing/reopening, terminal windows, or awkward
intermediate states.

------------------------------------------------------------------------

# 3. NetworkManager integration

QREEP should remain a **frontend to NetworkManager**. Do not implement
Wi-Fi management itself.

First determine how QREEP currently communicates with NetworkManager.

If the existing solution relies heavily on repeatedly spawning `nmcli`
and this is responsible for unreliable state or poor UX, investigate
moving persistent/stateful functionality to **NetworkManager's D-Bus
API**.

Prefer an event/state-driven architecture where practical:

    NetworkManager
          ↓
    Network service
          ↓
    normalized QREEP state
          ↓
    QML Wi-Fi panel

The UI should react to network state changes rather than relying on
arbitrary delays or repeated polling.

However, do not introduce a large native/C++ subsystem merely for
architectural purity. If the existing QREEP architecture has a clean and
reliable abstraction around `nmcli`, improve it where appropriate.
Choose the smallest robust solution that fits the project.

Centralize NetworkManager interaction. Individual QML controls should
not contain scattered shell commands.

------------------------------------------------------------------------

# 4. Wi-Fi panel

Create or improve the network panel/window following QREEP's existing
visual language.

The panel should provide approximately:

    Wi-Fi                         [toggle]

    Connected
    ┌─────────────────────────────┐
    │ ● Home Network        ▂▄▆█ │
    │   Connected                 │
    │                    Disconnect
    └─────────────────────────────┘

    Available networks

    🔒 University WiFi       ▂▄▆_
    🔒 Coffee Shop           ▂▄__
       Open Network          ▂___

    [ Rescan ]

    ─────────────────────────────

    Connect using QR
    [ Scan with camera ]
    [ Choose image ]

Do not copy this literally if QREEP already has better components/layout
conventions.

Important states should include at least:

-   Wi-Fi disabled;
-   scanning;
-   no networks found;
-   connected;
-   connecting;
-   authentication/password required;
-   invalid/wrong password;
-   connection failure;
-   disconnected.

Avoid duplicate access points where NetworkManager exposes multiple
BSSIDs for the same logical network. Present networks in a useful
human-oriented way.

Use sensible signal-strength representation and security indicators.

------------------------------------------------------------------------

# 5. Password flow

Selecting a protected network that needs credentials should produce an
**in-panel/in-window password prompt** consistent with QREEP's UI.

For example:

    Connect to "Home Network"

    Password
    [ ••••••••••••••• ]

    [ Show password ]

              [ Cancel ] [ Connect ]

Requirements:

-   do not open a terminal;
-   do not use an external interactive `nmcli` password prompt;
-   do not expose the password in logs;
-   do not keep passwords in QML state longer than necessary;
-   allow retry after authentication failure;
-   distinguish authentication failure from generic connection failure
    where NetworkManager provides enough information;
-   use an existing saved NetworkManager connection when possible.

Let NetworkManager remain responsible for persistent connection
profiles/credentials.

------------------------------------------------------------------------

# 6. Wi-Fi QR support

Implement support for the common Wi-Fi QR payload format, for example:

    WIFI:T:WPA;S:HomeWifi;P:secret123;;

Create one common QR-processing path.

Conceptually:

    camera ──────┐
                 │
    image file ──┼──> QR decoder
                 │
                 ↓
            QR payload
                 ↓
          Wi-Fi QR parser
                 ↓
          WifiCredentials
          - ssid
          - password
          - security
          - hidden (if present)
                 ↓
          normal Wi-Fi connection flow
                 ↓
          NetworkManager

**QR scanning must only provide credentials.**

Do not create a second independent connection implementation for QR
codes. After parsing, QR connections should use the same network
connection service/state machine as manually selected networks.

------------------------------------------------------------------------

# 7. QR parser

Keep QR **decoding** and Wi-Fi QR **parsing** separate.

The decoder returns plain text.

The parser determines whether it is a supported Wi-Fi QR payload and
extracts the fields.

Support the standard Wi-Fi QR structure, including escaped special
characters where applicable.

At minimum handle:

-   WPA/WPA2-style credentials;
-   open networks (`nopass`);
-   SSID;
-   password;
-   hidden-network flag if supplied.

Handle unsupported or malformed QR codes gracefully.

Do not accidentally display/log the password when reporting parsing
errors.

------------------------------------------------------------------------

# 8. Scan QR using camera

For the first implementation, prefer a simple external scanner based on
**ZBar** rather than building a full camera subsystem.

Investigate availability/behavior on the target Arch Linux environment
and use:

    zbarcam --raw

or the appropriate equivalent invocation.

QREEP should:

1.  start the scanner asynchronously;
2.  indicate that QR scanning is active;
3.  read scanner stdout;
4.  wait for a valid Wi-Fi QR payload;
5.  ignore/report unrelated QR codes appropriately;
6.  stop the scanner immediately after obtaining the required Wi-Fi QR;
7.  parse the credentials;
8.  present the detected network appropriately;
9.  connect through the normal Wi-Fi connection flow;
10. terminate the scanner cleanly on cancel, panel close, error, or
    success.

Do not leave orphan `zbarcam` processes.

A camera preview is **not required for this first version**.

The UI can show a polished scanning state such as:

    Scan Wi-Fi QR

        [ scanning indicator ]

    Point a Wi-Fi QR code
    at the camera.

             [ Cancel ]

If multiple cameras/devices need consideration, inspect what is
practical within the existing architecture. Keep the first version
simple but do not hard-code assumptions unnecessarily.

------------------------------------------------------------------------

# 9. Scan QR from an image

Allow the user to select an image file containing a Wi-Fi QR code.

Use ZBar's image decoder, e.g. the equivalent of:

    zbarimg --quiet --raw <image>

Requirements:

1.  use a QREEP/Qt-compatible file picker or the project's existing
    file-selection mechanism;
2.  accept common image formats;
3.  run decoding asynchronously;
4.  capture the decoded payload;
5.  validate that it is a Wi-Fi QR;
6.  parse it through the **same Wi-Fi QR parser** used by camera
    scanning;
7.  pass the resulting credentials through the **same Wi-Fi connection
    flow**;
8.  show a useful error if:
    -   no QR code is found;
    -   the QR is not a Wi-Fi QR;
    -   the payload is malformed;
    -   ZBar is unavailable;
    -   the image cannot be read.

Do not duplicate parsing or connection logic between camera and image
scanning.

------------------------------------------------------------------------

# 10. Dependency handling

ZBar should be treated as an optional feature dependency unless the
project's dependency policy indicates otherwise.

Detect missing executables cleanly.

If ZBar is unavailable:

-   normal Wi-Fi functionality must continue working;
-   QR actions should be disabled or produce a useful explanation;
-   do not crash;
-   provide the appropriate Arch Linux installation/dependency
    information in project documentation rather than attempting
    privileged package installation automatically.

Do not run `sudo` or install system packages automatically.

------------------------------------------------------------------------

# 11. Suggested internal separation

Adapt naming to existing QREEP conventions. Do not force these exact
filenames if the project already has an established structure.

Conceptually keep these responsibilities separate:

    Network / NetworkManager service
        scan()
        networks
        activeNetwork
        connect(...)
        disconnect(...)
        connection state/errors

    Wi-Fi QR service
        scanCamera()
        stopCameraScan()
        decodeImage(path)
        decoder availability/state

    Wi-Fi QR parser
        parse(payload)
        -> credentials or typed error

    QML UI
        network list
        connection states
        password prompt
        QR actions
        QR scanning state
        errors

The UI should consume normalized state and invoke service operations.
Avoid business logic scattered through visual QML components.

------------------------------------------------------------------------

# 12. Security and privacy

Treat Wi-Fi passwords as secrets.

In particular:

-   never log passwords;
-   never include passwords in debug output;
-   avoid putting credentials into shell command strings where they may
    be exposed unnecessarily;
-   prefer argument arrays/stdin/appropriate NetworkManager APIs;
-   clear transient password state after connection attempts;
-   do not persist credentials independently of NetworkManager;
-   QR decoding should happen locally;
-   do not upload QR images or camera frames anywhere.

Review any existing logging/debugging code touched by this change for
accidental credential leakage.

------------------------------------------------------------------------

# 13. UX details

Aim for a polished QREEP experience.

Where supported by the existing architecture:

-   preserve the network list while rescanning instead of making it
    flash/disappear;
-   update signal strength without rebuilding the entire UI
    unnecessarily;
-   visually distinguish current/known/secured/open networks;
-   disable impossible actions while a connection attempt is active;
-   provide cancel/retry paths;
-   use QREEP's existing animations and transition conventions;
-   provide useful errors rather than raw `nmcli`, D-Bus, or ZBar
    output;
-   do not make the user manually refresh after
    connecting/disconnecting;
-   avoid stealing focus unnecessarily;
-   keyboard interaction should remain sensible.

Do not over-engineer animations at the cost of reliability.

------------------------------------------------------------------------

# 14. Verification

After implementation:

1.  run the project's existing formatting/linting/static checks;

2.  run relevant tests;

3.  add focused tests for pure parsing/state logic if the project has a
    testing strategy that supports them;

4.  manually reason through and, where possible, verify:

    -   Wi-Fi disabled/enabled;
    -   network scan;
    -   rescan;
    -   open network connection;
    -   protected network connection;
    -   saved network reconnection;
    -   wrong password;
    -   disconnect;
    -   failed/unavailable network;
    -   camera QR success;
    -   camera cancellation;
    -   image QR success;
    -   image without QR;
    -   non-Wi-Fi QR;
    -   malformed Wi-Fi QR;
    -   missing `zbarcam`;
    -   missing `zbarimg`;
    -   panel closed while scanning;
    -   scanner process cleanup.

Ensure there are no orphan processes after QR scanning.

------------------------------------------------------------------------

# 15. Documentation

Update the relevant QREEP documentation.

Document:

-   how the Wi-Fi manager works;
-   NetworkManager dependency/architecture;
-   QR support;
-   ZBar dependency;
-   camera scanning;
-   image scanning;
-   supported Wi-Fi QR format;
-   important limitations;
-   any new configuration.

Keep documentation consistent with the project's existing documentation
style.

------------------------------------------------------------------------

# 16. Implementation discipline

This is an **existing project**, not a greenfield implementation.

Therefore:

-   inspect before modifying;
-   follow existing QREEP architecture and naming;
-   reuse existing components;
-   avoid unrelated refactors;
-   do not introduce unnecessary dependencies;
-   do not silently change unrelated behavior;
-   keep changes cohesive;
-   explain architectural decisions that materially change the current
    implementation.

If the current implementation already solves part of this well, preserve
it.

If something requested here conflicts with the actual QREEP
architecture, choose the solution that best fits QREEP and explain the
deviation rather than forcing an inappropriate design.

The final result should make the network module feel like a native,
reliable part of QREEP.
