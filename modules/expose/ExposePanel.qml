import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootExposePanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    property bool presented: false
    readonly property int overviewItemCount: service.currentClients.length + service.workspaceClusters.length
    readonly property int maxColumnsByWidth: Math.max(1, Math.floor((width - theme.modules.expose.panelMargin * 2 + theme.modules.expose.cardGap) / (theme.modules.expose.currentCardWidth + theme.modules.expose.cardGap)))
    readonly property int gridColumns: Math.max(1, Math.min(theme.modules.expose.gridMaxColumns, overviewItemCount, maxColumnsByWidth))
    readonly property int gridRows: overviewItemCount > 0 ? Math.ceil(overviewItemCount / gridColumns) : 1
    readonly property point gatherPoint: Qt.point(width / 2, height / 2)

    signal closeRequested

    implicitWidth: screen.width
    implicitHeight: screen.height

    color: theme.modules.expose.overlayColor
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.namespace: "qreep-expose"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        background.forceActiveFocus();
        if (panelOpen)
            enterTimer.restart();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            background.forceActiveFocus();
            enterTimer.restart();
            return;
        }

        enterTimer.stop();
        presented = false;
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: rootExposePanel.closeRequested()
    }

    Shortcut {
        sequence: "Return"
        context: Qt.WindowShortcut
        onActivated: rootExposePanel.service.focusSelected()
    }

    Shortcut {
        sequence: "Enter"
        context: Qt.WindowShortcut
        onActivated: rootExposePanel.service.focusSelected()
    }

    Shortcut {
        sequence: "Left"
        context: Qt.WindowShortcut
        onActivated: rootExposePanel.selectSpatial("left")
    }

    Shortcut {
        sequence: "Right"
        context: Qt.WindowShortcut
        onActivated: rootExposePanel.selectSpatial("right")
    }

    Shortcut {
        sequence: "Up"
        context: Qt.WindowShortcut
        onActivated: rootExposePanel.selectSpatial("up")
    }

    Shortcut {
        sequence: "Down"
        context: Qt.WindowShortcut
        onActivated: rootExposePanel.selectSpatial("down")
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: rootExposePanel.presented = true
    }

    Rectangle {
        id: background

        anchors.fill: parent
        color: "transparent"
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                rootExposePanel.closeRequested();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                rootExposePanel.service.focusSelected();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                rootExposePanel.selectSpatial("left");
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                rootExposePanel.selectSpatial("right");
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                rootExposePanel.selectSpatial("up");
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                rootExposePanel.selectSpatial("down");
                event.accepted = true;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: rootExposePanel.closeRequested()
        }
    }

    Item {
        id: overview

        anchors {
            fill: parent
            margins: rootExposePanel.theme.modules.expose.panelMargin
        }
        opacity: rootExposePanel.presented ? 1 : 0
        y: rootExposePanel.presented ? 0 : 18

        Behavior on opacity {
            NumberAnimation {
                duration: rootExposePanel.theme.modules.expose.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: rootExposePanel.theme.modules.expose.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Grid {
            id: overviewGrid

            anchors.centerIn: parent
            width: Math.min(parent.width, rootExposePanel.gridColumns * rootExposePanel.theme.modules.expose.currentCardWidth + Math.max(0, rootExposePanel.gridColumns - 1) * spacing)
            height: Math.min(parent.height, rootExposePanel.gridRows * rootExposePanel.theme.modules.expose.currentCardHeight + Math.max(0, rootExposePanel.gridRows - 1) * spacing)
            columns: rootExposePanel.gridColumns
            spacing: rootExposePanel.theme.modules.expose.cardGap

            Repeater {
                id: currentRepeater

                model: rootExposePanel.service.currentClients

                ExposeClientCard {
                    required property var modelData
                    required property int index

                    theme: rootExposePanel.theme
                    client: modelData
                    selected: modelData.address === rootExposePanel.service.selectedAddress
                    entrancePresented: rootExposePanel.presented
                    entranceIndex: index
                    entranceGatherPoint: rootExposePanel.gatherPoint

                    onSelectedRequested: card => rootExposePanel.service.selectAddress(card.client.address)
                    onActivated: client => rootExposePanel.service.focusClient(client)
                }
            }

            Repeater {
                id: clusterRepeater

                model: rootExposePanel.service.workspaceClusters

                ExposeWorkspaceCluster {
                    required property var modelData
                    required property int index

                    theme: rootExposePanel.theme
                    cluster: modelData
                    selectedAddress: rootExposePanel.service.selectedAddress
                    gridTile: true
                    entrancePresented: rootExposePanel.presented
                    entranceIndex: rootExposePanel.service.currentClients.length + index
                    entranceGatherPoint: rootExposePanel.gatherPoint

                    onSelectedRequested: card => rootExposePanel.service.selectAddress(card.client.address)
                    onActivated: client => rootExposePanel.service.focusClient(client)
                }
            }
        }
    }

    Rectangle {
        visible: rootExposePanel.service.error.length > 0
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: rootExposePanel.theme.modules.expose.panelMargin
        }
        width: Math.min(720, parent.width - rootExposePanel.theme.modules.expose.panelMargin * 2)
        height: errorText.implicitHeight + 24
        radius: rootExposePanel.theme.modules.expose.cardRadius
        color: Qt.rgba(rootExposePanel.theme.error.r, rootExposePanel.theme.error.g, rootExposePanel.theme.error.b, 0.16)
        border.width: 1
        border.color: rootExposePanel.theme.error

        Text {
            id: errorText

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 12
            }
            text: rootExposePanel.service.error
            color: rootExposePanel.theme.modules.expose.primaryTextColor
            font.pixelSize: rootExposePanel.theme.modules.expose.subtitlePixelSize
            wrapMode: Text.Wrap
        }
    }

    function selectSpatial(direction) {
        const entries = navigationEntries();

        if (entries.length === 0)
            return;

        let currentIndex = -1;

        for (let index = 0; index < entries.length; index++) {
            if (entryContainsAddress(entries[index], service.selectedAddress)) {
                currentIndex = index;
                break;
            }
        }

        if (currentIndex < 0) {
            service.selectAddress(entries[0].address);
            return;
        }

        if (entries[currentIndex].cluster && entries[currentIndex].item) {
            const innerAddress = entries[currentIndex].item.navigateWithin(direction);

            if (innerAddress.length > 0) {
                service.selectAddress(innerAddress);
                return;
            }
        }

        const column = currentIndex % gridColumns;
        let nextIndex = currentIndex;

        switch (direction) {
        case "left":
            if (column > 0)
                nextIndex = currentIndex - 1;
            break;
        case "right":
            if (column < gridColumns - 1 && currentIndex + 1 < entries.length)
                nextIndex = currentIndex + 1;
            break;
        case "up":
            if (currentIndex - gridColumns >= 0)
                nextIndex = currentIndex - gridColumns;
            break;
        case "down":
            if (currentIndex + gridColumns < entries.length)
                nextIndex = currentIndex + gridColumns;
            break;
        }

        if (nextIndex !== currentIndex)
            service.selectAddress(entries[nextIndex].address);
    }

    function navigationEntries() {
        const entries = [];

        for (let index = 0; index < currentRepeater.count; index++) {
            const item = currentRepeater.itemAt(index);

            if (item)
                entries.push({ item: item, address: String(item.client.address || ""), cluster: false });
        }

        for (let index = 0; index < clusterRepeater.count; index++) {
            const cluster = clusterRepeater.itemAt(index);

            if (cluster) {
                const address = cluster.primaryAddress();

                if (address.length > 0)
                    entries.push({ item: cluster, address: address, cluster: true });
            }
        }

        return entries;
    }

    function entryContainsAddress(entry, address) {
        const value = String(address || "");

        if (entry.address === value)
            return true;

        return entry.cluster && entry.item && entry.item.containsAddress(value);
    }
}
