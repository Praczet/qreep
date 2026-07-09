import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootExposePanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    property bool presented: false
    readonly property bool searchVisible: searchInput.activeFocus || service.searchQuery.length > 0
    readonly property int overviewItemCount: service.currentClients.length + service.workspaceClusters.length
    readonly property int maxColumnsByWidth: Math.max(1, Math.floor((width - theme.modules.expose.panelMargin * 2 + theme.modules.expose.cardGap) / (theme.modules.expose.currentCardWidth + theme.modules.expose.cardGap)))
    readonly property int gridColumns: Math.max(1, Math.min(theme.modules.expose.gridMaxColumns, overviewItemCount, maxColumnsByWidth))
    readonly property int gridRows: overviewItemCount > 0 ? Math.ceil(overviewItemCount / gridColumns) : 1
    readonly property point gatherPoint: Qt.point(width / 2, height / 2)

    signal closeRequested
    signal activateRequested(var client)

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
        service.clearSearch();
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: rootExposePanel.handleEscape()
    }

    Shortcut {
        sequence: "Return"
        context: Qt.WindowShortcut
        onActivated: rootExposePanel.activateSelected()
    }

    Shortcut {
        sequence: "Enter"
        context: Qt.WindowShortcut
        onActivated: rootExposePanel.activateSelected()
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

    Connections {
        target: rootExposePanel.service

        function onSearchQueryChanged() {
            if (searchInput.text !== rootExposePanel.service.searchQuery)
                searchInput.text = rootExposePanel.service.searchQuery;
        }
    }

    Rectangle {
        id: background

        anchors.fill: parent
        color: "transparent"
        focus: true
        Keys.priority: Keys.BeforeItem

        Keys.onPressed: event => {
            rootExposePanel.handlePanelKey(event);
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

        Item {
            id: overviewLayout

            anchors.centerIn: parent
            width: rootExposePanel.overviewLayoutWidth()
            height: rootExposePanel.overviewLayoutHeight()

            Repeater {
                id: currentRepeater

                model: rootExposePanel.service.currentClients

                ExposeClientCard {
                    required property var modelData
                    required property int index

                    theme: rootExposePanel.theme
                    client: modelData
                    selected: modelData.address === rootExposePanel.service.selectedAddress
                    x: rootExposePanel.tileX(index)
                    y: rootExposePanel.tileY(index)
                    entrancePresented: rootExposePanel.presented
                    entranceIndex: index
                    entranceGatherPoint: rootExposePanel.gatherPoint

                    onSelectedRequested: card => rootExposePanel.service.selectAddress(card.client.address)
                    onActivated: client => rootExposePanel.activateRequested(client)
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
                    x: rootExposePanel.tileX(rootExposePanel.service.currentClients.length + index)
                    y: rootExposePanel.tileY(rootExposePanel.service.currentClients.length + index)
                    entrancePresented: rootExposePanel.presented
                    entranceIndex: rootExposePanel.service.currentClients.length + index
                    entranceGatherPoint: rootExposePanel.gatherPoint

                    onSelectedRequested: card => rootExposePanel.service.selectAddress(card.client.address)
                    onActivated: client => rootExposePanel.activateRequested(client)
                }
            }
        }

        Rectangle {
            id: searchBox

            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }
            width: Math.min(parent.width, rootExposePanel.theme.modules.expose.searchWidth)
            height: rootExposePanel.theme.modules.expose.searchHeight
            radius: rootExposePanel.theme.modules.expose.cardRadius
            color: rootExposePanel.theme.modules.expose.searchColor
            border.width: rootExposePanel.theme.modules.expose.borderWidth
            border.color: searchInput.activeFocus ? rootExposePanel.theme.modules.expose.selectedBorderColor : rootExposePanel.theme.modules.expose.borderColor
            opacity: rootExposePanel.searchVisible ? 1 : 0
            y: rootExposePanel.searchVisible ? 0 : -10
            visible: rootExposePanel.searchVisible || opacity > 0

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

            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: 14
                }
                visible: searchInput.text.length === 0
                text: "Search windows"
                color: rootExposePanel.theme.modules.expose.secondaryTextColor
                font.pixelSize: rootExposePanel.theme.modules.expose.subtitlePixelSize
                elide: Text.ElideRight
            }

            TextInput {
                id: searchInput

                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: 14
                }
                text: rootExposePanel.service.searchQuery
                color: rootExposePanel.theme.modules.expose.primaryTextColor
                selectedTextColor: rootExposePanel.theme.modules.expose.badgeTextColor
                selectionColor: rootExposePanel.theme.modules.expose.accentColor
                font.pixelSize: rootExposePanel.theme.modules.expose.titlePixelSize
                clip: true
                Keys.priority: Keys.BeforeItem

                onTextChanged: {
                    if (rootExposePanel.service.searchQuery !== text)
                        rootExposePanel.service.setSearchQuery(text);
                }

                Keys.onPressed: event => rootExposePanel.handlePanelKey(event)
            }
        }

        Text {
            visible: rootExposePanel.service.searchQuery.length > 0 && rootExposePanel.overviewItemCount === 0
            anchors.centerIn: parent
            text: "No matching windows"
            color: rootExposePanel.theme.modules.expose.secondaryTextColor
            font.pixelSize: rootExposePanel.theme.modules.expose.titlePixelSize
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

    function activateSelected() {
        const entries = navigationEntries();

        if (entries.length === 0)
            return;

        for (let index = 0; index < entries.length; index++) {
            const entry = entries[index];

            if (entryContainsAddress(entry, service.selectedAddress)) {
                activateEntry(entry);
                return;
            }
        }

        activateEntry(entries[0]);
    }

    function activateEntry(entry) {
        if (!entry || !entry.item)
            return;

        if (entry.cluster) {
            const clusterClient = entry.item.selectedClient();

            if (clusterClient) {
                activateRequested(clusterClient);
                return;
            }
        }

        if (entry.item.client)
            activateRequested(entry.item.client);
    }

    function overviewLayoutWidth() {
        const gap = theme.modules.expose.cardGap;
        const cardWidth = theme.modules.expose.currentCardWidth;

        return Math.min(overview.width, gridColumns * cardWidth + Math.max(0, gridColumns - 1) * gap);
    }

    function overviewLayoutHeight() {
        const gap = theme.modules.expose.cardGap;
        const cardHeight = theme.modules.expose.currentCardHeight;

        return Math.min(overview.height, gridRows * cardHeight + Math.max(0, gridRows - 1) * gap);
    }

    function tileX(index) {
        const column = index % gridColumns;

        return column * (theme.modules.expose.currentCardWidth + theme.modules.expose.cardGap);
    }

    function tileY(index) {
        const row = Math.floor(index / gridColumns);

        return row * (theme.modules.expose.currentCardHeight + theme.modules.expose.cardGap);
    }

    function showSearch(initialText) {
        searchInput.forceActiveFocus();

        if (initialText && initialText.length > 0)
            searchInput.insert(searchInput.cursorPosition, initialText);

        searchInput.cursorPosition = searchInput.text.length;
    }

    function hideSearch() {
        background.forceActiveFocus();
    }

    function handleEscape() {
        if (searchInput.activeFocus) {
            hideSearch();
            return;
        }

        if (service.searchQuery.length > 0) {
            service.clearSearch();
            background.forceActiveFocus();
            return;
        }

        closeRequested();
    }

    function handlePanelKey(event) {
        if (event.key === Qt.Key_Escape) {
            handleEscape();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activateSelected();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Left) {
            selectSpatial("left");
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Right) {
            selectSpatial("right");
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Up) {
            selectSpatial("up");
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Down) {
            selectSpatial("down");
            event.accepted = true;
            return;
        }

        if ((event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) !== 0)
            return;

        if (event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
            showSearch(event.text);
            event.accepted = true;
        }
    }
}
