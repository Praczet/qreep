import QtQuick
import Quickshell
import Quickshell.Wayland
import "OrbitLayout.js" as OrbitLayout

// Orbit overlay: dimmed screen, the current node in the middle, its items on a
// ring around it, and its parent as a faint dot. Every node of the tree keeps
// one circle; OrbitLayout.scene() says where each belongs and the circles
// animate there on their own.
PanelWindow {
    id: rootOrbitPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    readonly property QtObject ot: theme.modules.orbit
    property bool presented: false
    // False while a node travels to the middle; its children wait inside it.
    property bool bloomed: false
    readonly property string currentId: service.current ? service.current.id : ""
    readonly property var nodeIds: service.nodes.map(node => node.id)
    // The live circles, by node index, so the links can follow them.
    property var nodeItems: []

    readonly property var ringLayout: OrbitLayout.ring(service.items.length, {
        radius: ot.ringRadius,
        nodeSize: ot.nodeSize,
        minNodeSize: ot.minNodeSize,
        gap: ot.nodeGap,
        maxRadius: Math.max(ot.centerSize, Math.min(width, height) / 2 - ot.screenMargin - ot.nodeSize / 2)
    })

    readonly property var scene: OrbitLayout.scene(nodeIds, currentId, ringLayout, {
        presented: presented,
        bloomed: bloomed,
        centerSize: ot.centerSize,
        parentSlots: ot.parentSlots,
        staggerDelay: ot.staggerDelay,
        maxStagger: ot.maxStagger
    })

    signal closeRequested

    onCurrentIdChanged: restartBloom()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "qreep-orbit"
    WlrLayershell.layer: WlrLayer.Overlay
    // Let go of the keyboard when closing starts, so what Orbit launched gets it.
    WlrLayershell.keyboardFocus: panelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Component.onCompleted: {
        keys.forceActiveFocus();
        if (panelOpen)
            enterTimer.restart();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            keys.forceActiveFocus();
            enterTimer.restart();
            return;
        }
        enterTimer.stop();
        bloomTimer.stop();
        presented = false;
        bloomed = false;
    }

    function setNodeItem(index, item) {
        const items = nodeItems.slice();

        items[index] = item;
        nodeItems = items;
    }

    function restartBloom() {
        bloomed = false;
        if (presented)
            bloomTimer.restart();
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: {
            rootOrbitPanel.presented = true;
            rootOrbitPanel.restartBloom();
        }
    }

    Timer {
        id: bloomTimer

        interval: rootOrbitPanel.ot.bloomDelay
        repeat: false
        onTriggered: rootOrbitPanel.bloomed = true
    }

    Rectangle {
        anchors.fill: parent
        color: rootOrbitPanel.ot.overlayColor
        opacity: rootOrbitPanel.presented ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: rootOrbitPanel.ot.animationDuration
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rootOrbitPanel.closeRequested()
    }

    Item {
        id: keys

        anchors.fill: parent
        focus: true

        Keys.onPressed: event => rootOrbitPanel.handleKey(event)

        Repeater {
            model: rootOrbitPanel.service.nodes

            OrbitLink {
                required property var modelData
                required property int index

                readonly property int parentIndex: rootOrbitPanel.nodeIds.indexOf(OrbitLayout.parentOf(modelData.id))

                ot: rootOrbitPanel.ot
                childNode: rootOrbitPanel.nodeItems[index] || null
                parentNode: parentIndex >= 0 ? rootOrbitPanel.nodeItems[parentIndex] || null : null
                originX: keys.width / 2
                originY: keys.height / 2
            }
        }

        Repeater {
            model: rootOrbitPanel.service.nodes
            onItemAdded: (index, item) => rootOrbitPanel.setNodeItem(index, item)
            onItemRemoved: index => rootOrbitPanel.setNodeItem(index, null)

            OrbitNode {
                required property var modelData

                readonly property int ringIndex: entry ? entry.ringIndex : -1

                ot: rootOrbitPanel.ot
                entry: rootOrbitPanel.scene[modelData.id] || null
                originX: keys.width / 2
                originY: keys.height / 2
                text: modelData.text
                iconSource: modelData.iconSource
                hint: modelData.key || modelData.text.toLowerCase()
                pinnedKey: modelData.key.length > 0
                selected: ringIndex >= 0 && ringIndex === rootOrbitPanel.service.selectedIndex
                dimmed: ringIndex >= 0 && rootOrbitPanel.service.isDimmed(ringIndex)

                onClicked: {
                    if (ringIndex >= 0)
                        rootOrbitPanel.service.activate(ringIndex);
                    else if (entry.parentLevel > 0)
                        rootOrbitPanel.service.goUpLevels(entry.parentLevel);
                    else if (!rootOrbitPanel.service.goUp())
                        rootOrbitPanel.closeRequested();
                }
            }
        }

        // The backing keeps a line running straight down out of the text.
        Rectangle {
            anchors.centerIn: caption
            width: Math.min(caption.width, Math.max(captionTitle.implicitWidth, captionDetail.implicitWidth)) + 2 * rootOrbitPanel.ot.captionPadding
            height: caption.height + rootOrbitPanel.ot.captionPadding
            radius: rootOrbitPanel.ot.captionPadding
            color: rootOrbitPanel.ot.captionColor
            opacity: caption.opacity
        }

        Column {
            id: caption

            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 + rootOrbitPanel.ot.centerSize / 2 + rootOrbitPanel.ot.captionOffset
            opacity: rootOrbitPanel.bloomed || rootOrbitPanel.service.problem.length > 0 ? 1 : 0
            width: rootOrbitPanel.ot.captionWidth
            spacing: 2

            Behavior on opacity {
                NumberAnimation {
                    duration: rootOrbitPanel.ot.selectDuration
                }
            }

            Text {
                id: captionTitle

                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: rootOrbitPanel.captionName()
                color: rootOrbitPanel.ot.textColor
                font.pixelSize: rootOrbitPanel.ot.captionPixelSize
                font.bold: true
            }

            Text {
                id: captionDetail

                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: rootOrbitPanel.service.problem.length > 0 ? Text.Wrap : Text.NoWrap
                elide: rootOrbitPanel.service.problem.length > 0 ? Text.ElideNone : Text.ElideRight
                text: rootOrbitPanel.service.problem.length > 0 ? rootOrbitPanel.service.problem : rootOrbitPanel.service.detailOf(rootOrbitPanel.service.selectedNode)
                color: rootOrbitPanel.service.problem.length > 0 ? rootOrbitPanel.ot.errorColor : rootOrbitPanel.ot.detailColor
                font.pixelSize: rootOrbitPanel.ot.detailPixelSize
            }
        }
    }

    function captionName() {
        if (service.selectedNode)
            return service.selectedNode.name;
        return service.current ? service.current.name : "";
    }

    function handleKey(event) {
        const service = rootOrbitPanel.service;

        event.accepted = true;
        switch (event.key) {
        case Qt.Key_Escape:
            if (event.modifiers & Qt.ControlModifier)
                closeRequested();
            else if (!service.clearTyped() && !service.goUp())
                closeRequested();
            return;
        case Qt.Key_Backspace:
            if (!service.clearTyped())
                service.goUp();
            return;
        case Qt.Key_Tab:
            service.cycle(1);
            return;
        case Qt.Key_Backtab:
            service.cycle(-1);
            return;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            service.activate(service.selectedIndex);
            return;
        }

        const blocked = Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier;
        const letter = String(event.text || "").toLowerCase();

        if ((event.modifiers & blocked) === 0 && letter.length === 1 && letter.trim().length === 1)
            service.typeLetter(letter);
        else
            event.accepted = false;
    }
}
