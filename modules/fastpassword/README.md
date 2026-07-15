# Fast Password

`qreep-fast-password` is a shell-level password entry picker. It shows entry
names, lets Adam search them quickly, and copies the selected password through
the Polkit-gated `qreep-pass-copy` helper.

It does not render secret values in QML. Qreep is the picker, not the vault.
Small mercy, large consequences.

## Files

```text
modules/fastpassword/
├── FastPassword.qml        # Scope/controller, IPC, open state, lazy panel
├── FastPasswordPanel.qml   # centered overlay, search, keyboard list
├── FastPasswordService.qml # list/copy helper calls, filtering, selection
├── FastPasswordTheme.qml   # sizes, colors, motion
└── README.md
```

## Helpers

The module expects three user-level commands:

```bash
qreep-pass-auth
qreep-pass-list
qreep-pass-copy
```

`qreep-pass-auth` asks Polkit for `art.druzd.adam.qreep.pass.copy` before the
chooser opens. The policy uses `auth_self_keep`, so the later copy should reuse
the short-lived authorization instead of asking again immediately.

`qreep-pass-list` lists allowed KeePass entry names. It does not output
passwords. The source for the current helpers and policy lives at:

```text
scripts/qreep-pass-auth_v0.0.1
scripts/qreep-pass-copy_v0.0.2
scripts/qreep-pass-list_v0.0.1
scripts/art.druzd.adam.qreep.pass.policy
```

Install/update the helpers with:

```bash
install -m 0755 scripts/qreep-pass-auth_v0.0.1 ~/.local/bin/qreep-pass-auth
install -m 0755 scripts/qreep-pass-copy_v0.0.2 ~/.local/bin/qreep-pass-copy
install -m 0755 scripts/qreep-pass-list_v0.0.1 ~/.local/bin/qreep-pass-list
```

Install/update the policy with:

```bash
pkexec install -m 0644 scripts/art.druzd.adam.qreep.pass.policy /usr/share/polkit-1/actions/art.druzd.adam.qreep.pass.policy
```

`qreep-pass-auth` writes a short-lived runtime stamp after Polkit accepts the
request. `qreep-pass-copy` checks that stamp without opening another prompt,
enforces the same allowlist through `qreep-pass-list`, then copies the selected
password with `wl-copy --sensitive`. Direct `passw` remains a bypass if somebody
runs it manually; this module only makes the Qreep path behave like a decent
citizen.

## Visible Entries

The chooser is allowlist-based. By default, no config means no visible entries.
Create:

```text
~/.config/qreep/fast-password.json
```

Example:

```json
{
  "entries": [
    "Work/DB"
  ]
}
```

Only entries in that list are printed by `qreep-pass-list` and shown in Qreep.
There is a `showAll: true` escape hatch for debugging, but using it as a daily
setting is just rebuilding the old Rofi situation with nicer clothes.

## IPC

```bash
quickshell ipc call qreep-fast-password toggle
quickshell ipc call qreep-fast-password showMe
quickshell ipc call qreep-fast-password hideMe
quickshell ipc call qreep-fast-password refresh
quickshell ipc call qreep-fast-password copy "Work/DB"
```

## Keyboard

- `Escape` closes.
- Typing filters.
- `Down` moves from search into the list.
- `Up`/`Down` move selection.
- `Enter` copies the selected entry through `qreep-pass-copy` and closes the
  panel.

## Current Boundary

This is the KeePass-backed first slice because that is what `passw` already
knows. Proton Pass / `pass-cli` can replace the helper backend later without
making QML learn how secrets work. That boundary is intentional.
