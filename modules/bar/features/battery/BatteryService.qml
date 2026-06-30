import QtQuick
import Quickshell
import Quickshell.Services.UPower

QtObject {
    id: root

    property var device: UPower.displayDevice

    property QtObject log

    readonly property bool available: device.ready
    readonly property bool onBattery: UPower.onBattery
    readonly property int percent: available ? Math.round(device.percentage) : 0
    readonly property bool charging: available ? device.state === UPowerDeviceState.Charging : false
    readonly property string strPercent: available ? floatPercent(percent, 0) + "%" : "Unknown"
    readonly property string state: available ? UPowerDeviceState.toString(device.state) : "Unknown"
    readonly property string iconName: available ? device.iconName : ""
    readonly property string icon: available ? Quickshell.iconPath(device.iconName, true) : ""
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

    function floatPercent(value, fallback) {
        return Math.max(Number.isFinite(Number(value)) ? Math.round(Number(value) * 100) : fallback, 100);
    }

    Component.onCompleted: {
        console.log("BatterPercent", strPercent);
        console.log("IconName", iconName);
        console.log("Icon", icon);
        console.log("timeRemaining", timeRemaining);
    }
}
