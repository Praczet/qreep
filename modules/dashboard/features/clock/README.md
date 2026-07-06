# Dashboard Clock Block

The dashboard clock block is a configurable analog clock widget with optional
digital time overlaid on the face and optional date text below it.

It is configured from a dashboard block in:

```text
modules/dashboard/configs/main_dashboard.json
```

The outer dashboard card and the inner clock widget are separate. This is not
philosophy; it is why two borders can appear if both are enabled.

Outer dashboard block flags:

```json
{
  "showBackground": false,
  "showBorder": false
}
```

Inner clock widget flags live under `config`:

```json
{
  "config": {
    "showBackground": false,
    "showBorder": false
  }
}
```

## Example

```json
{
  "id": "clock-analog",
  "type": "clock",
  "anchorPoint": "top-left",
  "dx": 480,
  "dy": 110,
  "width": 280,
  "height": 245,
  "showTitle": false,
  "showBackground": false,
  "showBorder": false,
  "config": {
    "faceColor": "{{on_surface_variant}}",
    "showBackground": false,
    "showBorder": false,
    "showHourHand": true,
    "showMinuteHand": true,
    "showSecondHand": true,
    "showHourMarkers": true,
    "showMinuteMarkers": false,
    "showDigitalClock": true,
    "showDate": true,
    "showDayOfWeek": false,
    "showSeconds": true
  }
}
```

## Config Options

Layout and sizing:

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `width` | number | `240` | Fallback implicit width. Dashboard block `width` is normally the real size. |
| `height` | number | `240` | Fallback implicit height. Dashboard block `height` is normally the real size. |
| `padding` | number | `0` | Inner padding inside the clock widget. |
| `textSpacing` | number | `10` | Space between face and date row. |
| `radius` | number | `18` | Inner clock card corner radius. |
| `faceSize` | number | auto | Preferred face size, capped by available block space. |

Inner card:

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `showBackground` | boolean | `true` | Shows the inner clock card background. |
| `showBorder` | boolean | `true` | Shows the inner clock card border. |
| `cardColor` | color | theme dashboard surface | Inner clock card background color. |
| `cardBorderColor` | color | theme dashboard border | Inner clock card border color. |

Analog face:

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `faceColor` | color | theme module background | Clock face fill color. |
| `faceOpacity` | number | `0.5` | Face fill opacity. |
| `faceBorderColor` | color | theme dashboard border | Outer face circle stroke color. |
| `tickColor` | color | theme secondary text | Hour and minute marker color. |
| `showHourMarkers` | boolean | `true` | Shows the 12 larger markers. |
| `showMinuteMarkers` | boolean | `true` | Shows the 60 smaller markers. |

Hands:

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `showHourHand` | boolean | `true` | Shows the hour hand. |
| `showMinuteHand` | boolean | `true` | Shows the minute hand. |
| `showSecondHand` | boolean | `true` | Shows the second hand. |
| `showSecondsHand` | boolean | `true` | Compatibility alias. Prefer `showSecondHand`. |
| `hourHandColor` | color | theme primary text | Hour hand color. |
| `minuteHandColor` | color | theme calendar header text | Minute hand color. |
| `secondHandColor` | color | theme accent/event color | Second hand color. |
| `centerDotColor` | color | theme primary text | Center dot color. |
| `hourHandOpacity` | number | `1` | Hour hand opacity. |
| `minuteHandOpacity` | number | `1` | Minute hand opacity. |
| `secondHandOpacity` | number | `1` | Second hand opacity. |

Digital time:

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `showDigitalClock` | boolean | `true` | Shows time text overlaid inside the analog face. |
| `timeTextColor` | color | theme primary text | Digital time color. |
| `timePixelSize` | number | auto | Fixed digital time font size. Overrides `timeTextScale`. |
| `timeTextScale` | number | `0.12` | Digital time font size as a fraction of block auto size. |
| `digitalClockYOffset` | number | `0.18` | Vertical offset from face center, as a fraction of `faceSize`. |
| `timeFormat` | string | `"24h"` | Use `"12h"` for 12-hour time. Anything else uses 24-hour time. |

Date:

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `showDate` | boolean | `true` | Shows formatted date below the face. |
| `showDayOfWeek` | boolean | `false` | Shows only day-of-week when `showDate` is false. |
| `dateTextColor` | color | theme secondary text | Date row color. |
| `datePixelSize` | number | auto | Fixed date font size. Overrides `dateTextScale`. |
| `dateTextScale` | number | `0.07` | Date font size as a fraction of block auto size. |
| `dateFormat` | string | `"dddd, yyyy-MM-dd"` | Qt date format used when `showDate` is true. |

Clock service:

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `showSeconds` | boolean | `showSecondHand` | Uses second-level clock updates when true. This does not add seconds to the digital text. |
| `fontFamily` | string | `""` | Optional font family for digital time and date text. |

## Digital Clock Block

Use `type: "digital-clock"` for the plain time/date dashboard widget. The outer
dashboard block owns the rounded surface, border, placement, and animation. The
digital block only renders text. Heroic restraint, somehow.

```json
{
  "id": "clock-digital",
  "type": "digital-clock",
  "anchorPoint": "top-left",
  "dx": 80,
  "dy": 110,
  "width": 426,
  "height": 160,
  "showTitle": false,
  "showBackground": true,
  "showBorder": false,
  "config": {
    "showTime": true,
    "showDate": true,
    "showSeconds": false
  }
}
```

Digital clock config:

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `width` | number | `360` | Fallback implicit width. Dashboard block `width` is normally used. |
| `height` | number | `140` | Fallback implicit height. Dashboard block `height` is normally used. |
| `padding` | number | `18` | Inner padding inside the block. |
| `textSpacing` | number | `8` | Space between time and date text. |
| `showTime` | boolean | `true` | Shows the large time text. |
| `showDate` | boolean | `true` | Shows formatted date below the time. |
| `showDayOfWeek` | boolean | `false` | Shows only day-of-week when `showDate` is false. |
| `showSeconds` | boolean | `false` | Shows seconds and uses second-level clock updates. |
| `timeTextColor` | color | theme primary text | Time text color. |
| `dateTextColor` | color | theme secondary text | Date text color. |
| `timePixelSize` | number | auto | Fixed time font size. Overrides `timeTextScale`. |
| `timeTextScale` | number | `0.48` | Time font size as a fraction of block auto size. |
| `datePixelSize` | number | auto | Fixed date font size. Overrides `dateTextScale`. |
| `dateTextScale` | number | `0.12` | Date font size as a fraction of block auto size. |
| `timeFormat` | string | `"24h"` | Use `"12h"` for 12-hour time. |
| `dateFormat` | string | `"dddd, yyyy-MM-dd"` | Qt date format used when `showDate` is true. |
| `fontFamily` | string | `""` | Optional font family for both text rows. |

## Color Values

Color options accept raw colors:

```json
{
  "faceColor": "#b3d686"
}
```

They also accept theme tokens:

| Token | Meaning |
| --- | --- |
| `{{background}}` | Root background color. |
| `{{surface}}` | Surface color. |
| `{{surface_variant}}` | Variant surface color. |
| `{{surface_container}}` | Container surface color. |
| `{{surface_container_high}}` | Raised container surface color. |
| `{{primary}}` | Primary accent color. |
| `{{secondary}}` | Secondary accent color. |
| `{{tertiary}}` | Tertiary accent color. |
| `{{on_surface}}` | Primary text color on surfaces. |
| `{{on_surface_variant}}` | Secondary text color on surfaces. |
| `{{outline}}` | Border/outline color. |
| `{{outline_variant}}` | Muted border/outline color. |
| `{{error}}` | Error color. |
| `{{warning}}` | Warning color. |
| `{{success}}` | Success color. |

## Reloading

The dashboard service reloads `dashboard.json` when the dashboard opens. If the
dashboard is already open, use:

```bash
quickshell ipc call qreep-dashboard refresh
```

Then close and reopen the dashboard if you changed block placement. QML is not a
mind reader, despite the rumors.
