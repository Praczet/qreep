# Dashboard Weather

First dashboard weather block. It uses Open-Meteo through `curl`, because no API
key is a fine feature when the alternative is inventing account management for a
weather card.

Use it from `modules/dashboard/configs/main_dashboard.json`:

```json
{
  "type": "weather",
  "showTitle": false,
  "config": {
    "apiEnabled": true,
    "location": "Bergem, Luxembourg",
    "latitude": 49.524509,
    "longitude": 6.044283,
    "timezone": "Europe/Luxembourg",
    "refreshInterval": 1800000,
    "temperature": "37°C",
    "condition": "Overcast",
    "wind": "Wind 9 km/h",
    "icon": "weather-overcast-symbolic",
    "forecast": [
      { "day": "Sat, Jun 27", "low": 20, "high": 38, "icon": "weather-overcast-symbolic" }
    ]
  }
}
```

`temperature`, `condition`, `wind`, `icon`, and `forecast` are fallback values
shown before the first API response or when `apiEnabled` is `false`.

The block expects the dashboard card wrapper to handle placement, size,
background, border, and animation. This file only owns weather content.
