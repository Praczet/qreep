import QtQuick

Rectangle {
    id: rootExposeWorkspaceCluster

    required property QtObject theme
    required property var cluster
    required property string selectedAddress
    property bool gridTile: false
    property bool entrancePresented: true
    property int entranceIndex: 0
    property point entranceGatherPoint: Qt.point(0, 0)
    property real entranceOvershootX: 0
    property real entranceOvershootY: 0

    signal selectedRequested(var card)
    signal activated(var client)

    width: gridTile ? theme.modules.expose.currentCardWidth : theme.modules.expose.clusterWidth
    height: gridTile ? theme.modules.expose.currentCardHeight : Math.max(theme.modules.expose.clusterMinHeight, clusterLayout.implicitHeight + theme.modules.expose.panelPadding)
    radius: theme.modules.expose.cardRadius
    color: theme.modules.expose.cardColor
    border.width: theme.modules.expose.borderWidth
    border.color: theme.modules.expose.borderColor
    clip: true

    transform: Translate {
        id: entranceTranslate

        x: 0
        y: 0
    }

    SequentialAnimation {
        id: entranceAnimation

        PauseAnimation {
            duration: rootExposeWorkspaceCluster.entranceIndex * rootExposeWorkspaceCluster.theme.modules.expose.cardEntranceStagger
        }

        ParallelAnimation {
            NumberAnimation {
                target: entranceTranslate
                property: "x"
                to: rootExposeWorkspaceCluster.entranceOvershootX
                duration: rootExposeWorkspaceCluster.theme.modules.expose.cardEntranceDuration * 0.72
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: entranceTranslate
                property: "y"
                to: rootExposeWorkspaceCluster.entranceOvershootY
                duration: rootExposeWorkspaceCluster.theme.modules.expose.cardEntranceDuration * 0.72
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: entranceTranslate
                property: "x"
                to: 0
                duration: rootExposeWorkspaceCluster.theme.modules.expose.cardEntranceDuration * 0.24
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: entranceTranslate
                property: "y"
                to: 0
                duration: rootExposeWorkspaceCluster.theme.modules.expose.cardEntranceDuration * 0.24
                easing.type: Easing.OutCubic
            }
        }
    }

    Component.onCompleted: resetEntrance()

    onEntrancePresentedChanged: {
        if (entrancePresented)
            playEntrance();
        else
            resetEntrance();
    }

    function selectableCards() {
        const cards = [];

        for (let index = 0; index < miniRepeater.count; index++) {
            const item = miniRepeater.itemAt(index);

            if (item)
                cards.push(item);
        }

        return cards;
    }

    function primaryAddress() {
        const clients = cluster.clients || [];

        return clients.length > 0 ? String(clients[0].address || "") : "";
    }

    function containsAddress(address) {
        const value = String(address || "");
        const clients = cluster.clients || [];

        for (let index = 0; index < clients.length; index++) {
            if (String(clients[index].address || "") === value)
                return true;
        }

        return false;
    }

    function selectedClientIndex() {
        const value = String(selectedAddress || "");
        const clients = cluster.clients || [];

        for (let index = 0; index < clients.length; index++) {
            if (String(clients[index].address || "") === value)
                return index;
        }

        return -1;
    }

    function navigateWithin(direction) {
        const clients = cluster.clients || [];

        if (clients.length === 0)
            return "";

        const columns = miniGridColumns();
        let index = selectedClientIndex();

        if (index < 0)
            index = 0;

        let nextIndex = index;

        switch (direction) {
        case "left":
            if (index % columns > 0)
                nextIndex = index - 1;
            break;
        case "right":
            if (index % columns < columns - 1 && index + 1 < clients.length)
                nextIndex = index + 1;
            break;
        case "up":
            if (index - columns >= 0)
                nextIndex = index - columns;
            break;
        case "down":
            if (index + columns < clients.length)
                nextIndex = index + columns;
            break;
        }

        return nextIndex !== index ? String(clients[nextIndex].address || "") : "";
    }

    function miniGridColumns() {
        return Math.max(1, Math.floor((miniFlow.width + miniFlow.spacing) / (rootExposeWorkspaceCluster.theme.modules.expose.miniCardWidth + miniFlow.spacing)));
    }

    function resetEntrance() {
        const offset = gatherOffsetFromCurrentCluster();

        entranceAnimation.stop();
        entranceTranslate.x = offset.x;
        entranceTranslate.y = offset.y;
    }

    function playEntrance() {
        const offset = gatherOffsetFromCurrentCluster();

        resetEntrance();
        entranceOvershootX = -offset.x * rootExposeWorkspaceCluster.theme.modules.expose.cardEntranceOvershoot;
        entranceOvershootY = -offset.y * rootExposeWorkspaceCluster.theme.modules.expose.cardEntranceOvershoot;
        entranceAnimation.restart();
    }

    function gatherOffsetFromCurrentCluster() {
        const topLeft = rootExposeWorkspaceCluster.mapToGlobal(Qt.point(0, 0));
        const centerX = topLeft.x + rootExposeWorkspaceCluster.width / 2;
        const centerY = topLeft.y + rootExposeWorkspaceCluster.height / 2;

        return Qt.point(rootExposeWorkspaceCluster.entranceGatherPoint.x - centerX, rootExposeWorkspaceCluster.entranceGatherPoint.y - centerY);
    }

    Column {
        id: clusterLayout

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: rootExposeWorkspaceCluster.theme.modules.expose.panelPadding / 2
        }
        spacing: 12

        Row {
            width: parent.width
            spacing: 10

            Text {
                width: parent.width - countLabel.width - parent.spacing
                text: rootExposeWorkspaceCluster.cluster.title
                color: rootExposeWorkspaceCluster.theme.modules.expose.primaryTextColor
                font.pixelSize: rootExposeWorkspaceCluster.theme.modules.expose.clusterTitlePixelSize
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                id: countLabel

                text: "(" + rootExposeWorkspaceCluster.cluster.clients.length + ")"
                color: rootExposeWorkspaceCluster.theme.modules.expose.secondaryTextColor
                font.pixelSize: rootExposeWorkspaceCluster.theme.modules.expose.clusterCountPixelSize
            }
        }

        Flow {
            id: miniFlow

            width: parent.width
            spacing: 10

            Repeater {
                id: miniRepeater

                model: rootExposeWorkspaceCluster.cluster.clients.slice(0, rootExposeWorkspaceCluster.theme.modules.expose.maxClusterClients)

                ExposeClientCard {
                    required property var modelData

                    theme: rootExposeWorkspaceCluster.theme
                    client: modelData
                    compact: true
                    selected: modelData.address === rootExposeWorkspaceCluster.selectedAddress

                    onSelectedRequested: card => rootExposeWorkspaceCluster.selectedRequested(card)
                    onActivated: client => rootExposeWorkspaceCluster.activated(client)
                }
            }
        }
    }
}
