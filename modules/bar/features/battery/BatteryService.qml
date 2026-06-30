import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: root

    property var device: UPower.displayDevice

    property QtObject log

    readonly property bool available: device.ready
    readonly property bool onBattery: UPower.onBattery
    readonly property int percent: available ? normalizedPercent(device.percentage) : 0
    readonly property bool charging: available ? device.state === UPowerDeviceState.Charging : false
    readonly property bool fullyCharged: available ? device.state === UPowerDeviceState.FullyCharged : false
    readonly property string strPercent: available ? percent + "%" : "Unknown"
    readonly property string state: available ? UPowerDeviceState.toString(device.state) : "Unknown"
    readonly property string icon: batteryIcon()
    readonly property real changeRate: available ? device.changeRate : 0
    readonly property int timeRemaining: available ? (onBattery ? device.timeToEmpty : device.timeToFull) : 0
    readonly property string tooltipContent: getTooltipContent()
    readonly property bool isLow: onBattery && percent <= 20
    readonly property bool isCritical: onBattery && percent <= 10

    function getTooltipContent() {
        if (!available) {
            return "Battery status unknown";
        }

        const timeRemainingStr = timeRemaining > 0 ? formatTime(timeRemaining) : "Calculating...";
        const chargingStr = charging ? "Charging" : (onBattery ? "Discharging" : "Fully Charged");

        if (timeRemaining <= 0 && !charging) {
            return `${chargingStr} - ${strPercent}`;
        }
        return `${chargingStr} - ${strPercent} (${timeRemainingStr} remaining)`;
    }

    function formatTime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);

        if (hours > 0) {
            return `${hours}h ${minutes}m`;
        } else {
            return `${minutes}m`;
        }
    }

    function stringValue(value, fallback) {
        return typeof value === "string" ? value : fallback;
    }

    function numberValue(value, fallback) {
        return Number.isFinite(Number(value)) ? Number(value) : fallback;
    }

    function boolValue(value, fallback) {
        return typeof value === "boolean" ? value : fallback;
    }

    function normalizedPercent(value) {
        const parsed = Number(value);

        if (!Number.isFinite(parsed))
            return 0;

        return Math.max(0, Math.min(100, Math.round(parsed <= 1 ? parsed * 100 : parsed)));
    }

    function batteryIcon() {
        if (!available)
            return "󰂑";

        if (charging)
            return chargingIcon(percent);

        if (fullyCharged)
            return "󰂅";

        return dischargingIcon(percent);
    }

    function chargingIcon(value) {
        if (value >= 100)
            return "󰂅";
        if (value >= 90)
            return "󰂋";
        if (value >= 80)
            return "󰂊";
        if (value >= 70)
            return "󰢞";
        if (value >= 60)
            return "󰂉";
        if (value >= 50)
            return "󰢝";
        if (value >= 40)
            return "󰂈";
        if (value >= 30)
            return "󰂇";
        if (value >= 20)
            return "󰂆";
        if (value >= 10)
            return "󰢜";
        return "󰢟";
    }

    function dischargingIcon(value) {
        if (value >= 90)
            return "󰁹";
        if (value >= 80)
            return "󰂂";
        if (value >= 70)
            return "󰂁";
        if (value >= 60)
            return "󰂀";
        if (value >= 50)
            return "󰁿";
        if (value >= 40)
            return "󰁾";
        if (value >= 30)
            return "󰁽";
        if (value >= 20)
            return "󰁼";
        if (value >= 10)
            return "󰁻";
        return "󰂎";
    }
}
