import QtQuick
import Quickshell
import Quickshell.Io

// Shared live system sensors: CPU usage from /proc/stat, CPU/core temps and
// fans from hwmon, disk usage from df. Nothing polls until a consumer asks for
// a group through setDemand(), so an idle sensor costs nothing.
//
// hwmon devices are resolved by their `name` file, never by hwmonN index;
// the kernel reshuffles those between boots.
Scope {
    id: rootSystemSensorsService

    property int cpuInterval: 2000
    property int sensorInterval: 3000
    property int diskInterval: 60000
    property var diskMounts: ["/"]
    // 0 = use the driver's fanN_max, then the highest rpm seen this session.
    property int fanMaxRpmOverride: 0

    property var demand: ({})
    readonly property bool cpuWanted: groupWanted("cpu")
    readonly property bool sensorsWanted: groupWanted("sensors")
    readonly property bool diskWanted: groupWanted("disk")

    // CPU usage, percent. coreUsage is per logical CPU (threads), not per core.
    property real cpuUsage: 0
    property var coreUsage: []
    property var previousCpuSample: null

    // Temperatures in degrees C. coreTemps is per physical core.
    property real cpuTemp: NaN
    property real cpuTempCrit: 100
    property var coreTemps: []
    property string cpuTempSource: ""

    property real fanRpm: NaN
    property real fanMaxRpm: 0
    property real fanPeakRpm: 0
    property string fanSource: ""
    // Which fan is currently the busiest, e.g. "fan2".
    property string fanLabel: ""
    readonly property real effectiveFanMaxRpm: fanMaxRpmOverride > 0 ? fanMaxRpmOverride : (fanMaxRpm > 0 ? fanMaxRpm : Math.max(1, fanPeakRpm))

    property var disks: []

    // Resolved sensor files: { cpuTemp, cores: [{ label, path }], fans: [{ label, path }] }.
    property var sensorMap: null
    property bool discovered: false

    readonly property FileView procStat: FileView {
        path: "/proc/stat"
        // reload() is a no-op without preload in Quickshell 0.3.2. One read at
        // startup is cheap; after that the cpu timer drives reload().
        preload: true

        onLoaded: rootSystemSensorsService.applyCpuStat(text())
    }

    readonly property Process discoveryRunner: Process {
        command: ["sh", "-c", rootSystemSensorsService.discoveryScript()]

        stdout: StdioCollector {
            id: discoveryStdout
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootSystemSensorsService.applyDiscovery(discoveryStdout.text)
    }

    readonly property Process sensorRunner: Process {
        stdout: StdioCollector {
            id: sensorStdout
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootSystemSensorsService.applySensorValues(sensorStdout.text)
    }

    readonly property Process diskRunner: Process {
        stdout: StdioCollector {
            id: diskStdout
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootSystemSensorsService.applyDisks(diskStdout.text)
    }

    readonly property Timer cpuTimer: Timer {
        interval: rootSystemSensorsService.cpuInterval
        repeat: true
        running: rootSystemSensorsService.cpuWanted
        triggeredOnStart: true
        onTriggered: rootSystemSensorsService.procStat.reload()
    }

    readonly property Timer sensorTimer: Timer {
        interval: rootSystemSensorsService.sensorInterval
        repeat: true
        running: rootSystemSensorsService.sensorsWanted
        triggeredOnStart: true
        onTriggered: rootSystemSensorsService.refreshSensors()
    }

    readonly property Timer diskTimer: Timer {
        interval: rootSystemSensorsService.diskInterval
        repeat: true
        running: rootSystemSensorsService.diskWanted
        triggeredOnStart: true
        onTriggered: rootSystemSensorsService.refreshDisks()
    }

    onCpuWantedChanged: {
        if (!cpuWanted)
            previousCpuSample = null;
    }

    // Declare which groups ("cpu", "sensors", "disk") a consumer needs.
    // An empty list releases the consumer.
    function setDemand(id, groups) {
        const next = Object.assign({}, demand);
        next[String(id || "default")] = Array.isArray(groups) ? groups.slice() : [];
        demand = next;
    }

    function groupWanted(group) {
        return Object.keys(demand).some(id => demand[id].indexOf(group) >= 0);
    }

    function refreshSensors() {
        if (!discovered) {
            if (!discoveryRunner.running)
                discoveryRunner.running = true;
            return;
        }

        const files = sensorFiles();

        if (files.length === 0 || sensorRunner.running)
            return;

        // grep -H . prints "path:value" for every readable file in one exec.
        sensorRunner.command = ["grep", "-H", "."].concat(files);
        sensorRunner.running = true;
    }

    function refreshDisks() {
        if (diskRunner.running)
            return;

        diskRunner.command = ["df", "-B1", "-P"].concat(diskMounts);
        diskRunner.running = true;
    }

    function discoveryScript() {
        // One line per temp/fan input: name|input|label|max|crit
        return "for h in /sys/class/hwmon/hwmon*; do "
            + "n=$(cat \"$h/name\" 2>/dev/null); "
            + "for f in \"$h\"/temp*_input \"$h\"/fan*_input; do "
            + "[ -r \"$f\" ] || continue; b=${f%_input}; "
            + "printf '%s|%s|%s|%s|%s\\n' \"$n\" \"$f\" \"$(cat \"${b}_label\" 2>/dev/null)\" \"$(cat \"${b}_max\" 2>/dev/null)\" \"$(cat \"${b}_crit\" 2>/dev/null)\"; "
            + "done; done";
    }

    function applyDiscovery(text) {
        const rows = String(text || "").split(/\r?\n/).filter(line => line.length > 0).map(line => {
            const parts = line.split("|");
            return {
                name: parts[0] || "",
                path: parts[1] || "",
                label: parts[2] || "",
                max: Number(parts[3]) || 0,
                crit: Number(parts[4]) || 0
            };
        });

        const temps = rows.filter(row => /\/temp\d+_input$/.test(row.path));
        const fans = rows.filter(row => /\/fan\d+_input$/.test(row.path));

        // Intel coretemp first, then AMD k10temp/zenpower.
        const packageTemp = temps.find(row => row.name === "coretemp" && /^Package id/.test(row.label))
            || temps.find(row => row.name === "k10temp" && /^Tctl$|^Tdie$/.test(row.label))
            || temps.find(row => row.name === "zenpower")
            || temps.find(row => row.name === "coretemp");

        const cores = temps.filter(row => row.name === "coretemp" && /^Core \d+$/.test(row.label)).sort((left, right) => coreNumber(left.label) - coreNumber(right.label)).map(row => ({
                    label: row.label,
                    path: row.path
                }));

        // Read every fan on one device and report the busiest. Labels are not
        // trustworthy: on the XPS dell_ddv calls fan1 "CPU Fan" and it sits at
        // 0 rpm while fan2 does the work. Prefer the device that reports a max
        // (dell_smm does) so the gauge has a scale.
        const fanDevice = (fans.find(row => row.max > 0) || fans[0] || {}).name;
        const deviceFans = fans.filter(row => row.name === fanDevice);

        sensorMap = {
            cpuTemp: packageTemp ? packageTemp.path : "",
            cores: cores,
            fans: deviceFans.map(row => ({
                        path: row.path,
                        label: row.label || row.path.replace(/^.*\/(fan\d+)_input$/, "$1")
                    }))
        };
        cpuTempCrit = packageTemp && packageTemp.crit > 0 ? packageTemp.crit / 1000 : 100;
        cpuTempSource = packageTemp ? packageTemp.name + (packageTemp.label ? " / " + packageTemp.label : "") : "";
        fanMaxRpm = deviceFans.reduce((max, row) => Math.max(max, row.max), 0);
        fanSource = fanDevice || "";
        discovered = true;
        refreshSensors();
    }

    function sensorFiles() {
        if (!sensorMap)
            return [];

        const files = [];

        if (sensorMap.cpuTemp)
            files.push(sensorMap.cpuTemp);
        for (let index = 0; index < sensorMap.cores.length; index++)
            files.push(sensorMap.cores[index].path);
        for (let index = 0; index < sensorMap.fans.length; index++)
            files.push(sensorMap.fans[index].path);

        return files;
    }

    function applySensorValues(text) {
        const values = {};
        const lines = String(text || "").split(/\r?\n/);

        for (let index = 0; index < lines.length; index++) {
            const separator = lines[index].lastIndexOf(":");
            if (separator > 0)
                values[lines[index].slice(0, separator)] = Number(lines[index].slice(separator + 1));
        }

        if (!sensorMap)
            return;

        cpuTemp = milli(values[sensorMap.cpuTemp]);
        coreTemps = sensorMap.cores.map(core => ({
                    label: core.label,
                    value: milli(values[core.path])
                }));

        let busiest = null;

        for (let index = 0; index < sensorMap.fans.length; index++) {
            const rpm = Number(values[sensorMap.fans[index].path]);
            if (Number.isFinite(rpm) && (!busiest || rpm > busiest.rpm))
                busiest = {
                    rpm,
                    label: sensorMap.fans[index].label
                };
        }

        fanRpm = busiest ? busiest.rpm : NaN;
        fanLabel = busiest ? busiest.label : "";
        if (busiest && busiest.rpm > fanPeakRpm)
            fanPeakRpm = busiest.rpm;
    }

    function applyCpuStat(text) {
        const sample = parseCpuSample(text);

        if (previousCpuSample) {
            const usage = cpuUsageBetween(previousCpuSample, sample);
            cpuUsage = usage.total;
            coreUsage = usage.cores;
        }

        previousCpuSample = sample;
    }

    // Same math as AegisService.parseCpuSample/cpuUsage; Aegis can move here later.
    function parseCpuSample(text) {
        const lines = String(text || "").split(/\r?\n/).filter(line => line.indexOf("cpu") === 0);
        let total = 0;
        let idle = 0;
        const cores = [];

        for (let index = 0; index < lines.length; index++) {
            const parts = lines[index].trim().split(/\s+/);
            const values = parts.slice(1).map(value => Number(value) || 0);
            const itemTotal = values.reduce((sum, value) => sum + value, 0);
            const itemIdle = (values[3] || 0) + (values[4] || 0);

            if (parts[0] === "cpu") {
                total = itemTotal;
                idle = itemIdle;
            } else {
                cores.push({
                    total: itemTotal,
                    idle: itemIdle
                });
            }
        }

        return {
            total,
            idle,
            cores
        };
    }

    function cpuUsageBetween(previous, next) {
        const cores = [];

        for (let index = 0; index < next.cores.length; index++) {
            const last = previous.cores[index];
            const current = next.cores[index];
            cores.push(last ? busyPercent(current.total - last.total, current.idle - last.idle) : 0);
        }

        return {
            total: busyPercent(next.total - previous.total, next.idle - previous.idle),
            cores
        };
    }

    function busyPercent(totalDelta, idleDelta) {
        return totalDelta > 0 ? Math.max(0, Math.min(100, (totalDelta - idleDelta) / totalDelta * 100)) : 0;
    }

    function applyDisks(text) {
        const lines = String(text || "").split(/\r?\n/).filter(line => line.trim().length > 0);
        const next = [];

        for (let index = 1; index < lines.length; index++) {
            const parts = lines[index].trim().split(/\s+/);
            if (parts.length < 6)
                continue;

            const total = Number(parts[1]) || 0;
            const used = Number(parts[2]) || 0;

            next.push({
                device: parts[0],
                mount: parts.slice(5).join(" "),
                totalBytes: total,
                usedBytes: used,
                freeBytes: Number(parts[3]) || 0,
                usedPercent: total > 0 ? used / total * 100 : 0
            });
        }

        disks = next;
    }

    function milli(value) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed / 1000 : NaN;
    }

    function coreNumber(label) {
        return Number(String(label).replace(/\D+/g, "")) || 0;
    }
}
