import QtQuick
import Quickshell
import Quickshell.Io

// Vitals controller: which indicators are on, what sensor groups that needs,
// and the display data each pill indicator renders. The pill hides when nothing is on.
Scope {
    id: rootVitals

    required property QtObject theme
    required property QtObject sensors
    property QtObject batteryService: null
    // Bar sets this from pill visibility; sensors only poll while it is true.
    property bool active: false

    readonly property QtObject vitalsTheme: theme.modules.bar.vitals
    readonly property var knownIndicators: ["cpu-usage", "core-usage", "cpu-temp", "core-temps", "cpu-fan", "battery", "disk"]
    readonly property var indicatorGroups: ({
            "cpu-usage": "cpu",
            "core-usage": "cpu",
            "cpu-temp": "sensors",
            "core-temps": "sensors",
            "cpu-fan": "sensors",
            "disk": "disk"
        })
    property var enabledIndicators: knownIndicators.filter(id => vitalsTheme.defaultIndicators.indexOf(id) >= 0)
    readonly property bool hasIndicators: enabledIndicators.length > 0
    readonly property string tooltipContent: tooltipLines().join("\n")
    readonly property var diskInfo: sensors && sensors.disks.length > 0 ? sensors.disks[0] : null

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-vitals"

        function toggleIndicator(id: string): string {
            return rootVitals.toggleIndicator(id);
        }

        function enableIndicator(id: string): string {
            return rootVitals.setIndicatorEnabled(id, true);
        }

        function disableIndicator(id: string): string {
            return rootVitals.setIndicatorEnabled(id, false);
        }

        function setIndicators(ids: string): string {
            return rootVitals.setIndicators(ids);
        }

        function listIndicators(): string {
            return rootVitals.listIndicators();
        }

        function state(): string {
            return rootVitals.tooltipContent;
        }
    }

    // First consumer configures the shared service; Aegis does not touch these yet.
    Component.onCompleted: {
        if (!sensors)
            return;

        sensors.cpuInterval = vitalsTheme.cpuInterval;
        sensors.sensorInterval = vitalsTheme.sensorInterval;
        sensors.diskInterval = vitalsTheme.diskInterval;
        sensors.diskMounts = [vitalsTheme.diskMount];
        sensors.fanMaxRpmOverride = vitalsTheme.fanMaxRpm;
        updateDemand();
    }

    onActiveChanged: updateDemand()
    onEnabledIndicatorsChanged: updateDemand()

    function updateDemand() {
        if (!sensors)
            return;

        const groups = [];

        if (active) {
            for (let index = 0; index < enabledIndicators.length; index++) {
                const group = indicatorGroups[enabledIndicators[index]];
                if (group && groups.indexOf(group) < 0)
                    groups.push(group);
            }
        }

        sensors.setDemand("bar-vitals", groups);
    }

    function isKnown(id) {
        return knownIndicators.indexOf(id) >= 0;
    }

    function isEnabled(id) {
        return enabledIndicators.indexOf(id) >= 0;
    }

    function setIndicatorEnabled(id, value) {
        const normalized = String(id || "").trim().toLowerCase();

        if (!isKnown(normalized))
            return "unknown indicator: " + normalized + " (known: " + knownIndicators.join(", ") + ")";

        // Rebuild from knownIndicators so pill order never depends on toggle order.
        enabledIndicators = knownIndicators.filter(known => known === normalized ? value : isEnabled(known));
        return normalized + " " + (value ? "on" : "off");
    }

    function toggleIndicator(id) {
        return setIndicatorEnabled(id, !isEnabled(String(id || "").trim().toLowerCase()));
    }

    function setIndicators(ids) {
        const wanted = String(ids || "").split(",").map(id => id.trim().toLowerCase()).filter(id => id.length > 0);
        const unknown = wanted.filter(id => !isKnown(id));

        if (unknown.length > 0)
            return "unknown indicator: " + unknown.join(", ") + " (known: " + knownIndicators.join(", ") + ")";

        enabledIndicators = knownIndicators.filter(id => wanted.indexOf(id) >= 0);
        return listIndicators();
    }

    function listIndicators() {
        return knownIndicators.map(id => (isEnabled(id) ? "on  " : "off ") + id).join("\n");
    }

    // fraction is 0..1 of the indicator's max; levels come from VitalsTheme.
    function levelColor(fraction, levels) {
        if (!Number.isFinite(fraction))
            return vitalsTheme.unavailableColor;

        const level = levels.inverted ? 1 - fraction : fraction;

        if (level >= levels.critical)
            return vitalsTheme.criticalColor;
        if (level >= levels.warning)
            return vitalsTheme.warningColor;
        if (level < levels.success)
            return vitalsTheme.successColor;
        return vitalsTheme.normalColor;
    }

    function batteryPercent() {
        return batteryService && batteryService.available ? batteryService.percent : NaN;
    }

    function indicatorItem(id) {
        const t = vitalsTheme;

        if (!sensors)
            return {
                id,
                kind: "gauge",
                value: 0,
                color: t.unavailableColor
            };

        if (id === "cpu-usage")
            return {
                id,
                kind: "pie",
                icon: String.fromCodePoint(0xF4BC),
                value: sensors.cpuUsage / 100,
                color: levelColor(sensors.cpuUsage / 100, t.usageLevels)
            };

        if (id === "core-usage")
            return {
                id,
                kind: "pie-cluster",
                values: sensors.coreUsage.map(value => value / 100),
                colors: sensors.coreUsage.map(value => levelColor(value / 100, t.usageLevels))
            };

        if (id === "cpu-temp")
            return {
                id,
                kind: "gauge",
                icon: String.fromCodePoint(0xF2C9),
                value: sensors.cpuTemp / sensors.cpuTempCrit,
                color: levelColor(sensors.cpuTemp / sensors.cpuTempCrit, t.tempLevels)
            };

        if (id === "core-temps")
            return {
                id,
                kind: "gauge-cluster",
                values: sensors.coreTemps.map(core => core.value / sensors.cpuTempCrit),
                colors: sensors.coreTemps.map(core => levelColor(core.value / sensors.cpuTempCrit, t.tempLevels))
            };

        if (id === "cpu-fan")
            return {
                id,
                kind: "gauge",
                icon: String.fromCodePoint(0xF0210),
                value: sensors.fanRpm / sensors.effectiveFanMaxRpm,
                color: levelColor(sensors.fanRpm / sensors.effectiveFanMaxRpm, t.fanLevels)
            };

        if (id === "battery") {
            const percent = batteryPercent();
            return {
                id,
                kind: "gauge",
                icon: batteryService ? batteryService.icon : String.fromCodePoint(0xF0079),
                value: percent / 100,
                color: levelColor(percent / 100, t.batteryLevels)
            };
        }

        if (id === "disk") {
            const used = diskInfo ? diskInfo.usedPercent : NaN;
            return {
                id,
                kind: "gauge",
                icon: String.fromCodePoint(0xF02CA),
                value: used / 100,
                color: levelColor(used / 100, t.diskLevels)
            };
        }

        return null;
    }

    function tooltipLines() {
        const lines = [];

        if (!sensors)
            return ["Sensors service missing"];

        for (let index = 0; index < enabledIndicators.length; index++) {
            const id = enabledIndicators[index];

            if (id === "cpu-usage")
                lines.push("CPU usage: " + percentText(sensors.cpuUsage));
            else if (id === "core-usage")
                lines.push("Threads: " + (sensors.coreUsage.length > 0 ? sensors.coreUsage.map(value => Math.round(value)).join(" / ") + " %" : "waiting for a second sample"));
            else if (id === "cpu-temp")
                lines.push("CPU temp: " + tempText(sensors.cpuTemp) + " (crit " + Math.round(sensors.cpuTempCrit) + " °C)");
            else if (id === "core-temps")
                lines.push("Cores: " + (sensors.coreTemps.length > 0 ? sensors.coreTemps.map(core => Number.isFinite(core.value) ? Math.round(core.value) : "?").join(" / ") + " °C" : "no per-core sensors"));
            else if (id === "cpu-fan")
                lines.push("Fan: " + (Number.isFinite(sensors.fanRpm) ? Math.round(sensors.fanRpm) + " / " + Math.round(sensors.effectiveFanMaxRpm) + " rpm (" + sensors.fanLabel + ")" : "no fan sensor"));
            else if (id === "battery")
                lines.push("Battery: " + (batteryService ? batteryService.tooltipContent : "unavailable"));
            else if (id === "disk")
                lines.push("Disk " + vitalsTheme.diskMount + ": " + (diskInfo ? formatBytes(diskInfo.freeBytes) + " free of " + formatBytes(diskInfo.totalBytes) + " (" + percentText(diskInfo.usedPercent) + " used)" : "unknown"));
        }

        return lines;
    }

    function percentText(value) {
        return Number.isFinite(value) ? Math.round(value) + "%" : "?";
    }

    function tempText(value) {
        return Number.isFinite(value) ? Math.round(value) + " °C" : "?";
    }

    function formatBytes(bytes) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = Number(bytes) || 0;
        let unit = 0;

        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit++;
        }

        return value.toFixed(unit >= 3 ? 1 : 0) + " " + units[unit];
    }
}
