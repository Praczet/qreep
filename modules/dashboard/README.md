# Dashboard Module

Qreep dashboard is a top-level shell surface, not a bar-owned popup.

This is the dashboard engine and the main dashboard instance. Aegis also uses
this renderer, but it has its own IPC target and config. Do not make the main
dashboard carry Aegis blocks just because the renderer can.

The first draft is deliberately fake: it loads configured blocks and proves the
canvas, card sizing, positioning, title/chrome flags, and entry animation. Real
blocks can arrive after the surface stops doing interpretive dance.

## IPC

```bash
quickshell ipc call qreep-dashboard toggle
quickshell ipc call qreep-dashboard showMe
quickshell ipc call qreep-dashboard hideMe
quickshell ipc call qreep-dashboard refresh
```

## Config

The draft config lives at:

```text
modules/dashboard/configs/main_dashboard.json
```

This is repo-local for now so it can be reviewed with the module. User config can
move to `~/.config/quickshell/qreep/dashboard.json` once the schema is less
likely to change every time someone looks at it funny.

Aegis uses the same schema from:

```text
modules/dashboard/configs/aegis_dashboard.json
```

## Blocks

Current real blocks:

- `clock` / `digital-clock`: local clock displays.
- `aegis*`: system overview blocks backed by the Aegis service.
- `bloom`: last Unclaimed Bloom wallpaper/profile/palette card.
- `borg`: last Borg backup card. It watches `~/.cache/qreep/borg/state.json`
  and falls back to `~/.cache/qreep/borg/final.json` for archive metadata.

Blocks use explicit `width` and `height`. Preferred placement is anchored:

```json
{
  "anchorPoint": "middle-center",
  "dx": 0,
  "dy": 0
}
```

`anchorPoint` supports `top-left`, `top-center`, `top-right`, `middle-left`,
`middle-center`, `middle-right`, `bottom-left`, `bottom-center`, and
`bottom-right`. `dx` and `dy` offset from that anchor. Old `x`/`y` top-left
placement still works as fallback while the draft is learning to behave.

### Card Style

Every block is rendered inside a `DashboardCard`. Shared card chrome can be set
once with `cardStyle`, then overridden by any block that needs to be special.
Special blocks should justify themselves quietly.

```json
{
  "cardStyle": {
    "color": "{{on_surface}}",
    "backgroundColor": "{{surface}}",
    "borderColor": "{{outline}}",
    "radius": 18,
    "borderWidth": 1,
    "padding": 20
  },
  "blocks": [
    {
      "id": "plain-card",
      "type": "fake",
      "showBackground": true,
      "showBorder": true
    },
    {
      "id": "louder-card",
      "type": "fake",
      "color": "{{on_surface_variant}}",
      "backgroundColor": "{{surface_container}}",
      "borderColor": "{{primary}}",
      "radius": 10,
      "borderWidth": 2,
      "padding": 16
    }
  ]
}
```

Top-level block style options:

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `showBackground` | boolean | `true` | Paints the outer card background. |
| `showBorder` | boolean | `true` | Paints the outer card border. |
| `color` | color string | `cardStyle.color`, then dashboard text color | Outer card title/body/meta text color. Feature blocks may still use their own colors. |
| `backgroundColor` | color string | `cardStyle.backgroundColor`, then dashboard theme surface | Outer card background. |
| `borderColor` | color string | `cardStyle.borderColor`, then dashboard theme border | Outer card border and title divider. |
| `radius` | number | `cardStyle.radius`, then dashboard theme radius | Outer card corner radius. |
| `borderWidth` | number | `cardStyle.borderWidth`, then dashboard theme border width | Outer card border width. |
| `padding` | number | `cardStyle.padding`, then dashboard theme padding | Inner content margin. |

Supported theme color tokens:

```text
{{background}}, {{surface}}, {{surface_variant}}, {{surface_container}},
{{surface_container_high}}, {{surface_container_highest}}, {{primary}},
{{primary_container}}, {{primary_fixed_dim}}, {{secondary}}, {{tertiary}},
{{on_background}}, {{on_surface}}, {{on_surface_variant}}, {{on_primary}},
{{on_primary_container}}, {{outline}}, {{outline_variant}}, {{error}},
{{warning}}, {{success}}
```

## Hyprland

Layer namespace:

```text
qreep-dashboard
```

Blur belongs in Hyprland layer rules. QML should control the overlay opacity and
card surfaces; Hyprland can do the blur without QML pretending to be a compositor
with hobbies.
