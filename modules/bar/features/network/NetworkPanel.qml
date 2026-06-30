import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth

PopupWindow {
    id: rootNetworkPanel

    required property QtObject theme
    required property QtObject service
    required property Item anchorItem

    property var passwordTarget: null
    property string passwordText: ""

    readonly property var availableWifi: service.availableWifiNetworks()
    readonly property var knownWifi: service.knownWifiNetworks()
    readonly property var pairedBluetooth: service.pairedBluetoothDevices()
    readonly property var nearbyBluetooth: service.nearbyBluetoothDevices()

    anchor {
        item: rootNetworkPanel.anchorItem
        rect.x: rootNetworkPanel.anchorItem.width - rootNetworkPanel.width
        rect.y: rootNetworkPanel.anchorItem.height + rootNetworkPanel.theme.modules.bar.network.panelTopOffset
    }

    implicitWidth: rootNetworkPanel.theme.modules.bar.network.panelWidth
    implicitHeight: Math.min(panelCard.implicitHeight, rootNetworkPanel.theme.modules.bar.network.panelMaxHeight)
    color: "transparent"
    grabFocus: true
    visible: false

    onVisibleChanged: {
        if (visible)
            service.refreshWiredDetails();
        else {
            passwordTarget = null;
            passwordText = "";
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: rootNetworkPanel.visible
        onActivated: rootNetworkPanel.visible = false
    }

    function networkName(network) {
        return network ? network.name : "";
    }

    function securityText(network) {
        return network ? WifiSecurityType.toString(network.security) : "";
    }

    function signalText(network) {
        return network ? service.normalizedPercent(network.signalStrength) + "%" : "";
    }

    function deviceName(device) {
        return device ? (device.name || device.deviceName || device.address || "Unknown device") : "Unknown device";
    }

    function bluetoothMeta(device) {
        if (!device)
            return "";

        const parts = [];
        parts.push(device.connected ? "connected" : BluetoothDeviceState.toString(device.state).toLowerCase());

        if (device.paired)
            parts.push("paired");

        if (device.batteryAvailable)
            parts.push(service.normalizedPercent(device.battery) + "%");

        return parts.join(" - ");
    }

    Rectangle {
        id: panelCard

        width: rootNetworkPanel.width
        height: rootNetworkPanel.height
        implicitHeight: Math.min(panelContent.implicitHeight + rootNetworkPanel.theme.modules.bar.network.panelPadding * 2, rootNetworkPanel.theme.modules.bar.network.panelMaxHeight)
        radius: rootNetworkPanel.theme.modules.bar.network.panelRadius
        color: rootNetworkPanel.theme.modules.bar.network.panelBackgroundColor
        border.width: 1
        border.color: rootNetworkPanel.theme.modules.bar.network.borderColor
        clip: true

        Flickable {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                margins: rootNetworkPanel.theme.modules.bar.network.panelPadding
            }
            contentWidth: width
            contentHeight: panelContent.implicitHeight
            clip: true

            Column {
                id: panelContent

                width: parent.width
                spacing: rootNetworkPanel.theme.modules.bar.network.sectionSpacing

            Row {
                width: parent.width
                spacing: 8

                Text {
                    width: parent.width - refreshButton.width - parent.spacing
                    text: "Network"
                    color: rootNetworkPanel.theme.modules.bar.network.primaryTextColor
                    font.pixelSize: rootNetworkPanel.theme.modules.bar.network.titlePixelSize
                    font.weight: Font.DemiBold
                }

                NetworkAction {
                    id: refreshButton
                    theme: rootNetworkPanel.theme
                    label: "Refresh"
                    onTriggered: {
                        rootNetworkPanel.service.refreshWiredDetails();
                        rootNetworkPanel.service.scanWifi();
                    }
                }
            }

            Rectangle {
                width: parent.width
                implicitHeight: wiredSection.implicitHeight + rootNetworkPanel.theme.modules.bar.network.sectionPadding * 2
                radius: rootNetworkPanel.theme.modules.bar.network.sectionRadius
                color: rootNetworkPanel.theme.modules.bar.network.sectionBackgroundColor

                Column {
                    id: wiredSection
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootNetworkPanel.theme.modules.bar.network.sectionPadding
                    }
                    spacing: rootNetworkPanel.theme.modules.bar.network.rowSpacing

                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "󰛳"
                            color: rootNetworkPanel.service.wiredActive ? rootNetworkPanel.theme.modules.bar.network.activeColor : rootNetworkPanel.theme.modules.bar.network.inactiveColor
                            font.family: rootNetworkPanel.theme.iconFontFamily
                            font.pixelSize: rootNetworkPanel.theme.modules.bar.network.iconPixelSize
                        }

                        Text {
                            width: parent.width - parent.spacing - wiredRestart.width - rootNetworkPanel.theme.modules.bar.network.iconPixelSize
                            text: "Wired"
                            color: rootNetworkPanel.theme.modules.bar.network.primaryTextColor
                            font.pixelSize: rootNetworkPanel.theme.modules.bar.network.titlePixelSize
                            font.weight: Font.DemiBold
                        }

                        NetworkAction {
                            id: wiredRestart
                            theme: rootNetworkPanel.theme
                            label: "Restart"
                            enabled: rootNetworkPanel.service.wiredAvailable
                            onTriggered: rootNetworkPanel.service.restartWired()
                        }
                    }

                    Text {
                        width: parent.width
                        text: rootNetworkPanel.service.wiredInfo
                        color: rootNetworkPanel.theme.modules.bar.network.secondaryTextColor
                        font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: "IP " + rootNetworkPanel.service.wiredIp + "   Gateway " + rootNetworkPanel.service.wiredGateway
                        color: rootNetworkPanel.theme.modules.bar.network.primaryTextColor
                        font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: "DNS " + rootNetworkPanel.service.wiredDns
                        color: rootNetworkPanel.theme.modules.bar.network.secondaryTextColor
                        font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                width: parent.width
                implicitHeight: wifiSection.implicitHeight + rootNetworkPanel.theme.modules.bar.network.sectionPadding * 2
                radius: rootNetworkPanel.theme.modules.bar.network.sectionRadius
                color: rootNetworkPanel.theme.modules.bar.network.sectionBackgroundColor

                Column {
                    id: wifiSection
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootNetworkPanel.theme.modules.bar.network.sectionPadding
                    }
                    spacing: rootNetworkPanel.theme.modules.bar.network.rowSpacing

                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: rootNetworkPanel.service.wifiIcon
                            color: rootNetworkPanel.service.wifiConnected ? rootNetworkPanel.theme.modules.bar.network.activeColor : rootNetworkPanel.theme.modules.bar.network.inactiveColor
                            font.family: rootNetworkPanel.theme.iconFontFamily
                            font.pixelSize: rootNetworkPanel.theme.modules.bar.network.iconPixelSize
                        }

                        Text {
                            width: parent.width - wifiToggle.width - wifiScan.width - rootNetworkPanel.theme.modules.bar.network.iconPixelSize - parent.spacing * 3
                            text: "Wi-Fi - " + rootNetworkPanel.service.wifiInfo
                            color: rootNetworkPanel.theme.modules.bar.network.primaryTextColor
                            font.pixelSize: rootNetworkPanel.theme.modules.bar.network.titlePixelSize
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        NetworkAction {
                            id: wifiToggle
                            theme: rootNetworkPanel.theme
                            label: rootNetworkPanel.service.wifiEnabled ? "Off" : "On"
                            enabled: rootNetworkPanel.service.wifiHardwareEnabled
                            onTriggered: rootNetworkPanel.service.toggleWifiEnabled()
                        }

                        NetworkAction {
                            id: wifiScan
                            theme: rootNetworkPanel.theme
                            label: rootNetworkPanel.service.wifiScanning ? "Scanning" : "Scan"
                            enabled: rootNetworkPanel.service.wifiEnabled && rootNetworkPanel.service.wifiDevice !== null
                            onTriggered: rootNetworkPanel.service.scanWifi()
                        }
                    }

                    Text {
                        visible: rootNetworkPanel.service.wifiConnected
                        width: parent.width
                        text: "Connected: " + rootNetworkPanel.networkName(rootNetworkPanel.service.activeWifi) + "  " + rootNetworkPanel.signalText(rootNetworkPanel.service.activeWifi) + "  " + rootNetworkPanel.securityText(rootNetworkPanel.service.activeWifi)
                        color: rootNetworkPanel.theme.modules.bar.network.secondaryTextColor
                        font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                        elide: Text.ElideRight
                    }

                    NetworkAction {
                        visible: rootNetworkPanel.service.wifiConnected
                        theme: rootNetworkPanel.theme
                        label: "Disconnect current Wi-Fi"
                        onTriggered: rootNetworkPanel.service.disconnectNetwork(rootNetworkPanel.service.activeWifi)
                    }

                    Text {
                        text: "Available"
                        color: rootNetworkPanel.theme.modules.bar.network.secondaryTextColor
                        font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                        font.weight: Font.DemiBold
                    }

                    Repeater {
                        model: rootNetworkPanel.availableWifi.slice(0, 8)

                        delegate: Rectangle {
                            required property var modelData

                            width: wifiSection.width
                            implicitHeight: wifiRow.implicitHeight + 8
                            radius: rootNetworkPanel.theme.modules.bar.network.actionRadius
                            color: rootNetworkPanel.theme.modules.bar.network.rowBackgroundColor

                            Column {
                                id: wifiRow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 8
                                    rightMargin: 8
                                }
                                spacing: 6

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        width: parent.width - wifiConnect.width - wifiDetails.width - parent.spacing * 2
                                        text: rootNetworkPanel.networkName(modelData) + "  " + rootNetworkPanel.signalText(modelData) + "  " + rootNetworkPanel.securityText(modelData)
                                        color: rootNetworkPanel.theme.modules.bar.network.primaryTextColor
                                        font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                                        elide: Text.ElideRight
                                    }

                                    NetworkAction {
                                        id: wifiDetails
                                        theme: rootNetworkPanel.theme
                                        label: modelData.known ? "Copy cmd" : "Password"
                                        onTriggered: {
                                            if (modelData.known)
                                                rootNetworkPanel.service.copyPasswordCommand(modelData.name);
                                            else
                                                rootNetworkPanel.passwordTarget = rootNetworkPanel.passwordTarget === modelData ? null : modelData;
                                        }
                                    }

                                    NetworkAction {
                                        id: wifiConnect
                                        theme: rootNetworkPanel.theme
                                        label: modelData.known ? "Connect" : "Join"
                                        onTriggered: {
                                            if (modelData.known || rootNetworkPanel.securityText(modelData) === "Open")
                                                rootNetworkPanel.service.connectWifi(modelData, "");
                                            else
                                                rootNetworkPanel.passwordTarget = modelData;
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    spacing: 8
                                    visible: rootNetworkPanel.passwordTarget === modelData

                                    Rectangle {
                                        width: parent.width - passwordJoin.width - parent.spacing
                                        height: rootNetworkPanel.theme.modules.bar.network.inputHeight
                                        radius: rootNetworkPanel.theme.modules.bar.network.actionRadius
                                        color: rootNetworkPanel.theme.modules.bar.network.panelBackgroundColor
                                        border.width: 1
                                        border.color: rootNetworkPanel.theme.modules.bar.network.borderColor

                                        TextInput {
                                            anchors {
                                                fill: parent
                                                leftMargin: 8
                                                rightMargin: 8
                                            }
                                            verticalAlignment: TextInput.AlignVCenter
                                            echoMode: TextInput.Password
                                            text: rootNetworkPanel.passwordText
                                            color: rootNetworkPanel.theme.modules.bar.network.primaryTextColor
                                            font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                                            onTextChanged: rootNetworkPanel.passwordText = text
                                        }
                                    }

                                    NetworkAction {
                                        id: passwordJoin
                                        theme: rootNetworkPanel.theme
                                        label: "Join"
                                        onTriggered: {
                                            rootNetworkPanel.service.connectWifi(modelData, rootNetworkPanel.passwordText);
                                            rootNetworkPanel.passwordText = "";
                                            rootNetworkPanel.passwordTarget = null;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "Known nearby"
                        color: rootNetworkPanel.theme.modules.bar.network.secondaryTextColor
                        font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                        font.weight: Font.DemiBold
                    }

                    Repeater {
                        model: rootNetworkPanel.knownWifi.slice(0, 5)

                        delegate: Row {
                            required property var modelData

                            width: wifiSection.width
                            spacing: 8

                            Text {
                                width: parent.width - knownConnect.width - knownForget.width - knownCopy.width - parent.spacing * 3
                                text: rootNetworkPanel.networkName(modelData) + "  " + rootNetworkPanel.signalText(modelData)
                                color: rootNetworkPanel.theme.modules.bar.network.primaryTextColor
                                font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                                elide: Text.ElideRight
                            }

                            NetworkAction {
                                id: knownCopy
                                theme: rootNetworkPanel.theme
                                label: "Copy cmd"
                                onTriggered: rootNetworkPanel.service.copyPasswordCommand(modelData.name)
                            }

                            NetworkAction {
                                id: knownForget
                                theme: rootNetworkPanel.theme
                                label: "Forget"
                                onTriggered: rootNetworkPanel.service.forgetNetwork(modelData)
                            }

                            NetworkAction {
                                id: knownConnect
                                theme: rootNetworkPanel.theme
                                label: "Connect"
                                onTriggered: rootNetworkPanel.service.connectWifi(modelData, "")
                            }
                        }
                    }

                    Text {
                        visible: rootNetworkPanel.service.lastCopiedText.length > 0
                        width: parent.width
                        text: rootNetworkPanel.service.lastCopiedText
                        color: rootNetworkPanel.theme.modules.bar.network.secondaryTextColor
                        font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                width: parent.width
                implicitHeight: bluetoothSection.implicitHeight + rootNetworkPanel.theme.modules.bar.network.sectionPadding * 2
                radius: rootNetworkPanel.theme.modules.bar.network.sectionRadius
                color: rootNetworkPanel.theme.modules.bar.network.sectionBackgroundColor

                Column {
                    id: bluetoothSection
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootNetworkPanel.theme.modules.bar.network.sectionPadding
                    }
                    spacing: rootNetworkPanel.theme.modules.bar.network.rowSpacing

                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: rootNetworkPanel.service.bluetoothIcon
                            color: rootNetworkPanel.service.bluetoothConnected ? rootNetworkPanel.theme.modules.bar.network.activeColor : rootNetworkPanel.theme.modules.bar.network.inactiveColor
                            font.family: rootNetworkPanel.theme.iconFontFamily
                            font.pixelSize: rootNetworkPanel.theme.modules.bar.network.iconPixelSize
                        }

                        Text {
                            width: parent.width - bluetoothToggle.width - bluetoothDiscover.width - rootNetworkPanel.theme.modules.bar.network.iconPixelSize - parent.spacing * 3
                            text: "Bluetooth - " + rootNetworkPanel.service.bluetoothInfo
                            color: rootNetworkPanel.theme.modules.bar.network.primaryTextColor
                            font.pixelSize: rootNetworkPanel.theme.modules.bar.network.titlePixelSize
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        NetworkAction {
                            id: bluetoothToggle
                            theme: rootNetworkPanel.theme
                            label: rootNetworkPanel.service.bluetoothEnabled ? "Off" : "On"
                            enabled: rootNetworkPanel.service.bluetoothAvailable
                            onTriggered: rootNetworkPanel.service.toggleBluetoothEnabled()
                        }

                        NetworkAction {
                            id: bluetoothDiscover
                            theme: rootNetworkPanel.theme
                            label: rootNetworkPanel.service.bluetoothDiscovering ? "Stop" : "Discover"
                            enabled: rootNetworkPanel.service.bluetoothEnabled
                            onTriggered: rootNetworkPanel.service.toggleBluetoothDiscovery()
                        }
                    }

                    Text {
                        text: "Paired / connected"
                        color: rootNetworkPanel.theme.modules.bar.network.secondaryTextColor
                        font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                        font.weight: Font.DemiBold
                    }

                    Repeater {
                        model: rootNetworkPanel.pairedBluetooth

                        delegate: Row {
                            required property var modelData

                            width: bluetoothSection.width
                            spacing: 8

                            Text {
                                width: parent.width - btConnect.width - btForget.width - parent.spacing * 2
                                text: rootNetworkPanel.deviceName(modelData) + " - " + rootNetworkPanel.bluetoothMeta(modelData)
                                color: rootNetworkPanel.theme.modules.bar.network.primaryTextColor
                                font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                                elide: Text.ElideRight
                            }

                            NetworkAction {
                                id: btForget
                                theme: rootNetworkPanel.theme
                                label: "Forget"
                                onTriggered: rootNetworkPanel.service.forgetBluetooth(modelData)
                            }

                            NetworkAction {
                                id: btConnect
                                theme: rootNetworkPanel.theme
                                label: modelData.connected ? "Disconnect" : "Connect"
                                onTriggered: {
                                    if (modelData.connected)
                                        rootNetworkPanel.service.disconnectBluetooth(modelData);
                                    else
                                        rootNetworkPanel.service.connectBluetooth(modelData);
                                }
                            }
                        }
                    }

                    Text {
                        text: "Nearby"
                        color: rootNetworkPanel.theme.modules.bar.network.secondaryTextColor
                        font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                        font.weight: Font.DemiBold
                    }

                    Repeater {
                        model: rootNetworkPanel.nearbyBluetooth.slice(0, 6)

                        delegate: Row {
                            required property var modelData

                            width: bluetoothSection.width
                            spacing: 8

                            Text {
                                width: parent.width - btPair.width - parent.spacing
                                text: rootNetworkPanel.deviceName(modelData) + " - " + rootNetworkPanel.bluetoothMeta(modelData)
                                color: rootNetworkPanel.theme.modules.bar.network.primaryTextColor
                                font.pixelSize: rootNetworkPanel.theme.modules.bar.network.bodyPixelSize
                                elide: Text.ElideRight
                            }

                            NetworkAction {
                                id: btPair
                                theme: rootNetworkPanel.theme
                                label: modelData.pairing ? "Cancel" : "Pair"
                                onTriggered: {
                                    if (modelData.pairing)
                                        modelData.cancelPair();
                                    else
                                        rootNetworkPanel.service.pairBluetooth(modelData);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    }
}
