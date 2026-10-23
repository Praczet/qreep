# Qreep

Qreep is Adam's Quickshell shell. It started as a Waybar-shaped experiment and
is now exactly the sort of thing that needs documentation before future Adam
starts guessing. Guessing is how tiny panels become archaeology.

This file is the map. The details live in each module's README, because a
detail copied into two places ages at two different speeds.

## Run

Qreep is installed by symlinking the repo into Quickshell's config directory:

```bash
ln -s ~/Development/Hyprland/quickshell/Qreep ~/.config/quickshell/qreep
quickshell -c qreep
```

Use this when relaunching during tests:

```bash
quickshell -c qreep --no-duplicate
```

That second command refuses to spawn another copy if one is already running.
Useful if you do not want a bar colony.

IPC examples below use the short `quickshell ipc call ...` form. Module READMEs
often spell it `quickshell --path ~/Development/Hyprland/quickshell/Qreep ipc
call ...`; both reach the same instance. Some Quickshell versions vary slightly
in CLI syntax. If this bites, check `quickshell ipc --help`.

## Layout

```text
shell.qml        hosts the bar and every top-level module
core/            shared services (sound, system sensors)
components/      reusable UI pieces
modules/         top-level modules, one folder each
modules/bar/features/   bar-owned pills, panels, services, and popups
theme/           public theme entry point and generated colours
scripts/         helper scripts, systemd units, Polkit policy, install
tools/           jarvis (KIP backend) and triagectl (Triage helper)
fixtures/        test data, currently for Qreeper
docs/            bar ownership map, mot-du-jour pipeline, archive
```

Reusable wrappers stay in `components/`. Theme entry points stay in `theme/`.
Old agent briefs live in [`docs/archive/`](docs/archive/README.md) and describe
plans, not the current code.

## Module index

Top-level modules, all hosted directly by `shell.qml`. Keybinds are the ones in
Adam's Hyprland `binds.lua`, not something Qreep sets.

| Module | What it is | IPC target | Keybind | Docs |
| --- | --- | --- | --- | --- |
| Aegis | system information overlay on the dashboard renderer | `qreep-aegis` | `SUPER+SHIFT+Escape` | [README](modules/aegis/README.md) |
| Bloom | Unclaimed Bloom progress card | `qreep-bloom` | — | [README](modules/bloom/README.md) |
| Clipboard | clipvault history with search, pins, image previews | `qreep-clipboard` | `SUPER+SHIFT+V` | [README](modules/clipboard/README.md) |
| Dashboard | main dashboard of JSON-configured blocks | `qreep-dashboard` | `SUPER+Escape` | [README](modules/dashboard/README.md) |
| Expose | window overview with live previews and search | `qreep-expose` | `SUPER+Tab` | [README](modules/expose/README.md) |
| Fast Password | Polkit-gated, allowlisted KeePass entry copier | `qreep-fast-password` | `SUPER+SHIFT+L` | [README](modules/fastpassword/README.md) |
| KIP | launcher, slash commands, local-AI prompt | `qreep-kip` | `SUPER+Space`, `SUPER+/`, `SUPER+F1`, `SUPER+F2`, `SUPER+SHIFT+C` | [README](modules/kip/README.md) |
| Notification | notification server, popups, centre | `qreep-notification` | `SUPER+N`, `SUPER+SHIFT+N` | [README](modules/notification/README.md) |
| OSD | on-screen messages, progress, volume, brightness | `osd` | — | [README](modules/osd/README.md) |
| Places | project cockpit plus folders, drives, shares, hosts | `qreep-places` | `SUPER+grave` | [README](modules/places/README.md) |
| Polkit | session auth agent, with a demo mode | `qreep-polkit` | — | [README](modules/polkit/README.md) |
| Prism | colour history, favourites, palettes, harmonies | `qreep-prism` | `SUPER+P` (pick), `SUPER+SHIFT+P` | [README](modules/prism/README.md) |
| Qreeper | Qreeper map minimap and Atlas, on demand | `qreep-qreeper` | — | [README](modules/qreeper/README.md) |
| Screenshot | delayed region screenshot panel | `qreep-screenshot` | `Ctrl+Print` | [README](modules/screenshot/README.md) |
| Timer | count-up and countdown panel | `qreep-timer` | `SUPER+Q` | [README](modules/timer/README.md) |
| Triage | Arch package triage, read-only against the system | `qreep-triage` | — | [README](modules/triage/README.md) |
| Wallpaper | wallpaper picker that hands off to `wallset` | `qreep-wallpaper` | `SUPER+T` | [README](modules/wallpaper/README.md) |

Bar features under `modules/bar/features/`:

| Feature | What it is | IPC target | Docs |
| --- | --- | --- | --- |
| battery | UPower battery pill | — | [README](modules/bar/features/battery/README.md) |
| borg | Borg backup state and progress popup | `qreep-borg` | [README](modules/bar/features/borg/README.md) |
| clock | clock, calendar popup, calendar sync | `qreep-calendar` | [README](modules/bar/features/clock/README.md) |
| language | keyboard layout pill | `qreep-language` | [README](modules/bar/features/language/README.md) |
| launcher | button that opens KIP | — | [README](modules/bar/features/launcher/README.md) |
| monitorprofile | monitor layout icons from runtime JSON | `qreep-monitor-profile` | [README](modules/bar/features/monitorprofile/README.md) |
| mpris | media pill, preview tooltip, player popup | `qreep-mpris` | [README](modules/bar/features/mpris/README.md) |
| network | wired, Wi-Fi, and Bluetooth pill and panel | — | [README](modules/bar/features/network/README.md) |
| potatofast | POTATO fasting progress pill | `qreep-potato-fast` | [README](modules/bar/features/potatofast/README.md) |
| power | power panel, normal and fullscreen | `qreep-power` | [README](modules/bar/features/power/README.md) |
| qreeper | compass pill, only during a Qreeper session | — | [`modules/qreeper/README.md`](modules/qreeper/README.md) |
| timer | active timer pill | — | [README](modules/bar/features/timer/README.md) |
| tray | StatusNotifier system tray | — | [README](modules/bar/features/tray/README.md) |
| upchecker | update pill and panel, with Triage badges | `qreep-upchecker` | [README](modules/bar/features/upchecker/README.md) |
| vitals | runtime-toggleable CPU, temp, fan, battery, disk gauges | `qreep-vitals` | [README](modules/bar/features/vitals/README.md) |
| volume | volume pill with OSD feedback | — | [README](modules/bar/features/volume/README.md) |
| workspaces | Hyprland workspaces and client popup | — | [README](modules/bar/features/workspaces/README.md) |

Dashboard blocks have their own READMEs under `modules/dashboard/features/`
(clock, image, weather, wotd). The word-of-the-day pipeline is in
[`docs/mot-du-jour.md`](docs/mot-du-jour.md).

## Bar

The main bar is `modules/bar/Bar.qml`.

It owns:

- the left, center, right, and overlay slots;
- shared services used by bar modules;
- shared tooltip surfaces;
- feature panels/popups that are opened from bar buttons.

The detailed ownership map lives in
[`docs/bar-ownership-map.md`](docs/bar-ownership-map.md). Read that before
moving feature surfaces around. It is cheaper than guessing, which remains a
popular but poorly reviewed debugging strategy.

Bar mode and screen:

```bash
quickshell ipc call qreep-bar getMode
quickshell ipc call qreep-bar setMode reserved    # or overlay, collapsed
quickshell ipc call qreep-bar toggleCollapsed
quickshell ipc call qreep-bar moveToFocused       # bar follows you on request, not on every focus change
quickshell ipc call qreep-bar getScreen
```

Pill state uses two separate ideas:

```bash
quickshell ipc call qreep-bar-pill enablePill clock    # add pill to the bar
quickshell ipc call qreep-bar-pill disablePill clock   # remove pill from the bar
quickshell ipc call qreep-bar-pill expandPill clock    # full-size in collapsed mode
quickshell ipc call qreep-bar-pill collapsePill clock  # collapsed strip in collapsed mode
quickshell ipc call qreep-bar-pill listPills           # list known pill state
```

So in collapsed mode, `enablePill` makes the pill present, and `expandPill`
makes it full-size. Separate switches. Fewer surprise side effects, which is a
lifestyle choice.

Current known runtime pills are `clock`, `workspaces`, `mpris`, `timer`,
`upchecker`, `monitorprofile`, `borg`, `potato-fast`, `vitals`, `battery`,
`network`, `language`, `volume`, `qreeper`, and `tray`. Unknown pill IDs return
an error instead of inventing state for `banana`, which is growth.

## Hyprland layer rules

Every surface has its own namespace, so every surface can get its own rule.
The bar is not the power panel. This is a useful fact, despite everything
trying to make it annoying.

`ignore_alpha` tells Hyprland not to blur behind pixels at or below that alpha.
It is how a full-screen layer gets blur only where it should:

- `0.1` blurs everything that is not fully transparent. KIP depends on this:
  its faint full-screen backdrop (alpha 0.18) sits just above it on purpose, so
  the whole desktop behind KIP blurs while the card stays sharp.
- `0.5` sits between a dimmed backdrop (about 0.32) and a card (about 0.75), so
  the backdrop dims without blurring and only the card blurs. Places uses
  this.

What Adam's config currently does:

| Namespace | Blur | `ignore_alpha` | Notes |
| --- | --- | --- | --- |
| `qreep-bar` | no | — | do not blur this; transparent edges get halos |
| `qreep-popup-power` | yes | 0.5 | |
| `qreep-popup-workspace-clients` | yes | 0.5 | |
| `qreep-popup-upchecker` | yes | 0.1 | `blur_popups` |
| `qreep-popup-osd` | yes | 0.1 | `blur_popups` |
| `qreep-places` | yes | 0.5 | backdrop dims, card blurs |
| `qreep-kip` | yes | 0.1 | backdrop above the threshold on purpose |
| `qreep-aegis`, `qreep-dashboard`, `qreep-expose` | yes | 0.1 | |
| `qreep-clipboard`, `qreep-timer`, `qreep-triage` | yes | 0.1 | |
| `qreep-notification`, `qreep-notification-center` | yes | 0.1 | surfaces are input-masked too |
| `qreep-polkit`, `qreep-fast-password`, `qreep-bloom` | yes | 0.1 | |

Not given rules yet: `qreep-screenshot`, `qreep-qreeper-minimap`, and
`qreep-qreeper-atlas`.

Rule shape, in the Lua config syntax:

```lua
hl.layer_rule({
    name = "qreep-kip",
    match = { namespace = "qreep-kip" },
    blur = true,
    ignore_alpha = 0.1,
})
```

## Hyprland window rules

Not everything is a layer. Triage, Prism, and Wallpaper are `FloatingWindow`s:
normal Hyprland windows you can move, resize, and send to another workspace.
Hyprland tiles them by default, which is a choice it makes without asking.

To open them floating and centred, at the size Qreep asks for, add a window
rule to `~/.config/hypr/modules/windows.lua` (Adam's config; anything Hyprland
loads works). The match is the window title, which each panel sets:

| Title | Module |
| --- | --- |
| `Qreep Prism` | Prism |
| `Qreep Wallpaper` | Wallpaper |
| `Qreep Triage` | Triage (not in Adam's rule; it still tiles) |

```lua
hl.window_rule({
    name = "windowrule-qreep-floating",
    match = { title = "^Qreep (Prism|Wallpaper)$" },
    float = true,
    center = true,
})
```

Then reload and check Hyprland agrees:

```bash
# Reload the Hyprland config and print any config errors (empty is good).
hyprctl reload && hyprctl configerrors

# Open Prism, then list Qreep windows with their floating state and geometry.
quickshell -c qreep ipc call qreep-prism showMe
hyprctl clients -j | jq '.[] | select(.title | startswith("Qreep")) | {title, floating, size, at}'
```

`center` centres on the usable area, so the bar's reserved space pushes the
window down a little. That is arithmetic, not a bug.

The old `qreep-prism` and `qreep-wallpaper` layer rules match nothing now and
can be deleted.

## Theme

The public theme object is `theme/QreepTheme.qml`. Colours come from
`theme/colors/UnclaimedBloomColors.qml`, generated by Unclaimed Bloom from
`theme/colors/template.qml`. Do not hand-edit the generated file; the next
wallpaper change will undo you without asking.

Module theme files live with their owning module and are aggregated by
`modules/ModulesTheme.qml`:

```text
modules/<module>/<Module>Theme.qml            one per top-level module
modules/bar/BarTheme.qml                      bar, plus BarPillTheme and TooltipTheme
modules/bar/features/<feature>/*Theme.qml     one per bar feature that needs tokens
modules/dashboard/features/aegis/AegisTheme.qml   Aegis lives here, not in modules/aegis/
```

`QreepTheme.qml` exposes global semantic colours and the aggregated module
theme:

```qml
readonly property QtObject modules: Modules.ModulesTheme {
    qreep: rootQreepTheme
}
```

Old paths such as `theme.module`, `theme.tooltip`, and `theme.dashboard` remain
as compatibility aliases for now. New module-specific code should prefer paths
like `theme.modules.aegis`, `theme.modules.bar.pill`,
`theme.modules.bar.tooltip`, `theme.modules.dashboard`, and
`theme.modules.notification`.

If a feature needs sizes, spacing, timing, or command names, put them in that
feature's theme file. Hardcoding in the button is how the next tweak becomes a
search warrant.

## Install

```bash
scripts/install
```

Copies the versioned helper scripts to stable names in `~/.local/bin`:

```text
qreep-bloom-notify
qreep-calendar-sync
qreep-calendar-google-sync
qreep-calendar-microsoft-ics-sync
qreep-calendar-microsoft-sync
qreep-calendar-pull
qreep-notification-test-batch
qreep-region-screenshot-delay
```

It also builds and installs `triagectl` with cargo (skipped with a message if
cargo is missing), and installs the calendar user units:

```text
~/.config/systemd/user/qreep-calendar-sync.service
~/.config/systemd/user/qreep-calendar-sync.timer
```

Enable the timer only when wanted:

```bash
systemctl --user enable --now qreep-calendar-sync.timer
```

Not installed by `scripts/install`, on purpose or out of laziness:

- the `qreep-pass-*` helpers and the Polkit policy; see
  [`modules/fastpassword/README.md`](modules/fastpassword/README.md), because
  installing a policy needs root and deserves a deliberate moment;
- `jarvis` and its prompts; see [`tools/jarvis/README.md`](tools/jarvis/README.md);
- `wallpaper-thumbs`, which runs from the repo next to its QML.

## Validation

Small useful checks:

```bash
qmllint modules/bar/Bar.qml
qmllint theme/QreepTheme.qml
qmllint modules/<module>/*.qml
```

For broader changes:

```bash
qmllint modules/bar/Bar.qml theme/QreepTheme.qml modules/bar/features/*/*.qml
git diff --check
```

Runtime smoke test:

```bash
quickshell -c qreep --no-duplicate
```

If it says an instance is already running, that is not a failed launch. It is the
command doing what the flag says. Suspiciously rare behavior.
