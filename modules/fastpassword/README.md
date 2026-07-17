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

`qreep-pass-list` lists configured entry metadata as JSON. It does not output
passwords. The source for the current helpers and policy lives at:

```text
scripts/qreep-pass-auth_v0.0.1
scripts/qreep-pass-copy_v0.0.3
scripts/qreep-pass-list_v0.0.3
scripts/art.druzd.adam.qreep.pass.policy
```

Install/update the helpers with:

```bash
install -m 0755 scripts/qreep-pass-auth_v0.0.1 ~/.local/bin/qreep-pass-auth
install -m 0755 scripts/qreep-pass-copy_v0.0.3 ~/.local/bin/qreep-pass-copy
install -m 0755 scripts/qreep-pass-list_v0.0.3 ~/.local/bin/qreep-pass-list
```

Install/update the policy with:

```bash
pkexec install -m 0644 scripts/art.druzd.adam.qreep.pass.policy /usr/share/polkit-1/actions/art.druzd.adam.qreep.pass.policy
```

`qreep-pass-list` is deliberately cheap for normal use: it reads
`fast-password.json`, normalizes metadata, and stops there. It does not open
KeePass, ask GNOME Keyring, or poke Proton just to paint the picker. Backend
checks happen when `qreep-pass-copy` tries to copy the selected entry, where
failure can point at the selected provider instead of making the whole panel
arrive late.

`qreep-pass-auth` writes a short-lived runtime stamp after Polkit accepts the
request. `qreep-pass-copy` checks that stamp without opening another prompt,
enforces the same allowlist through `qreep-pass-list`, then copies the selected
password with `wl-copy --sensitive`.

If `qreep-pass-copy` exits with `6`, QML treats that as a missing, invalid, or
expired auth stamp. It asks Polkit again and retries the same copy request after
authentication instead of shouting through a critical notification like a tiny
fire alarm with feelings.

If Proton Pass is not logged in, the helper exits with `9` and prints a short
`pass-cli login` hint. QML treats that as a provider state warning, not as a
critical Qreep failure.

Copy routing is source-specific:

```text
keepass       keepassxc-cli show -q -a password "$DB" "$key"
proton        pass-cli item view pass:$key
gnome-keyring secret-tool lookup <configured lookup attributes>
```

The Proton key may include the full `pass://` reference. If the key does not
already start with `pass:`, the helper prefixes it. Direct backend commands
remain bypasses if somebody runs them manually; this module only makes the
Qreep path behave like a decent citizen.

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
    {
      "name": "Work/DB",
      "displayName": "Work DB",
      "key": "Work/DB",
      "source": "keepass",
      "icon": "database",
      "desc": ""
    },
    {
      "displayName": "KeePassXC",
      "key": "//Personal/KeePassXC/pass",
      "source": "proton",
      "icon": "proton",
      "desc": "Proton Pass item"
    },
    {
      "displayName": "KeePassXC master password",
      "key": "keepassxc",
      "source": "gnome-keyring",
      "icon": "keyring",
      "desc": "secret-tool lookup app keepassxc",
      "lookup": {
        "app": "keepassxc"
      }
    }
  ]
}
```

String entries still mean KeePass names for compatibility. Object entries use
`displayName` for the picker, `key` for the backend lookup, `source` for
routing, and optional `icon` / `desc` fields for the visible row.

GNOME Keyring entries may include a `lookup` object. A simple map becomes
`secret-tool lookup ATTRIBUTE VALUE`, so this:

```json
"lookup": {
  "app": "keepassxc"
}
```

runs:

```bash
secret-tool lookup app keepassxc
```

For compatibility, missing `lookup` falls back to:

```bash
secret-tool lookup qreep-fast-password "$key"
```

Only entries in that list are printed by `qreep-pass-list` and shown in Qreep.
Normal listing trusts this config as metadata and validates the backend only
when copying. There is a `showAll: true` escape hatch for KeePass debugging,
but that still has to enumerate KeePass and is therefore allowed to be slow.
Using it as a daily setting is just rebuilding the old Rofi situation with nicer
clothes.

## IPC

```bash
quickshell ipc call qreep-fast-password toggle
quickshell ipc call qreep-fast-password showMe
quickshell ipc call qreep-fast-password hideMe
quickshell ipc call qreep-fast-password refresh
quickshell ipc call qreep-fast-password copy "Work/DB"
qreep-pass-copy --source proton --key "//Personal/KeePassXC/pass"
```

## Keyboard

- `Escape` closes.
- Typing filters.
- `Down` moves from search into the list.
- `Up`/`Down` move selection.
- `Enter` copies the selected entry through `qreep-pass-copy` and closes the
  panel.

## Current Boundary

Qreep only sees metadata. KeePass, Proton Pass, and GNOME Keyring lookup logic
stays in the helper scripts, where the ugly bits can wear one hat instead of
wandering through QML.
