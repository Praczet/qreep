import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Networking

FloatingWindow {
    id: rootWifiManagerPanel

    required property QtObject theme
    required property QtObject service

    property var passwordTarget: null
    property string passwordText: ""
    property bool showPassword: false

    readonly property var networks: service.wifiManagerNetworks()

    title: "Qreep Wi-Fi"
    implicitWidth: rootWifiManagerPanel.theme.modules.bar.network.managerWidth
    implicitHeight: rootWifiManagerPanel.theme.modules.bar.network.managerHeight
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false

    onVisibleChanged: {
        if (visible) {
            qrService.checkAvailability();
            service.beginWifiManager();
        } else {
            service.endWifiManager();
            qrService.stopCameraScan();
            clearPassword();
        }
    }

    WifiQrService {
        id: qrService

        onCredentialsReady: credentials => rootWifiManagerPanel.connectQrCredentials(credentials)
    }

    FileDialog {
        id: qrImageDialog

        title: "Choose a Wi-Fi QR image"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp *.gif)", "All files (*)"]

        onAccepted: qrService.decodeImage(rootWifiManagerPanel.localFilePath(selectedFile))
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: rootWifiManagerPanel.visible
        onActivated: {
            if (qrService.cameraScanning)
                qrService.stopCameraScan();
            else if (rootWifiManagerPanel.passwordTarget)
                rootWifiManagerPanel.clearPassword();
            else
                rootWifiManagerPanel.visible = false;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: rootWifiManagerPanel.theme.modules.bar.network.managerRadius
        color: rootWifiManagerPanel.theme.modules.bar.network.panelBackgroundColor
        border.width: 1
        border.color: rootWifiManagerPanel.theme.modules.bar.network.borderColor
        clip: true

        Column {
            anchors {
                fill: parent
                margins: rootWifiManagerPanel.theme.modules.bar.network.managerPadding
            }
            spacing: rootWifiManagerPanel.theme.modules.bar.network.sectionSpacing

            Row {
                width: parent.width
                height: 34
                spacing: 8

                Column {
                    width: parent.width - wifiToggle.width - closeButton.width - parent.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "Wi-Fi"
                        color: rootWifiManagerPanel.theme.modules.bar.network.primaryTextColor
                        font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.managerTitlePixelSize
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: rootWifiManagerPanel.service.wifiInfo
                        color: rootWifiManagerPanel.theme.modules.bar.network.secondaryTextColor
                        font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.bodyPixelSize
                    }
                }

                NetworkAction {
                    id: wifiToggle
                    theme: rootWifiManagerPanel.theme
                    label: rootWifiManagerPanel.service.wifiEnabled ? "Turn off" : "Turn on"
                    enabled: rootWifiManagerPanel.service.wifiHardwareEnabled
                    onTriggered: rootWifiManagerPanel.service.toggleWifiEnabled()
                }

                NetworkAction {
                    id: closeButton
                    theme: rootWifiManagerPanel.theme
                    label: "Close"
                    onTriggered: rootWifiManagerPanel.visible = false
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: rootWifiManagerPanel.theme.modules.bar.network.borderColor
            }

            Rectangle {
                visible: rootWifiManagerPanel.service.wifiConnected
                width: parent.width
                height: visible ? connectedContent.implicitHeight + rootWifiManagerPanel.theme.modules.bar.network.sectionPadding * 2 : 0
                radius: rootWifiManagerPanel.theme.modules.bar.network.sectionRadius
                color: rootWifiManagerPanel.theme.modules.bar.network.sectionBackgroundColor

                Row {
                    id: connectedContent
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: rootWifiManagerPanel.theme.modules.bar.network.sectionPadding
                    }
                    spacing: 10

                    Text {
                        text: rootWifiManagerPanel.signalIcon(rootWifiManagerPanel.service.activeWifi)
                        color: rootWifiManagerPanel.theme.modules.bar.network.activeColor
                        font.family: rootWifiManagerPanel.theme.iconFontFamily
                        font.pixelSize: 24
                    }

                    Column {
                        width: parent.width - disconnectButton.width - 44
                        spacing: 3

                        Text {
                            width: parent.width
                            text: rootWifiManagerPanel.service.activeWifi ? rootWifiManagerPanel.service.activeWifi.name : ""
                            color: rootWifiManagerPanel.theme.modules.bar.network.primaryTextColor
                            font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.titlePixelSize
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: "Connected  ·  " + rootWifiManagerPanel.service.wifiSignal + "%  ·  " + rootWifiManagerPanel.securityText(rootWifiManagerPanel.service.activeWifi)
                            color: rootWifiManagerPanel.theme.modules.bar.network.secondaryTextColor
                            font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.bodyPixelSize
                            elide: Text.ElideRight
                        }
                    }

                    NetworkAction {
                        id: disconnectButton
                        theme: rootWifiManagerPanel.theme
                        label: "Disconnect"
                        enabled: !rootWifiManagerPanel.service.wifiConnectionBusy
                        onTriggered: rootWifiManagerPanel.service.disconnectNetwork(rootWifiManagerPanel.service.activeWifi)
                    }
                }
            }

            Rectangle {
                visible: rootWifiManagerPanel.service.wifiConnectionStatus.length > 0 || rootWifiManagerPanel.service.wifiConnectionError.length > 0
                width: parent.width
                height: visible ? connectionMessage.implicitHeight + 16 : 0
                radius: rootWifiManagerPanel.theme.modules.bar.network.actionRadius
                color: rootWifiManagerPanel.service.wifiConnectionError.length > 0
                    ? rootWifiManagerPanel.theme.modules.bar.network.errorBackgroundColor
                    : rootWifiManagerPanel.theme.modules.bar.network.rowBackgroundColor

                Text {
                    id: connectionMessage
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: 8
                    }
                    text: rootWifiManagerPanel.service.wifiConnectionError || rootWifiManagerPanel.service.wifiConnectionStatus
                    color: rootWifiManagerPanel.service.wifiConnectionError.length > 0
                        ? rootWifiManagerPanel.theme.modules.bar.network.errorTextColor
                        : rootWifiManagerPanel.theme.modules.bar.network.primaryTextColor
                    font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.bodyPixelSize
                    wrapMode: Text.Wrap
                }
            }

            Row {
                width: parent.width
                height: 30
                spacing: 8

                Text {
                    width: parent.width - rescanButton.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: rootWifiManagerPanel.service.wifiScanning ? "Available networks  ·  scanning" : "Available networks"
                    color: rootWifiManagerPanel.theme.modules.bar.network.primaryTextColor
                    font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.titlePixelSize
                    font.weight: Font.DemiBold
                }

                NetworkAction {
                    id: rescanButton
                    theme: rootWifiManagerPanel.theme
                    label: "Rescan"
                    enabled: rootWifiManagerPanel.service.wifiEnabled && rootWifiManagerPanel.service.wifiDevice !== null
                    onTriggered: rootWifiManagerPanel.service.forceWifiRescan()
                }
            }

            Rectangle {
                width: parent.width
                height: rootWifiManagerPanel.theme.modules.bar.network.networkListHeight
                radius: rootWifiManagerPanel.theme.modules.bar.network.sectionRadius
                color: rootWifiManagerPanel.theme.modules.bar.network.sectionBackgroundColor
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: !rootWifiManagerPanel.service.wifiEnabled || rootWifiManagerPanel.networks.length === 0
                    width: parent.width - 32
                    text: !rootWifiManagerPanel.service.wifiEnabled
                        ? "Wi-Fi is off. Turn it on to discover networks."
                        : (rootWifiManagerPanel.service.wifiScanning ? "Looking for nearby networks..." : "No nearby networks found. Try Rescan.")
                    color: rootWifiManagerPanel.theme.modules.bar.network.secondaryTextColor
                    font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.bodyPixelSize
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }

                ListView {
                    id: networkList
                    anchors {
                        fill: parent
                        margins: 6
                    }
                    visible: rootWifiManagerPanel.service.wifiEnabled && rootWifiManagerPanel.networks.length > 0
                    model: rootWifiManagerPanel.networks
                    spacing: 5
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: networkRow

                        required property var modelData

                        width: networkList.width
                        height: rootWifiManagerPanel.theme.modules.bar.network.networkRowHeight
                        radius: rootWifiManagerPanel.theme.modules.bar.network.actionRadius
                        color: rowMouse.containsMouse
                            ? rootWifiManagerPanel.theme.modules.bar.network.rowHoverBackgroundColor
                            : rootWifiManagerPanel.theme.modules.bar.network.rowBackgroundColor

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !rootWifiManagerPanel.service.wifiConnectionBusy
                            onClicked: rootWifiManagerPanel.chooseNetwork(networkRow.modelData)
                        }

                        Row {
                            anchors {
                                fill: parent
                                leftMargin: 10
                                rightMargin: 8
                            }
                            spacing: 10

                            Text {
                                width: 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: rootWifiManagerPanel.signalIcon(networkRow.modelData)
                                color: networkRow.modelData.connected
                                    ? rootWifiManagerPanel.theme.modules.bar.network.activeColor
                                    : rootWifiManagerPanel.theme.modules.bar.network.primaryTextColor
                                font.family: rootWifiManagerPanel.theme.iconFontFamily
                                font.pixelSize: 19
                            }

                            Column {
                                width: parent.width - connectButton.width - 58
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: networkRow.modelData.name
                                    color: rootWifiManagerPanel.theme.modules.bar.network.primaryTextColor
                                    font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.titlePixelSize
                                    font.weight: networkRow.modelData.connected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: rootWifiManagerPanel.networkMeta(networkRow.modelData)
                                    color: rootWifiManagerPanel.theme.modules.bar.network.secondaryTextColor
                                    font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.bodyPixelSize
                                    elide: Text.ElideRight
                                }
                            }

                            NetworkAction {
                                id: connectButton
                                anchors.verticalCenter: parent.verticalCenter
                                theme: rootWifiManagerPanel.theme
                                label: networkRow.modelData.connected ? "Connected" : (networkRow.modelData.known ? "Connect" : "Join")
                                enabled: !networkRow.modelData.connected && !rootWifiManagerPanel.service.wifiConnectionBusy
                                onTriggered: rootWifiManagerPanel.chooseNetwork(networkRow.modelData)
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: rootWifiManagerPanel.passwordTarget !== null
                width: parent.width
                height: visible ? passwordContent.implicitHeight + rootWifiManagerPanel.theme.modules.bar.network.sectionPadding * 2 : 0
                radius: rootWifiManagerPanel.theme.modules.bar.network.sectionRadius
                color: rootWifiManagerPanel.theme.modules.bar.network.sectionBackgroundColor

                Column {
                    id: passwordContent
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootWifiManagerPanel.theme.modules.bar.network.sectionPadding
                    }
                    spacing: 8

                    Text {
                        text: "Connect to “" + (rootWifiManagerPanel.passwordTarget ? rootWifiManagerPanel.passwordTarget.name : "") + "”"
                        color: rootWifiManagerPanel.theme.modules.bar.network.primaryTextColor
                        font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.titlePixelSize
                        font.weight: Font.DemiBold
                    }

                    Row {
                        width: parent.width
                        height: rootWifiManagerPanel.theme.modules.bar.network.inputHeight
                        spacing: 8

                        Rectangle {
                            width: parent.width - showPasswordButton.width - parent.spacing
                            height: parent.height
                            radius: rootWifiManagerPanel.theme.modules.bar.network.actionRadius
                            color: rootWifiManagerPanel.theme.modules.bar.network.panelBackgroundColor
                            border.width: 1
                            border.color: passwordInput.activeFocus
                                ? rootWifiManagerPanel.theme.modules.bar.network.activeColor
                                : rootWifiManagerPanel.theme.modules.bar.network.borderColor

                            TextInput {
                                id: passwordInput
                                anchors {
                                    fill: parent
                                    leftMargin: 10
                                    rightMargin: 10
                                }
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: rootWifiManagerPanel.showPassword ? TextInput.Normal : TextInput.Password
                                color: rootWifiManagerPanel.theme.modules.bar.network.primaryTextColor
                                selectionColor: rootWifiManagerPanel.theme.modules.bar.network.activeColor
                                font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.bodyPixelSize
                                text: rootWifiManagerPanel.passwordText
                                onTextChanged: rootWifiManagerPanel.passwordText = text
                                onAccepted: rootWifiManagerPanel.submitPassword()
                            }
                        }

                        NetworkAction {
                            id: showPasswordButton
                            theme: rootWifiManagerPanel.theme
                            label: rootWifiManagerPanel.showPassword ? "Hide" : "Show"
                            onTriggered: rootWifiManagerPanel.showPassword = !rootWifiManagerPanel.showPassword
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 8
                        layoutDirection: Qt.RightToLeft

                        NetworkAction {
                            theme: rootWifiManagerPanel.theme
                            label: "Connect"
                            enabled: rootWifiManagerPanel.passwordText.length > 0 && !rootWifiManagerPanel.service.wifiConnectionBusy
                            onTriggered: rootWifiManagerPanel.submitPassword()
                        }

                        NetworkAction {
                            theme: rootWifiManagerPanel.theme
                            label: "Cancel"
                            onTriggered: rootWifiManagerPanel.clearPassword()
                        }
                    }
                }
            }

            Rectangle {
                id: qrSection

                width: parent.width
                height: qrContent.implicitHeight + rootWifiManagerPanel.theme.modules.bar.network.sectionPadding * 2
                radius: rootWifiManagerPanel.theme.modules.bar.network.sectionRadius
                color: qrService.cameraSuccess
                    ? rootWifiManagerPanel.theme.modules.bar.network.successBackgroundColor
                    : rootWifiManagerPanel.theme.modules.bar.network.sectionBackgroundColor
                border.width: qrService.cameraSuccess ? 2 : 0
                border.color: rootWifiManagerPanel.theme.modules.bar.network.successTextColor

                Behavior on color {
                    ColorAnimation { duration: rootWifiManagerPanel.theme.animationFastDuration }
                }

                Column {
                    id: qrContent
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootWifiManagerPanel.theme.modules.bar.network.sectionPadding
                    }
                    spacing: 8

                    Text {
                        text: "Connect using QR"
                        color: rootWifiManagerPanel.theme.modules.bar.network.primaryTextColor
                        font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.titlePixelSize
                        font.weight: Font.DemiBold
                    }

                    Text {
                        visible: !qrService.cameraAvailable && !qrService.imageDecoderAvailable
                        width: parent.width
                        text: "QR support is optional. Install the Arch package 'zbar' to enable it."
                        color: rootWifiManagerPanel.theme.modules.bar.network.secondaryTextColor
                        font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.bodyPixelSize
                        wrapMode: Text.Wrap
                    }

                    Text {
                        visible: qrService.cameraScanning && !qrService.cameraSuccess
                        width: parent.width
                        text: "The live preview is open in the ‘zbar barcode reader’ window. Hold the Wi-Fi QR code inside its frame."
                        color: rootWifiManagerPanel.theme.modules.bar.network.secondaryTextColor
                        font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.bodyPixelSize
                        wrapMode: Text.Wrap
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        NetworkAction {
                            theme: rootWifiManagerPanel.theme
                            label: qrService.cameraScanning ? "Cancel camera scan" : "Scan with camera"
                            enabled: qrService.cameraAvailable && !qrService.imageDecoding
                            onTriggered: {
                                if (qrService.cameraScanning)
                                    qrService.stopCameraScan();
                                else
                                    qrService.startCameraScan();
                            }
                        }

                        NetworkAction {
                            theme: rootWifiManagerPanel.theme
                            label: qrService.imageDecoding ? "Reading image" : "Choose image"
                            enabled: qrService.imageDecoderAvailable && !qrService.cameraScanning && !qrService.imageDecoding
                            onTriggered: qrImageDialog.open()
                        }
                    }

                    Text {
                        visible: qrService.statusText.length > 0 || qrService.errorText.length > 0
                        width: parent.width
                        text: qrService.errorText || qrService.statusText
                        color: qrService.errorText.length > 0
                            ? rootWifiManagerPanel.theme.modules.bar.network.errorTextColor
                            : (qrService.cameraSuccess
                                ? rootWifiManagerPanel.theme.modules.bar.network.successTextColor
                                : rootWifiManagerPanel.theme.modules.bar.network.secondaryTextColor)
                        font.pixelSize: rootWifiManagerPanel.theme.modules.bar.network.bodyPixelSize
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    function chooseNetwork(network) {
        if (!network || network.connected || service.wifiConnectionBusy)
            return;

        service.clearWifiConnectionMessage();

        if (network.known && service.failedWifiName !== network.name) {
            service.connectWifi(network, "");
            return;
        }

        if (network.security === WifiSecurityType.Open) {
            service.connectWifi(network, "");
            return;
        }

        passwordTarget = network;
        passwordText = "";
        showPassword = false;
        passwordFocusTimer.restart();
    }

    Timer {
        id: passwordFocusTimer
        interval: 0
        repeat: false
        onTriggered: passwordInput.forceActiveFocus()
    }

    function submitPassword() {
        const target = passwordTarget;
        const password = passwordText;

        if (!target || password.length === 0)
            return;

        clearPassword();
        service.connectWifi(target, password);
    }

    function clearPassword() {
        passwordTarget = null;
        passwordText = "";
        showPassword = false;
    }

    function connectQrCredentials(credentials) {
        const network = service.findWifiNetwork(credentials.ssid);

        if (!network) {
            qrService.statusText = "";
            qrService.errorText = credentials.hidden
                ? "The hidden network “" + credentials.ssid + "” is not available in the discovered list yet."
                : "“" + credentials.ssid + "” is not currently discovered. Rescan and try again.";
            return;
        }

        if (network.connected) {
            qrService.errorText = "";
            qrService.statusText = "Already connected to “" + credentials.ssid + "”.";
            return;
        }

        service.connectWifi(network, credentials.security === "nopass" ? "" : credentials.password);
    }

    function securityText(network) {
        return network ? WifiSecurityType.toString(network.security) : "";
    }

    function networkMeta(network) {
        if (!network)
            return "";

        const parts = [service.normalizedPercent(network.signalStrength) + "%"];
        const security = securityText(network);

        parts.push(security === "Open" ? "Open" : "Secured");

        if (network.connected)
            parts.push("Connected");
        else if (network.known)
            parts.push("Saved");

        return parts.join("  ·  ");
    }

    function signalIcon(network) {
        const strength = network ? service.normalizedPercent(network.signalStrength) : 0;

        if (strength >= 75)
            return "󰤨";
        if (strength >= 50)
            return "󰤥";
        if (strength >= 25)
            return "󰤢";

        return "󰤟";
    }

    function localFilePath(url) {
        const value = String(url || "");
        return decodeURIComponent(value.replace(/^file:\/\//, ""));
    }
}
