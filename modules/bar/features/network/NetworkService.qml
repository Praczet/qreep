import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth

QtObject {
    id: rootNetworkService

    readonly property var networkDevices: Networking.devices.values
    readonly property var bluetoothDevices: Bluetooth.devices.values
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var wifiDevice: firstDevice(DeviceType.Wifi)
    readonly property var wiredDevice: firstDevice(DeviceType.Wired)
    readonly property var wifiNetworks: wifiDevice ? wifiDevice.networks.values : []
    readonly property var activeWifi: firstConnectedNetwork(wifiNetworks)
    readonly property var connectedBluetoothDevices: connectedDevices(bluetoothDevices)

    readonly property bool wiredAvailable: wiredDevice !== null
    readonly property bool wiredActive: wiredAvailable && (wiredDevice.connected || wiredDevice.state === ConnectionState.Connected || wiredDevice.hasLink)
    readonly property string wiredStateText: wiredState()
    readonly property string wiredIcon: wiredActive ? "󰛳" : "󰲛"
    readonly property string wiredInfo: wiredAvailable ? wiredStateText : "no wired device"

    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiScanning: wifiDevice !== null && wifiDevice.scannerEnabled
    readonly property bool wifiConnected: activeWifi !== null
    readonly property int wifiSignal: wifiConnected ? normalizedPercent(activeWifi.signalStrength) : 0
    readonly property string wifiStateText: wifiState()
    readonly property string wifiIcon: wifiGlyph()
    readonly property string wifiInfo: wifiInfoText()

    readonly property bool bluetoothAvailable: bluetoothAdapter !== null
    readonly property bool bluetoothEnabled: bluetoothAvailable && bluetoothAdapter.enabled
    readonly property bool bluetoothDiscovering: bluetoothAvailable && bluetoothAdapter.discovering
    readonly property bool bluetoothConnected: connectedBluetoothDevices.length > 0
    readonly property string bluetoothStateText: bluetoothState()
    readonly property string bluetoothIcon: bluetoothGlyph()
    readonly property string bluetoothInfo: bluetoothInfoText()
    property string wiredIp: "--"
    property string wiredGateway: "--"
    property string wiredDns: "--"
    property string wiredDetailsStatus: "Not loaded"
    property string lastCopiedText: ""

    readonly property string tooltipTitle: "Network"
    readonly property string tooltipContent: [
        "Wired: " + wiredInfo,
        "Wi-Fi: " + wifiInfo,
        "Bluetooth: " + bluetoothInfo
    ].join("\n")

    readonly property Process wiredDetailsRunner: Process {
        stdout: StdioCollector {
            id: wiredDetailsStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: wiredDetailsStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootNetworkService.applyWiredDetails(wiredDetailsStdout.text, wiredDetailsStderr.text, exitCode)
    }

    readonly property Timer scanStopTimer: Timer {
        interval: 10000
        repeat: false
        onTriggered: {
            if (rootNetworkService.wifiDevice)
                rootNetworkService.wifiDevice.scannerEnabled = false;
        }
    }

    readonly property Timer wiredReconnectTimer: Timer {
        interval: 900
        repeat: false
        onTriggered: {
            if (rootNetworkService.wiredDevice && rootNetworkService.wiredDevice.network)
                rootNetworkService.wiredDevice.network.connect();
        }
    }

    function firstDevice(type) {
        for (let index = 0; index < networkDevices.length; index++) {
            const device = networkDevices[index];

            if (device.type === type)
                return device;
        }

        return null;
    }

    function firstConnectedNetwork(networks) {
        for (let index = 0; index < networks.length; index++) {
            const network = networks[index];

            if (network.connected)
                return network;
        }

        return null;
    }

    function connectedDevices(devices) {
        const result = [];

        for (let index = 0; index < devices.length; index++) {
            const device = devices[index];

            if (device.connected)
                result.push(device);
        }

        return result;
    }

    function knownWifiNetworks() {
        const result = [];

        for (let index = 0; index < wifiNetworks.length; index++) {
            const network = wifiNetworks[index];

            if (network.known)
                result.push(network);
        }

        return result;
    }

    function availableWifiNetworks() {
        const result = [];

        for (let index = 0; index < wifiNetworks.length; index++) {
            const network = wifiNetworks[index];

            if (!network.connected)
                result.push(network);
        }

        return result;
    }

    function pairedBluetoothDevices() {
        const result = [];

        for (let index = 0; index < bluetoothDevices.length; index++) {
            const device = bluetoothDevices[index];

            if (device.paired || device.bonded || device.connected)
                result.push(device);
        }

        return result;
    }

    function nearbyBluetoothDevices() {
        const result = [];

        for (let index = 0; index < bluetoothDevices.length; index++) {
            const device = bluetoothDevices[index];

            if (!device.paired && !device.bonded && !device.connected)
                result.push(device);
        }

        return result;
    }

    function refreshWiredDetails() {
        if (!wiredAvailable || !wiredDevice.name) {
            wiredIp = "--";
            wiredGateway = "--";
            wiredDns = "--";
            wiredDetailsStatus = "No wired device";
            return;
        }

        wiredDetailsStatus = "Loading...";
        wiredDetailsRunner.running = false;
        wiredDetailsRunner.command = ["nmcli", "-t", "-f", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS", "device", "show", wiredDevice.name];
        wiredDetailsRunner.running = true;
    }

    function restartWired() {
        if (!wiredDevice)
            return;

        wiredDevice.disconnect();
        wiredReconnectTimer.restart();
    }

    function applyWiredDetails(stdoutText, stderrText, exitCode) {
        if (exitCode !== 0) {
            wiredIp = "--";
            wiredGateway = "--";
            wiredDns = "--";
            wiredDetailsStatus = String(stderrText || "Could not load wired details").trim();
            return;
        }

        const lines = String(stdoutText || "").split(/\r?\n/);
        const dns = [];

        wiredIp = "--";
        wiredGateway = "--";

        for (let index = 0; index < lines.length; index++) {
            const line = lines[index].trim();
            const separator = line.indexOf(":");

            if (separator < 0)
                continue;

            const key = line.slice(0, separator);
            const value = line.slice(separator + 1);

            if (key === "IP4.ADDRESS[1]")
                wiredIp = value.split("/")[0] || value;
            else if (key === "IP4.GATEWAY")
                wiredGateway = value || "--";
            else if (key.indexOf("IP4.DNS") === 0 && value.length > 0)
                dns.push(value);
        }

        wiredDns = dns.length > 0 ? dns.join(", ") : "--";
        wiredDetailsStatus = "Loaded";
    }

    function toggleWifiEnabled() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function scanWifi() {
        if (!wifiDevice)
            return;

        wifiDevice.scannerEnabled = true;
        scanStopTimer.restart();
    }

    function connectWifi(network, password) {
        if (!network)
            return;

        if (password && password.length > 0)
            network.connectWithPsk(password);
        else
            network.connect();
    }

    function disconnectNetwork(network) {
        if (network)
            network.disconnect();
    }

    function forgetNetwork(network) {
        if (network)
            network.forget();
    }

    function toggleBluetoothEnabled() {
        if (bluetoothAdapter)
            bluetoothAdapter.enabled = !bluetoothAdapter.enabled;
    }

    function toggleBluetoothDiscovery() {
        if (bluetoothAdapter)
            bluetoothAdapter.discovering = !bluetoothAdapter.discovering;
    }

    function connectBluetooth(device) {
        if (device)
            device.connect();
    }

    function disconnectBluetooth(device) {
        if (device)
            device.disconnect();
    }

    function pairBluetooth(device) {
        if (device)
            device.pair();
    }

    function forgetBluetooth(device) {
        if (device)
            device.forget();
    }

    function passwordCommand(name) {
        return "nmcli -s -g 802-11-wireless-security.psk connection show " + shellQuote(name);
    }

    function copyPasswordCommand(name) {
        const command = passwordCommand(name);
        Quickshell.clipboardText = command;
        lastCopiedText = "Copied password retrieval command for " + name;
    }

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\"'\"'") + "'";
    }

    function wiredState() {
        if (!wiredAvailable)
            return "no wired device";

        const name = wiredDevice.name || "Wired";
        const state = ConnectionState.toString(wiredDevice.state).toLowerCase();
        let details = state;

        if (wiredDevice.hasLink !== undefined && !wiredDevice.hasLink)
            details = "no link";
        else if (wiredDevice.linkSpeed > 0)
            details += " - " + wiredDevice.linkSpeed + " Mb/s";

        if (!wiredDevice.nmManaged)
            details += " - unmanaged";

        return name + " - " + details;
    }

    function wifiState() {
        if (!wifiHardwareEnabled)
            return "hardware disabled";

        if (!wifiEnabled)
            return "off";

        if (wifiScanning)
            return "scanning";

        if (!wifiConnected)
            return "on - no connection";

        if (activeWifi.stateChanging)
            return ConnectionState.toString(activeWifi.state).toLowerCase();

        if (Networking.connectivity === NetworkConnectivity.Portal)
            return "captive portal";

        if (Networking.connectivity === NetworkConnectivity.Limited)
            return "limited connectivity";

        if (Networking.connectivity === NetworkConnectivity.None)
            return "no internet";

        return "connected";
    }

    function bluetoothState() {
        if (!bluetoothAvailable)
            return "no adapter";

        if (bluetoothAdapter.state === BluetoothAdapterState.Blocked)
            return "blocked";

        if (bluetoothAdapter.state === BluetoothAdapterState.Enabling)
            return "enabling";

        if (bluetoothAdapter.state === BluetoothAdapterState.Disabling)
            return "disabling";

        if (!bluetoothEnabled)
            return "off";

        if (bluetoothDiscovering)
            return "discovering";

        if (bluetoothConnected)
            return "connected";

        return "on - no device connected";
    }

    function wifiInfoText() {
        if (!wifiConnected)
            return wifiStateText;

        const security = WifiSecurityType.toString(activeWifi.security);
        return activeWifi.name + " - " + wifiSignal + "% - " + wifiStateText + (security.length > 0 ? " - " + security : "");
    }

    function bluetoothInfoText() {
        if (!bluetoothConnected)
            return bluetoothStateText;

        const names = [];

        for (let index = 0; index < connectedBluetoothDevices.length; index++) {
            const device = connectedBluetoothDevices[index];
            let label = device.name || device.deviceName || device.address || "Unknown device";

            if (device.batteryAvailable)
                label += " " + normalizedPercent(device.battery) + "%";

            names.push(label);
        }

        return bluetoothStateText + ": " + names.join(", ");
    }

    function wifiGlyph() {
        if (!wifiHardwareEnabled || !wifiEnabled)
            return "󰤭";

        if (!wifiConnected)
            return "󰤩";

        return "󰤨";
    }

    function bluetoothGlyph() {
        if (!bluetoothAvailable || !bluetoothEnabled)
            return "󰂲";

        if (!bluetoothConnected)
            return "";

        return "";
    }

    function normalizedPercent(value) {
        const parsed = Number(value);

        if (!Number.isFinite(parsed))
            return 0;

        return Math.max(0, Math.min(100, Math.round(parsed <= 1 ? parsed * 100 : parsed)));
    }
}
