import QtQuick
import Quickshell.Io

QtObject {
    id: rootWifiQrService

    property bool cameraAvailable: false
    property bool imageDecoderAvailable: false
    property bool cameraScanning: cameraRunner.running
    property bool imageDecoding: imageRunner.running
    property bool cameraStopping: false
    property bool cameraSuccess: false
    property var pendingCameraCredentials: null
    property string statusText: ""
    property string errorText: ""

    signal credentialsReady(var credentials)

    readonly property Process cameraAvailabilityRunner: Process {
        command: ["/usr/bin/which", "zbarcam"]

        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => rootWifiQrService.cameraAvailable = exitCode === 0
    }

    readonly property Process imageAvailabilityRunner: Process {
        command: ["/usr/bin/which", "zbarimg"]

        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => rootWifiQrService.imageDecoderAvailable = exitCode === 0
    }

    readonly property Process cameraRunner: Process {
        stdout: SplitParser {
            onRead: data => rootWifiQrService.handleCameraPayload(data)
        }

        stderr: StdioCollector {
            id: cameraStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => {
            if (rootWifiQrService.cameraStopping) {
                rootWifiQrService.cameraStopping = false;
                return;
            }

            if (exitCode !== 0) {
                rootWifiQrService.statusText = "";
                rootWifiQrService.errorText = rootWifiQrService.safeDecoderError(cameraStderr.text, "Camera QR scanning failed.");
            } else if (!rootWifiQrService.cameraSuccess) {
                rootWifiQrService.statusText = "";
                rootWifiQrService.errorText = "The camera preview closed before a Wi-Fi QR code was detected.";
            }
        }
    }

    readonly property Process imageRunner: Process {
        stdout: StdioCollector {
            id: imageStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: imageStderr
            waitForEnd: true
        }

        onExited: (exitCode, exitStatus) => rootWifiQrService.finishImageDecode(exitCode, imageStdout.text, imageStderr.text)
    }

    readonly property Timer cameraSuccessTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: {
            const credentials = rootWifiQrService.pendingCameraCredentials;

            rootWifiQrService.stopCameraScan(true);
            rootWifiQrService.cameraSuccess = false;
            rootWifiQrService.pendingCameraCredentials = null;

            if (credentials)
                rootWifiQrService.credentialsReady(credentials);
        }
    }

    Component.onCompleted: checkAvailability()

    function checkAvailability() {
        cameraAvailabilityRunner.running = true;
        imageAvailabilityRunner.running = true;
    }

    function startCameraScan() {
        clearMessage();

        if (!cameraAvailable) {
            errorText = "Camera QR scanning needs ZBar (zbarcam).";
            return;
        }

        if (cameraRunner.running)
            return;

        statusText = "Scanning for a Wi-Fi QR code...";
        cameraSuccess = false;
        pendingCameraCredentials = null;
        cameraStopping = false;
        cameraRunner.command = ["zbarcam", "--quiet", "--nodbus", "--raw"];
        cameraRunner.running = true;
    }

    function stopCameraScan(preserveSuccess) {
        if (!cameraRunner.running)
            return;

        cameraStopping = true;
        cameraRunner.running = false;
        cameraSuccessTimer.stop();

        if (!preserveSuccess) {
            cameraSuccess = false;
            pendingCameraCredentials = null;
            statusText = "";
        }
    }

    function decodeImage(path) {
        clearMessage();

        if (!imageDecoderAvailable) {
            errorText = "Image QR decoding needs ZBar (zbarimg).";
            return;
        }

        if (!path || imageRunner.running)
            return;

        statusText = "Reading QR code from image...";
        imageRunner.command = ["zbarimg", "--quiet", "--nodisplay", "--nodbus", "--oneshot", "--raw", path];
        imageRunner.running = true;
    }

    function finishImageDecode(exitCode, stdoutText, stderrText) {
        statusText = "";

        if (exitCode !== 0) {
            errorText = safeDecoderError(stderrText, "No readable QR code was found in that image.");
            return;
        }

        const payloads = String(stdoutText || "").split(/\r?\n/);
        for (let index = 0; index < payloads.length; index++) {
            if (String(payloads[index]).trim().toUpperCase().indexOf("WIFI:") === 0) {
                acceptPayload(payloads[index], false);
                return;
            }
        }

        errorText = "The image contains a QR code, but it is not a Wi-Fi QR code.";
    }

    function handleCameraPayload(payload) {
        if (cameraSuccess)
            return;

        if (String(payload || "").trim().toUpperCase().indexOf("WIFI:") !== 0) {
            errorText = "That QR code is not a Wi-Fi QR code. Still scanning.";
            return;
        }

        acceptPayload(payload, true);
    }

    function acceptPayload(payload, fromCamera) {
        const result = parseWifiPayload(payload);

        if (!result.ok) {
            errorText = result.error;
            return;
        }

        errorText = "";

        if (fromCamera) {
            cameraSuccess = true;
            pendingCameraCredentials = result.credentials;
            statusText = "QR detected for " + result.credentials.ssid + ". Connecting...";
            cameraSuccessTimer.restart();
            return;
        }

        statusText = "Wi-Fi QR code read for " + result.credentials.ssid + ".";
        credentialsReady(result.credentials);
    }

    function parseWifiPayload(payload) {
        const text = String(payload || "").trim();

        if (text.slice(0, 5).toUpperCase() !== "WIFI:")
            return { ok: false, error: "This QR code does not contain Wi-Fi credentials." };

        let body = text.slice(5);
        if (body.endsWith(";;"))
            body = body.slice(0, -2);
        else if (body.endsWith(";"))
            body = body.slice(0, -1);

        const fields = splitEscaped(body, ";");
        const values = {};

        for (let index = 0; index < fields.length; index++) {
            const field = fields[index];
            const separator = firstUnescapedIndex(field, ":");

            if (separator <= 0)
                continue;

            const key = field.slice(0, separator).toUpperCase();
            values[key] = unescapeValue(field.slice(separator + 1));
        }

        const ssid = String(values.S || "");
        if (ssid.length === 0)
            return { ok: false, error: "The Wi-Fi QR code has no network name." };

        const rawSecurity = String(values.T || "nopass").toUpperCase();
        let security = "";

        if (rawSecurity === "NOPASS" || rawSecurity === "")
            security = "nopass";
        else if (rawSecurity === "WPA" || rawSecurity === "WPA2" || rawSecurity === "WPA3" || rawSecurity === "WPA/WPA2")
            security = "wpa";
        else if (rawSecurity === "WEP")
            security = "wep";
        else
            return { ok: false, error: "This Wi-Fi QR security type is not supported." };

        const password = String(values.P || "");
        if (security !== "nopass" && password.length === 0)
            return { ok: false, error: "The Wi-Fi QR code has no password." };

        return {
            ok: true,
            credentials: {
                ssid: ssid,
                password: password,
                security: security,
                hidden: String(values.H || "false").toLowerCase() === "true"
            }
        };
    }

    function splitEscaped(text, separator) {
        const result = [];
        let current = "";
        let escaped = false;

        for (let index = 0; index < text.length; index++) {
            const character = text[index];

            if (escaped) {
                current += "\\" + character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else if (character === separator) {
                result.push(current);
                current = "";
            } else {
                current += character;
            }
        }

        if (escaped)
            current += "\\";

        result.push(current);
        return result;
    }

    function firstUnescapedIndex(text, wanted) {
        let escaped = false;

        for (let index = 0; index < text.length; index++) {
            if (escaped) {
                escaped = false;
            } else if (text[index] === "\\") {
                escaped = true;
            } else if (text[index] === wanted) {
                return index;
            }
        }

        return -1;
    }

    function unescapeValue(value) {
        let result = "";
        let escaped = false;

        for (let index = 0; index < value.length; index++) {
            const character = value[index];

            if (escaped) {
                result += character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else {
                result += character;
            }
        }

        if (escaped)
            result += "\\";

        return result;
    }

    function safeDecoderError(stderrText, fallback) {
        const text = String(stderrText || "").trim();

        if (text.indexOf("No such file") >= 0 || text.indexOf("not found") >= 0)
            return "ZBar is unavailable. Install the Arch package 'zbar' to use Wi-Fi QR actions.";

        return fallback;
    }

    function clearMessage() {
        statusText = "";
        errorText = "";
        cameraSuccess = false;
    }
}
