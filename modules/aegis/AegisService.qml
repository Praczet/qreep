import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.UPower

QtObject {
    id: rootAegisService

    required property QtObject theme
    property string mode: "summary"
    property string error: ""
    property var data: emptyData()
    property var activeConsumers: ({})
    property var previousCpuSample: null
    property bool active: false
    readonly property string archIconPath: Quickshell.env("HOME") + "/.local/share/icons/ADArtWork/scalable/apps/archlinux.svg"
    readonly property string hyprlandIconPath: Quickshell.env("HOME") + "/.local/share/icons/ADArtWork/scalable/apps/hyprland.svg"

    readonly property var networkDevices: Networking.devices.values
    readonly property var wifiDevice: firstNetworkDevice(DeviceType.Wifi)
    readonly property var wiredDevice: firstNetworkDevice(DeviceType.Wired)
    readonly property var wifiNetworks: wifiDevice ? wifiDevice.networks.values : []
    readonly property var activeWifi: firstConnectedWifi()
    readonly property var batteryDevice: UPower.displayDevice
    readonly property string refreshTime: formatTime(new Date(data.refreshedAt || Date.now()))

    signal refreshed

    readonly property Process systemRunner: Process {
        stdout: StdioCollector {
            id: systemStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: systemStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootAegisService.applySystemOutput(systemStdout.text, systemStderr.text, exitCode)
    }

    readonly property Process hyprlandRunner: Process {
        stdout: StdioCollector {
            id: hyprlandStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: hyprlandStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootAegisService.applyHyprlandOutput(hyprlandStdout.text, hyprlandStderr.text, exitCode)
    }

    readonly property Process cpuRunner: Process {
        stdout: StdioCollector {
            id: cpuStdout
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootAegisService.applyCpuOutput(cpuStdout.text, exitCode)
    }

    readonly property Timer refreshTimer: Timer {
        interval: rootAegisService.theme.modules.aegis.refreshInterval
        repeat: true
        running: rootAegisService.active
        onTriggered: rootAegisService.refresh()
    }

    readonly property Timer cpuTimer: Timer {
        interval: rootAegisService.theme.modules.aegis.cpuRefreshInterval
        repeat: true
        running: rootAegisService.active
        onTriggered: rootAegisService.refreshCpu()
    }

    onNetworkDevicesChanged: updateLiveSections()
    onWifiNetworksChanged: updateLiveSections()
    onActiveWifiChanged: updateLiveSections()
    onWiredDeviceChanged: updateLiveSections()
    onBatteryDeviceChanged: updateLiveSections()

    function setMode(nextMode) {
        const value = String(nextMode || "");

        if (value === "minimal" || value === "summary" || value === "full")
            mode = value;
    }

    function setActive(id, value, opts) {
        const key = String(id || "default");
        const nextConsumers = Object.assign({}, activeConsumers);
        nextConsumers[key] = {
            active: Boolean(value),
            refreshOnShow: !opts || opts.refreshOnShow !== false
        };
        activeConsumers = nextConsumers;

        const wasActive = active;
        active = Object.keys(activeConsumers).some(name => activeConsumers[name].active);

        if (active && (!wasActive || nextConsumers[key].refreshOnShow))
            refresh();
    }

    function refresh() {
        runCommand(systemRunner, systemCommand());
        runCommand(hyprlandRunner, ["bash", "-lc", "printf '__VERSION__\\n'; hyprctl -j version 2>/dev/null; printf '\\n__MONITORS__\\n'; hyprctl -j monitors 2>/dev/null"]);
        refreshCpu();
    }

    function refreshCpu() {
        runCommand(cpuRunner, ["bash", "-lc", "printf '__CPUSTAT__\\n'; grep '^cpu' /proc/stat; printf '__FREQ__\\n'; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || true; printf '__TEMP__\\n'; for f in /sys/class/thermal/thermal_zone*/temp; do [ -r \"$f\" ] && cat \"$f\" && break; done"]);
    }

    function runCommand(runner, command) {
        if (runner.running)
            runner.running = false;

        runner.command = command;
        runner.running = true;
    }

    function systemCommand() {
        return ["bash", "-lc", [
            "printf '__HOST__\\n'; hostname 2>/dev/null || true",
            "printf '__KERNEL__\\n'; cat /proc/sys/kernel/osrelease 2>/dev/null || true",
            "printf '__UPTIME__\\n'; cut -d' ' -f1 /proc/uptime 2>/dev/null || true",
            "printf '__OS__\\n'; cat /etc/os-release 2>/dev/null || true",
            "printf '__MEM__\\n'; cat /proc/meminfo 2>/dev/null || true",
            "printf '__CPUINFO__\\n'; grep -m1 '^model name' /proc/cpuinfo 2>/dev/null || true; grep -c '^processor' /proc/cpuinfo 2>/dev/null || true; cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || true",
            "printf '__HOSTMODEL__\\n'; cat /sys/class/dmi/id/product_name 2>/dev/null || true; cat /sys/class/dmi/id/product_version 2>/dev/null || true",
            "printf '__GPU__\\n'; lspci -mm 2>/dev/null | grep -Ei 'VGA compatible controller|3D controller' | head -n1 || true",
            "printf '__DF__\\n'; df -B1 -T -P -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null || true",
            "printf '__LSBLK__\\n'; lsblk -b -J -o NAME,MODEL,SIZE,TYPE,MOUNTPOINT,FSTYPE 2>/dev/null || true",
            "printf '__NETDEV__\\n'; cat /proc/net/dev 2>/dev/null || true",
            "printf '__NETWORK__\\n'; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true",
            "printf '__NETWORK_SHOW__\\n'; nmcli -t -f GENERAL.DEVICE,GENERAL.TYPE,GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show 2>/dev/null || true",
            "printf '__THEME__\\n'; grep -h '^gtk-theme-name=' \"$HOME/.config/gtk-3.0/settings.ini\" \"$HOME/.config/gtk-4.0/settings.ini\" 2>/dev/null | head -n1 || true; grep -h '^gtk-icon-theme-name=' \"$HOME/.config/gtk-3.0/settings.ini\" \"$HOME/.config/gtk-4.0/settings.ini\" 2>/dev/null | head -n1 || true",
            "printf '__PACKAGES__\\n'; { command -v pacman >/dev/null && printf 'pacman=%s\\n' \"$(pacman -Qq 2>/dev/null | wc -l)\"; command -v flatpak >/dev/null && printf 'flatpak=%s\\n' \"$(flatpak list --app --columns=application 2>/dev/null | wc -l)\"; command -v snap >/dev/null && printf 'snap=%s\\n' \"$(snap list 2>/dev/null | tail -n +2 | wc -l)\"; } || true"
        ].join("; ")];
    }

    function emptyData() {
        return {
            os: ({}),
            host: ({}),
            kernel: ({}),
            uptime: ({}),
            hardware: ({}),
            system: ({}),
            memory: ({}),
            disks: [],
            physicalDisks: [],
            network: ({ interfaces: [], info: ({}) }),
            power: ({ batteries: [] }),
            hyprland: ({}),
            cpu: ({ usage: 0, cores: [] }),
            refreshedAt: Date.now()
        };
    }

    function applySystemOutput(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0) {
            error = String(stderrText || "Aegis system probe failed").trim();
            return;
        }

        const sections = splitSections(stdoutText);
        const next = Object.assign({}, data);

        next.os = parseOsRelease(sections.OS || "");
        next.host = ({ hostname: firstLine(sections.HOST) });
        next.kernel = ({ release: firstLine(sections.KERNEL) });
        next.uptime = ({ seconds: numberValue(firstLine(sections.UPTIME), 0) });
        next.hardware = Object.assign({}, next.hardware, parseHardware(sections.CPUINFO || "", sections.GPU || "", sections.HOSTMODEL || ""));
        next.system = ({
            packages: parsePackages(sections.PACKAGES || ""),
            theme: parseTheme(sections.THEME || "").theme,
            icons: parseTheme(sections.THEME || "").icons
        });
        next.memory = parseMemory(sections.MEM || "");
        next.disks = parseDisks(sections.DF || "");
        next.physicalDisks = parsePhysicalDisks(sections.LSBLK || "", next.disks);
        next.network = buildNetworkInfo(sections.NETDEV || "", sections.NETWORK || "", sections.NETWORK_SHOW || "");
        next.power = buildPowerInfo();
        next.refreshedAt = Date.now();

        data = next;
        error = "";
        refreshed();
    }

    function applyHyprlandOutput(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0)
            return;

        const sections = splitSections(stdoutText);
        const version = parseJson(sections.VERSION || "", ({}));
        const monitorsRaw = parseJson(sections.MONITORS || "", []);
        const monitors = Array.isArray(monitorsRaw) ? monitorsRaw.map(monitor => ({
            name: stringValue(monitor.name, "monitor"),
            description: stringValue(monitor.description, ""),
            model: stringValue(monitor.model, ""),
            width: numberValue(monitor.width, 0),
            height: numberValue(monitor.height, 0),
            refresh: numberValue(monitor.refreshRate, 0),
            scale: numberValue(monitor.scale, 1),
            activeWorkspace: monitor.activeWorkspace ? stringValue(monitor.activeWorkspace.name, "") : "",
            focused: Boolean(monitor.focused)
        })) : [];

        const next = Object.assign({}, data);
        next.hyprland = ({
            version: stringValue(version.version, stringValue(version.tag, "")),
            branch: stringValue(version.branch, ""),
            commit: stringValue(version.commit, ""),
            monitors
        });
        next.refreshedAt = Date.now();
        data = next;
    }

    function applyCpuOutput(stdoutText, exitCode) {
        if (exitCode !== 0)
            return;

        const sections = splitSections(stdoutText);
        const sample = parseCpuSample(sections.CPUSTAT || "");
        const usage = cpuUsage(previousCpuSample, sample);
        previousCpuSample = sample;

        const next = Object.assign({}, data);
        next.cpu = ({
            usage: usage.total,
            cores: usage.cores,
            speedGhz: cpuFreqGhz(firstLine(sections.FREQ)),
            tempC: cpuTempC(firstLine(sections.TEMP))
        });
        next.hardware = Object.assign({}, next.hardware, {
            cpuSpeed: next.cpu.speedGhz,
            cpuTemp: next.cpu.tempC
        });
        next.refreshedAt = Date.now();
        data = next;
    }

    function updateLiveSections() {
        const next = Object.assign({}, data);
        next.network = buildNetworkInfo("", "", "");
        next.power = buildPowerInfo();
        data = next;
    }

    function splitSections(text) {
        const result = {};
        const lines = String(text || "").split(/\r?\n/);
        let current = "";

        for (let index = 0; index < lines.length; index++) {
            const line = lines[index];
            const match = line.match(/^__([A-Z0-9_]+)__$/);

            if (match) {
                current = match[1];
                result[current] = "";
                continue;
            }

            if (current.length > 0)
                result[current] += line + "\n";
        }

        return result;
    }

    function parseOsRelease(text) {
        const values = {};
        const lines = String(text || "").split(/\r?\n/);

        for (let index = 0; index < lines.length; index++) {
            const line = lines[index].trim();
            const separator = line.indexOf("=");

            if (separator < 0)
                continue;

            const key = line.slice(0, separator);
            let value = line.slice(separator + 1);
            if (value.charAt(0) === "\"" && value.charAt(value.length - 1) === "\"")
                value = value.slice(1, -1);
            values[key] = value;
        }

        return {
            id: values.ID || "",
            name: values.NAME || "",
            prettyName: values.PRETTY_NAME || values.NAME || values.ID || "Unknown OS",
            version: values.VERSION_ID || values.VERSION || ""
        };
    }

    function parseHardware(cpuText, gpuText, hostText) {
        const cpuLines = String(cpuText || "").split(/\r?\n/).filter(line => line.length > 0);
        const modelLine = cpuLines.length > 0 ? cpuLines[0] : "";
        const model = modelLine.indexOf(":") >= 0 ? modelLine.split(":").slice(1).join(":").trim() : modelLine.trim();
        const cores = numberValue(cpuLines.length > 1 ? cpuLines[1] : 0, 0);
        const maxFreq = numberValue(cpuLines.length > 2 ? cpuLines[2] : 0, 0);
        const hostLines = String(hostText || "").split(/\r?\n/).filter(line => line.trim().length > 0);
        const host = hostLines.join(" ").trim();
        const gpu = parseGpu(gpuText);
        const ghz = maxFreq > 0 ? " @ " + (maxFreq / 1000000).toFixed(2) + " GHz" : "";

        return {
            cpu: model.length > 0 ? model + (cores > 0 ? " (" + cores + ")" : "") + ghz : "--",
            gpu,
            host: host.length > 0 ? host : "--"
        };
    }

    function parseGpu(text) {
        const line = firstLine(text);
        const parts = line.split("\"").filter(value => value.length > 0);

        if (parts.length >= 6)
            return parts[5];

        return line.length > 0 ? line : "--";
    }

    function parseMemory(text) {
        const values = {};
        const lines = String(text || "").split(/\r?\n/);

        for (let index = 0; index < lines.length; index++) {
            const line = lines[index];
            const parts = line.split(":");
            if (parts.length < 2)
                continue;
            values[parts[0].trim()] = numberValue(parts[1].trim().split(/\s+/)[0], 0) * 1024;
        }

        const total = values.MemTotal || 0;
        const available = values.MemAvailable || 0;
        const used = Math.max(0, total - available);
        const swapTotal = values.SwapTotal || 0;
        const swapFree = values.SwapFree || 0;
        const swapUsed = Math.max(0, swapTotal - swapFree);

        return {
            totalBytes: total,
            availableBytes: available,
            usedBytes: used,
            usedPercent: total > 0 ? used / total * 100 : 0,
            swapTotalBytes: swapTotal,
            swapFreeBytes: swapFree,
            swapUsedBytes: swapUsed,
            swapUsedPercent: swapTotal > 0 ? swapUsed / swapTotal * 100 : 0
        };
    }

    function parseDisks(text) {
        const lines = String(text || "").split(/\r?\n/).filter(line => line.trim().length > 0);
        const disks = [];

        for (let index = 1; index < lines.length; index++) {
            const parts = lines[index].trim().split(/\s+/);
            if (parts.length < 7)
                continue;

            const total = numberValue(parts[2], 0);
            const used = numberValue(parts[3], 0);
            const free = numberValue(parts[4], 0);
            const mount = parts.slice(6).join(" ");

            if ((mount.indexOf("/run") === 0 && mount.indexOf("/run/media/") !== 0) || mount.indexOf("/boot") === 0)
                continue;

            disks.push({
                device: parts[0],
                fsType: parts[1],
                totalBytes: total,
                usedBytes: used,
                freeBytes: free,
                usedPercent: total > 0 ? used / total * 100 : 0,
                mount
            });
        }

        disks.sort((left, right) => {
            if (left.mount === "/")
                return -1;
            if (right.mount === "/")
                return 1;
            if (left.mount === "/home")
                return -1;
            if (right.mount === "/home")
                return 1;
            return left.mount.localeCompare(right.mount);
        });
        return disks;
    }

    function parsePhysicalDisks(text, mountDisks) {
        const parsed = parseJson(text, ({}));
        const devices = parsed && Array.isArray(parsed.blockdevices) ? parsed.blockdevices : [];
        const result = [];

        for (let index = 0; index < devices.length; index++) {
            const item = devices[index];
            if (!item || item.type !== "disk")
                continue;
            const used = usedBytesForPhysicalDisk(item, mountDisks || []);
            const size = numberValue(item.size, 0);
            result.push({
                name: stringValue(item.name, "disk"),
                model: stringValue(item.model, ""),
                sizeBytes: size,
                usedBytes: used,
                freeBytes: size > 0 ? Math.max(0, size - used) : 0,
                usedPercent: size > 0 ? used / size * 100 : 0
            });
        }

        return result;
    }

    function usedBytesForPhysicalDisk(device, mountDisks) {
        const names = ["/dev/" + stringValue(device.name, "")];
        const children = Array.isArray(device.children) ? device.children : [];
        for (let index = 0; index < children.length; index++)
            names.push("/dev/" + stringValue(children[index].name, ""));

        let used = 0;
        for (let diskIndex = 0; diskIndex < mountDisks.length; diskIndex++) {
            const disk = mountDisks[diskIndex];
            if (names.indexOf(disk.device) >= 0)
                used += numberValue(disk.usedBytes, 0);
        }
        return used;
    }

    function parsePackages(text) {
        const lines = String(text || "").split(/\r?\n/).filter(line => line.trim().length > 0);
        const parts = [];

        for (let index = 0; index < lines.length; index++) {
            const pair = lines[index].split("=");
            if (pair.length === 2)
                parts.push(pair[1].trim() + " (" + pair[0].trim() + ")");
        }

        return parts.length > 0 ? parts.join(", ") : "--";
    }

    function parseTheme(text) {
        const lines = String(text || "").split(/\r?\n/);
        let themeName = "";
        let iconName = "";

        for (let index = 0; index < lines.length; index++) {
            const line = lines[index].trim();
            if (line.indexOf("gtk-theme-name=") === 0)
                themeName = line.slice("gtk-theme-name=".length);
            else if (line.indexOf("gtk-icon-theme-name=") === 0)
                iconName = line.slice("gtk-icon-theme-name=".length);
        }

        return {
            theme: themeName.length > 0 ? themeName + " [GTK]" : "--",
            icons: iconName.length > 0 ? iconName + " [GTK]" : "--"
        };
    }

    function parseCpuSample(text) {
        const lines = String(text || "").split(/\r?\n/).filter(line => line.indexOf("cpu") === 0);
        let total = 0;
        let idle = 0;
        const cores = [];

        for (let index = 0; index < lines.length; index++) {
            const parts = lines[index].trim().split(/\s+/);
            const values = parts.slice(1).map(value => numberValue(value, 0));
            const itemTotal = values.reduce((sum, value) => sum + value, 0);
            const itemIdle = (values[3] || 0) + (values[4] || 0);

            if (parts[0] === "cpu") {
                total = itemTotal;
                idle = itemIdle;
            } else {
                cores.push({ total: itemTotal, idle: itemIdle });
            }
        }

        return { total, idle, cores };
    }

    function cpuUsage(previous, next) {
        if (!previous || !next)
            return { total: 0, cores: [] };

        const totalDelta = next.total - previous.total;
        const idleDelta = next.idle - previous.idle;
        const totalUsage = totalDelta > 0 ? Math.max(0, Math.min(100, (totalDelta - idleDelta) / totalDelta * 100)) : 0;
        const cores = [];

        for (let index = 0; index < next.cores.length; index++) {
            const last = previous.cores[index];
            const current = next.cores[index];
            if (!last || !current) {
                cores.push(0);
                continue;
            }
            const coreTotal = current.total - last.total;
            const coreIdle = current.idle - last.idle;
            cores.push(coreTotal > 0 ? Math.max(0, Math.min(100, (coreTotal - coreIdle) / coreTotal * 100)) : 0);
        }

        return { total: totalUsage, cores };
    }

    function buildNetworkInfo(netDevText, statusText, showText) {
        const netBytes = parseNetDev(netDevText);
        const nmStatus = parseNmcliStatus(statusText);
        const nmDetails = parseNmcliDetails(showText);
        const interfaces = [];
        let primary = null;

        if (wiredDevice) {
            const name = stringValue(wiredDevice.name, "wired");
            const details = nmDetails[name] || ({});
            const status = nmStatus[name] || ({});
            const item = {
                name,
                type: "ethernet",
                state: wiredDevice.connected || wiredDevice.hasLink ? "up" : "down",
                ssid: stringValue(status.connection, wiredDevice.network ? stringValue(wiredDevice.network.name, "Ethernet") : "Ethernet"),
                primary: !activeWifi && (wiredDevice.connected || wiredDevice.hasLink),
                rxBytes: netBytes[name] ? netBytes[name].rxBytes : 0,
                txBytes: netBytes[name] ? netBytes[name].txBytes : 0,
                ip: details.ip || "--",
                gateway: details.gateway || "--",
                dns: details.dns || "--"
            };
            interfaces.push(item);
            if (item.primary)
                primary = item;
        }

        if (wifiDevice) {
            const name = stringValue(wifiDevice.name, "wifi");
            const details = nmDetails[name] || ({});
            const status = nmStatus[name] || ({});
            const item = {
                name,
                type: "wifi",
                state: activeWifi ? "up" : "down",
                ssid: activeWifi ? stringValue(activeWifi.name, "") : stringValue(status.connection, ""),
                primary: Boolean(activeWifi),
                rxBytes: netBytes[name] ? netBytes[name].rxBytes : 0,
                txBytes: netBytes[name] ? netBytes[name].txBytes : 0,
                ip: details.ip || "--",
                gateway: details.gateway || "--",
                dns: details.dns || "--"
            };
            interfaces.push(item);
            if (item.primary)
                primary = item;
        }

        if (!primary && interfaces.length > 0)
            primary = interfaces.find(item => item.state === "up") || interfaces[0];

        return {
            interfaces,
            info: ({
                hostname: stringValue(data.host.hostname, ""),
                iface: primary ? primary.name : "--",
                ssid: primary ? primary.ssid || "--" : "--",
                ip: primary ? primary.ip || "--" : "--",
                gateway: primary ? primary.gateway || "--" : "--",
                dns: primary ? primary.dns || "--" : "--"
            })
        };
    }

    function parseNetDev(text) {
        const result = {};
        const lines = String(text || "").split(/\r?\n/);

        for (let index = 2; index < lines.length; index++) {
            const line = lines[index];
            const separator = line.indexOf(":");
            if (separator < 0)
                continue;
            const name = line.slice(0, separator).trim();
            const values = line.slice(separator + 1).trim().split(/\s+/);
            result[name] = {
                rxBytes: numberValue(values[0], 0),
                txBytes: numberValue(values[8], 0)
            };
        }

        return result;
    }

    function parseNmcliStatus(text) {
        const result = {};
        const lines = String(text || "").split(/\r?\n/);

        for (let index = 0; index < lines.length; index++) {
            const parts = lines[index].split(":");
            if (parts.length < 4)
                continue;
            result[parts[0]] = {
                type: parts[1],
                state: parts[2],
                connection: parts.slice(3).join(":")
            };
        }

        return result;
    }

    function parseNmcliDetails(text) {
        const result = {};
        const lines = String(text || "").split(/\r?\n/);
        let current = "";

        for (let index = 0; index < lines.length; index++) {
            const line = lines[index];
            const separator = line.indexOf(":");
            if (separator < 0)
                continue;
            const key = line.slice(0, separator);
            const value = line.slice(separator + 1);

            if (key === "GENERAL.DEVICE") {
                current = value;
                if (!result[current])
                    result[current] = ({ dnsValues: [] });
            } else if (current.length > 0) {
                if (key === "GENERAL.CONNECTION")
                    result[current].connection = value;
                else if (key.indexOf("IP4.ADDRESS") === 0)
                    result[current].ip = value.split("/")[0] || value;
                else if (key === "IP4.GATEWAY")
                    result[current].gateway = value || "--";
                else if (key.indexOf("IP4.DNS") === 0 && value.length > 0)
                    result[current].dnsValues.push(value);
            }
        }

        const keys = Object.keys(result);
        for (let index = 0; index < keys.length; index++) {
            const item = result[keys[index]];
            item.dns = item.dnsValues && item.dnsValues.length > 0 ? item.dnsValues.join(", ") : "--";
        }

        return result;
    }

    function buildPowerInfo() {
        if (!batteryDevice || !batteryDevice.ready)
            return { batteries: [] };

        const percent = normalizedPercent(batteryDevice.percentage);
        const state = UPowerDeviceState.toString(batteryDevice.state);
        const time = UPower.onBattery ? batteryDevice.timeToEmpty : batteryDevice.timeToFull;

        return {
            batteries: [{
                name: "Battery",
                status: state,
                capacityPercent: percent,
                timeRemainingSeconds: numberValue(time, 0)
            }]
        };
    }

    function firstNetworkDevice(type) {
        for (let index = 0; index < networkDevices.length; index++) {
            const device = networkDevices[index];
            if (device.type === type)
                return device;
        }
        return null;
    }

    function firstConnectedWifi() {
        for (let index = 0; index < wifiNetworks.length; index++) {
            const network = wifiNetworks[index];
            if (network.connected)
                return network;
        }
        return null;
    }

    function sections(modeValue, sectionFilter) {
        const all = buildSections(data, String(modeValue || mode), sectionFilter || []);
        return all;
    }

    function buildSections(model, modeValue, sectionFilter) {
        const filter = Array.isArray(sectionFilter) ? sectionFilter : [];
        const sections = [
            {
                id: "system",
                title: "System",
                from: "top-left",
                rows: [
                    infoRow("OS", model.os.prettyName || "--", "minimal"),
                    infoRow("Host", model.host.hostname || "--", "minimal"),
                    infoRow("Kernel", model.kernel.release || "--", "summary"),
                    infoRow("Uptime", formatUptime(model.uptime.seconds), "minimal"),
                    infoRow("Packages", model.system.packages || "--", "summary"),
                    infoRow("Theme", model.system.theme || "--", "full"),
                    infoRow("Icons", model.system.icons || "--", "full")
                ]
            },
            {
                id: "hardware",
                title: "Hardware",
                from: "top-right",
                rows: [
                    infoRow("CPU", model.hardware.cpu || "--", "summary"),
                    infoRow("GPU", model.hardware.gpu || "--", "summary"),
                    infoRow("Host", model.hardware.host || "--", "summary")
                ]
            },
            {
                id: "memory",
                title: "Memory",
                from: "right",
                rows: [
                    infoRow("Usage", formatBytes(model.memory.usedBytes) + " / " + formatBytes(model.memory.totalBytes) + " (" + formatPercent(model.memory.usedPercent) + ")", "summary"),
                    infoRow("Available", formatBytes(model.memory.availableBytes), "full"),
                    infoRow("Swap", formatBytes(model.memory.swapUsedBytes) + " / " + formatBytes(model.memory.swapTotalBytes) + " (" + formatPercent(model.memory.swapUsedPercent) + ")", "full")
                ]
            },
            {
                id: "storage",
                title: "Storage",
                from: "bottom-right",
                rows: storageRows(model.disks)
            },
            {
                id: "network-info",
                title: "Network",
                from: "bottom-left",
                rows: networkRows(model.network)
            },
            {
                id: "power",
                title: "Power",
                from: "left",
                rows: powerRows(model.power)
            },
            {
                id: "hyprland",
                title: "Hyprland",
                from: "top",
                rows: hyprlandRows(model.hyprland)
            },
            {
                id: "status",
                title: "Status",
                from: "bottom",
                rows: [
                    infoRow("Updated", refreshTime, "minimal")
                ]
            }
        ];

        return sections.filter(section => (filter.length === 0 || filter.indexOf(section.id) >= 0))
            .map(section => Object.assign({}, section, { rows: section.rows.filter(row => rowAllowed(row, modeValue)) }))
            .filter(section => section.rows.length > 0);
    }

    function storageRows(disks) {
        if (!disks || disks.length === 0)
            return [infoRow("Disks", "--", "summary")];

        const rows = [];
        const root = disks.find(disk => disk.mount === "/") || disks[0];
        rows.push(infoRow("Root", formatBytes(root.usedBytes) + " / " + formatBytes(root.totalBytes) + " (" + formatPercent(root.usedPercent) + ")", "summary"));
        for (let index = 0; index < disks.length; index++) {
            const disk = disks[index];
            rows.push(infoRow(disk.mount, formatBytes(disk.usedBytes) + " / " + formatBytes(disk.totalBytes) + " (" + formatPercent(disk.usedPercent) + ")", "full"));
        }
        return rows;
    }

    function networkRows(network) {
        const interfaces = network && Array.isArray(network.interfaces) ? network.interfaces : [];
        if (interfaces.length === 0)
            return [infoRow("Interfaces", "--", "summary")];

        const rows = [];
        for (let index = 0; index < interfaces.length; index++) {
            const iface = interfaces[index];
            rows.push(infoRow(iface.name + (iface.primary ? " (primary)" : ""), iface.type + " - " + iface.state + (iface.ssid ? " - " + iface.ssid : ""), "summary"));
            rows.push(infoRow(iface.name + " traffic", formatBytes(iface.rxBytes) + " down / " + formatBytes(iface.txBytes) + " up", "full"));
        }
        rows.push(infoRow("IP", network.info ? network.info.ip || "--" : "--", "full"));
        rows.push(infoRow("Gateway", network.info ? network.info.gateway || "--" : "--", "full"));
        rows.push(infoRow("DNS", network.info ? network.info.dns || "--" : "--", "full"));
        return rows;
    }

    function powerRows(power) {
        const batteries = power && Array.isArray(power.batteries) ? power.batteries : [];
        if (batteries.length === 0)
            return [infoRow("Battery", "--", "summary")];

        const rows = [];
        for (let index = 0; index < batteries.length; index++) {
            const battery = batteries[index];
            rows.push(infoRow(battery.name, formatPercent(battery.capacityPercent) + " - " + battery.status, "summary"));
            if (battery.timeRemainingSeconds > 0)
                rows.push(infoRow("Time", formatDuration(battery.timeRemainingSeconds), "full"));
        }
        return rows;
    }

    function hyprlandRows(hyprland) {
        const monitors = hyprland && Array.isArray(hyprland.monitors) ? hyprland.monitors : [];
        const rows = [
            infoRow("Version", hyprland.version || "--", "summary"),
            infoRow("Monitors", String(monitors.length), "summary"),
            infoRow("Branch", hyprland.branch || "--", "full"),
            infoRow("Commit", hyprland.commit || "--", "full")
        ];

        for (let index = 0; index < monitors.length; index++) {
            const monitor = monitors[index];
            rows.push(infoRow(monitor.name, monitor.width + "x" + monitor.height + " - " + Math.round(monitor.refresh) + "Hz - " + monitor.scale + "x", "full"));
        }
        return rows;
    }

    function infoRow(label, value, minMode) {
        return { label, value, minMode };
    }

    function copyText(modeValue, sectionFilter) {
        const built = sections(modeValue || "full", sectionFilter || []);
        const lines = [];

        for (let sectionIndex = 0; sectionIndex < built.length; sectionIndex++) {
            const section = built[sectionIndex];
            lines.push(section.title);
            for (let rowIndex = 0; rowIndex < section.rows.length; rowIndex++) {
                const row = section.rows[rowIndex];
                lines.push("  " + row.label + ": " + row.value);
            }
            lines.push("");
        }

        return lines.join("\n").trim();
    }

    function copyJson() {
        return JSON.stringify(data, null, 2);
    }

    function copyInfo(format) {
        Quickshell.clipboardText = String(format || "text") === "json" ? copyJson() : copyText("full", []);
    }

    function osIconSource() {
        const id = String(data.os.id || data.os.name || "").toLowerCase();
        if (id.indexOf("arch") >= 0)
            return "file://" + archIconPath;
        return "";
    }

    function hyprlandIconSource() {
        return "file://" + hyprlandIconPath;
    }

    function rowAllowed(row, modeValue) {
        return modeRank(modeValue) >= modeRank(row.minMode);
    }

    function modeRank(value) {
        if (value === "full")
            return 2;
        if (value === "summary")
            return 1;
        return 0;
    }

    function normalizedPercent(value) {
        const parsed = Number(value);
        if (!Number.isFinite(parsed))
            return 0;
        return Math.max(0, Math.min(100, Math.round(parsed <= 1 ? parsed * 100 : parsed)));
    }

    function cpuFreqGhz(value) {
        const parsed = numberValue(value, 0);
        return parsed > 0 ? parsed / 1000000 : 0;
    }

    function cpuTempC(value) {
        const parsed = numberValue(value, 0);
        return parsed > 0 ? parsed / 1000 : 0;
    }

    function parseJson(text, fallback) {
        try {
            return JSON.parse(String(text || "").trim());
        } catch (error) {
            return fallback;
        }
    }

    function firstLine(text) {
        return String(text || "").split(/\r?\n/).find(line => line.trim().length > 0) || "";
    }

    function stringValue(value, fallback) {
        return typeof value === "string" && value.length > 0 ? value : fallback;
    }

    function numberValue(value, fallback) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function formatBytes(bytes) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = Number(bytes);
        let index = 0;

        if (!Number.isFinite(value) || value <= 0)
            return "--";

        while (value >= 1024 && index < units.length - 1) {
            value /= 1024;
            index += 1;
        }

        return value.toFixed(value >= 10 || index === 0 ? 0 : 1) + " " + units[index];
    }

    function formatPercent(value) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? Math.round(parsed) + "%" : "--";
    }

    function formatUptime(seconds) {
        const total = Math.max(0, Math.floor(numberValue(seconds, 0)));
        const days = Math.floor(total / 86400);
        const hours = Math.floor((total % 86400) / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        return (days > 0 ? days + "d " : "") + hours + "h " + minutes + "m";
    }

    function formatDuration(seconds) {
        const total = Math.max(0, Math.floor(numberValue(seconds, 0)));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }

    function formatTime(date) {
        return Qt.formatTime(date, "HH:mm:ss");
    }
}
