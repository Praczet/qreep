import QtQuick
import Quickshell.Io

QtObject {
    id: rootWeatherService

    property var config: ({})
    property string location: stringValue(config.location, "Bergem, Luxembourg")
    property string temperature: stringValue(config.temperature, "--°C")
    property real currentTemperature: parseTemperature(config.temperature, 0)
    property string condition: stringValue(config.condition, "Weather unavailable")
    property string wind: stringValue(config.wind, "")
    property string icon: stringValue(config.icon, "weather-overcast-symbolic")
    property var forecast: Array.isArray(config.forecast) ? config.forecast : []
    property string error: ""
    property bool loading: false
    property bool pendingRefresh: false

    readonly property real latitude: numberValue(config.latitude, 49.524509)
    readonly property real longitude: numberValue(config.longitude, 6.044283)
    readonly property string timezone: stringValue(config.timezone, "Europe/Luxembourg")
    readonly property int refreshInterval: Math.max(300000, numberValue(config.refreshInterval, 1800000))
    readonly property bool apiEnabled: config.apiEnabled !== false
    readonly property string requestUrl: "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + encodeURIComponent(latitude)
        + "&longitude=" + encodeURIComponent(longitude)
        + "&current=temperature_2m,weather_code,wind_speed_10m,is_day"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
        + "&timezone=" + encodeURIComponent(timezone)
        + "&forecast_days=7"
        + "&wind_speed_unit=kmh"

    readonly property Process fetchRunner: Process {
        id: fetchRunner

        stdout: StdioCollector {
            id: weatherStdout

            waitForEnd: true
        }

        stderr: StdioCollector {
            id: weatherStderr

            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            rootWeatherService.applyOutput(weatherStdout.text, weatherStderr.text, exitCode);

            if (rootWeatherService.pendingRefresh) {
                rootWeatherService.pendingRefresh = false;
                rootWeatherService.refresh();
            }
        }
    }

    readonly property Timer refreshTimer: Timer {
        interval: rootWeatherService.refreshInterval
        repeat: true
        running: rootWeatherService.apiEnabled
        onTriggered: rootWeatherService.refresh()
    }

    function refresh() {
        if (!apiEnabled)
            return;

        if (fetchRunner.running) {
            pendingRefresh = true;
            return;
        }

        loading = true;
        fetchRunner.running = false;
        fetchRunner.command = ["curl", "-fsS", "--max-time", "10", requestUrl];
        fetchRunner.running = true;
    }

    function applyOutput(stdoutText, stderrText, exitCode) {
        loading = false;

        if (exitCode !== 0) {
            error = String(stderrText || "curl exited with code " + exitCode).trim();
            return;
        }

        try {
            applyPayload(JSON.parse(String(stdoutText || "{}")));
        } catch (parseError) {
            error = "Weather JSON parse error: " + parseError;
        }
    }

    function applyPayload(payload) {
        const current = payload && payload.current ? payload.current : ({});
        const daily = payload && payload.daily ? payload.daily : ({});
        const code = numberValue(current.weather_code, 3);

        temperature = Math.round(numberValue(current.temperature_2m, 0)) + "°C";
        currentTemperature = numberValue(current.temperature_2m, currentTemperature);
        condition = conditionText(code);
        wind = "Wind " + Math.round(numberValue(current.wind_speed_10m, 0)) + " km/h";
        icon = iconName(code, numberValue(current.is_day, 1) === 1);
        forecast = dailyForecast(daily);
        error = "";
    }

    function dailyForecast(daily) {
        const times = Array.isArray(daily.time) ? daily.time : [];
        const lows = Array.isArray(daily.temperature_2m_min) ? daily.temperature_2m_min : [];
        const highs = Array.isArray(daily.temperature_2m_max) ? daily.temperature_2m_max : [];
        const codes = Array.isArray(daily.weather_code) ? daily.weather_code : [];
        const result = [];
        const count = Math.min(7, times.length);

        for (let index = 0; index < count; index++) {
            const code = numberValue(codes[index], 3);

            result.push({
                day: dayLabel(times[index]),
                low: Math.round(numberValue(lows[index], 0)),
                high: Math.round(numberValue(highs[index], 0)),
                icon: iconName(code, true)
            });
        }

        return result.length > 0 ? result : Array.isArray(config.forecast) ? config.forecast : [];
    }

    function dayLabel(dateText) {
        const parts = String(dateText || "").split("-");

        if (parts.length !== 3)
            return String(dateText || "");

        const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

        return days[date.getDay()] + ", " + months[date.getMonth()] + " " + String(date.getDate()).padStart(2, "0");
    }

    function conditionText(code) {
        switch (code) {
        case 0:
            return "Clear";
        case 1:
        case 2:
            return "Partly cloudy";
        case 3:
            return "Overcast";
        case 45:
        case 48:
            return "Fog";
        case 51:
        case 53:
        case 55:
        case 56:
        case 57:
            return "Drizzle";
        case 61:
        case 63:
        case 65:
        case 66:
        case 67:
            return "Rain";
        case 71:
        case 73:
        case 75:
        case 77:
            return "Snow";
        case 80:
        case 81:
        case 82:
            return "Showers";
        case 85:
        case 86:
            return "Snow showers";
        case 95:
        case 96:
        case 99:
            return "Thunderstorm";
        default:
            return "Weather";
        }
    }

    function iconName(code, isDay) {
        if (code === 0)
            return isDay ? "weather-clear-symbolic" : "weather-clear-night-symbolic";
        if (code === 1 || code === 2)
            return isDay ? "weather-few-clouds-symbolic" : "weather-few-clouds-night-symbolic";
        if (code === 3)
            return "weather-overcast-symbolic";
        if (code === 45 || code === 48)
            return "weather-fog-symbolic";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return "weather-showers-symbolic";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "weather-snow-symbolic";
        if (code >= 95)
            return "weather-storm-symbolic";

        return "weather-overcast-symbolic";
    }

    function stringValue(value, fallback) {
        return typeof value === "string" && value.length > 0 ? value : fallback;
    }

    function numberValue(value, fallback) {
        return Number.isFinite(Number(value)) ? Number(value) : fallback;
    }

    function parseTemperature(value, fallback) {
        const match = String(value || "").match(/-?\d+(\.\d+)?/);

        return match ? Number(match[0]) : fallback;
    }

    onConfigChanged: {
        location = stringValue(config.location, "Bergem, Luxembourg");
        temperature = stringValue(config.temperature, temperature);
        currentTemperature = parseTemperature(config.temperature, currentTemperature);

        if (apiEnabled)
            refresh();
    }

    Component.onCompleted: refresh()
}
