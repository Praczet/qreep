# Dashboard Image Block

The image block displays a local image file inside a dashboard card. It is meant
for generated artifacts such as POTATO charts, screenshots, and other files that
already know what they want to look like. Qreep only shows the thing. A bold
concept.

It supports regular bitmap formats and SVG through Qt's `Image` component. If a
format does not load, check Qt image plugin support before blaming the innocent
JSON.

## Example

```json
{
  "id": "potato-weight",
  "type": "image",
  "anchorPoint": "top-right",
  "dx": -128,
  "dy": 110,
  "width": 800,
  "height": 307,
  "showTitle": false,
  "showBackground": false,
  "showBorder": false,
  "config": {
    "path": "~/.cache/potato/weight.svg",
    "fillMode": "preserveAspectFit",
    "smooth": true,
    "mipmap": true,
    "cache": false
  }
}
```

## Config Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `path` | string | `""` | Image path. `~/` expands to `$HOME/`. |
| `width` | number | `320` | Fallback implicit width. Dashboard block `width` is normally used. |
| `height` | number | `180` | Fallback implicit height. Dashboard block `height` is normally used. |
| `showBackground` | boolean | `false` | Paints a QML background behind the image. Useful when SVG percentage backgrounds render like they had a long day. |
| `backgroundColor` | color | theme dashboard surface | QML background color. Supports theme tokens. |
| `radius` | number | dashboard card radius | QML background corner radius. |
| `fillMode` | string | `"preserveAspectFit"` | `stretch`, `preserveAspectFit`, `fit`, `preserveAspectCrop`, `crop`, `tile`, `tileVertically`, `tileHorizontally`, or `pad`. |
| `horizontalAlignment` | string | `"center"` | `left`, `center`, or `right`. |
| `verticalAlignment` | string | `"center"` | `top`, `center`, or `bottom`. |
| `opacity` | number | `1` | Opacity for the whole block. |
| `smooth` | boolean | `true` | Enables smooth image filtering. |
| `mipmap` | boolean | `true` | Enables mipmap filtering when supported. |
| `cache` | boolean | `false` | Qt image cache. Defaults false because generated charts may change. |
| `asynchronous` | boolean | `true` | Loads image asynchronously. |
| `clip` | boolean | `true` | Clips image content to block bounds. |
