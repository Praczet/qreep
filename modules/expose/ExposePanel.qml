import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootExposePanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    property bool presented: false

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

    Row {
        id: overview

        anchors {
            fill: parent
            margins: rootExposePanel.theme.modules.expose.panelMargin
        }
        spacing: rootExposePanel.theme.modules.expose.sectionGap
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

        Flow {
            id: currentFlow

            width: Math.max(1, parent.width - otherScroller.width - parent.spacing)
            height: parent.height
            spacing: rootExposePanel.theme.modules.expose.cardGap

            Repeater {
                id: currentRepeater

                model: rootExposePanel.service.currentClients

                ExposeClientCard {
                    required property var modelData

                    theme: rootExposePanel.theme
                    client: modelData
                    selected: modelData.address === rootExposePanel.service.selectedAddress

                    onSelectedRequested: card => rootExposePanel.service.selectAddress(card.client.address)
                    onActivated: client => rootExposePanel.service.focusClient(client)
                }
            }
        }

        Flickable {
            id: otherScroller

            width: Math.min(rootExposePanel.theme.modules.expose.clusterWidth, parent.width * 0.34)
            height: parent.height
            contentWidth: width
            contentHeight: clusterColumn.implicitHeight
            clip: true

            Column {
                id: clusterColumn

                width: otherScroller.width
                spacing: rootExposePanel.theme.modules.expose.cardGap

                Repeater {
                    id: clusterRepeater

                    model: rootExposePanel.service.workspaceClusters

                    ExposeWorkspaceCluster {
                        required property var modelData

                        theme: rootExposePanel.theme
                        cluster: modelData
                        selectedAddress: rootExposePanel.service.selectedAddress

                        onSelectedRequested: card => rootExposePanel.service.selectAddress(card.client.address)
                        onActivated: client => rootExposePanel.service.focusClient(client)
                    }
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
        const cards = selectableCards();

        if (cards.length === 0)
            return;

        let current = null;

        for (let index = 0; index < cards.length; index++) {
            if (cards[index].client.address === service.selectedAddress) {
                current = cards[index];
                break;
            }
        }

        if (!current) {
            service.selectAddress(cards[0].client.address);
            return;
        }

        const currentCenter = cardCenter(current);
        let best = null;
        let bestScore = Number.POSITIVE_INFINITY;

        for (let index = 0; index < cards.length; index++) {
            const candidate = cards[index];

            if (candidate === current)
                continue;

            const center = cardCenter(candidate);
            const dx = center.x - currentCenter.x;
            const dy = center.y - currentCenter.y;

            if (!isInDirection(direction, dx, dy))
                continue;

            const primary = direction === "left" || direction === "right" ? Math.abs(dx) : Math.abs(dy);
            const secondary = direction === "left" || direction === "right" ? Math.abs(dy) : Math.abs(dx);
            const score = primary * 1000 + secondary;

            if (score < bestScore) {
                bestScore = score;
                best = candidate;
            }
        }

        if (best)
            service.selectAddress(best.client.address);
    }

    function selectableCards() {
        let cards = [];

        for (let index = 0; index < currentRepeater.count; index++) {
            const item = currentRepeater.itemAt(index);

            if (item)
                cards.push(item);
        }

        for (let index = 0; index < clusterRepeater.count; index++) {
            const cluster = clusterRepeater.itemAt(index);

            if (cluster)
                cards = cards.concat(cluster.selectableCards());
        }

        return cards;
    }

    function cardCenter(card) {
        const point = card.mapToGlobal(Qt.point(card.width / 2, card.height / 2));

        return Qt.point(point.x, point.y);
    }

    function isInDirection(direction, dx, dy) {
        switch (direction) {
        case "left":
            return dx < -1;
        case "right":
            return dx > 1;
        case "up":
            return dy < -1;
        case "down":
            return dy > 1;
        default:
            return false;
        }
    }
}
