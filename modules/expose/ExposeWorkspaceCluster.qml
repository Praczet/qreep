import QtQuick

Rectangle {
    id: rootExposeWorkspaceCluster

    required property QtObject theme
    required property var cluster
    required property string selectedAddress

    signal selectedRequested(var card)
    signal activated(var client)

    width: theme.modules.expose.clusterWidth
    height: Math.max(theme.modules.expose.clusterMinHeight, clusterLayout.implicitHeight + theme.modules.expose.panelPadding)
    radius: theme.modules.expose.cardRadius
    color: theme.modules.expose.cardColor
    border.width: theme.modules.expose.borderWidth
    border.color: theme.modules.expose.borderColor

    function selectableCards() {
        const cards = [];

        for (let index = 0; index < miniRepeater.count; index++) {
            const item = miniRepeater.itemAt(index);

            if (item)
                cards.push(item);
        }

        return cards;
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
