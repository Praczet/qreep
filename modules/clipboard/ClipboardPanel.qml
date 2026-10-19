import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootClipboardPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    property bool presented: false
    // F1 sheet. Esc closes it before it closes the panel.
    property bool shortcutsOpen: false
    // Ctrl+1 … Ctrl+5, in the order of the header buttons.
    readonly property var filterKeys: ["pins", "image", "text", "code", "color"]
    readonly property var shortcuts: [
        { keys: "type", action: "Search" },
        { keys: "↑ ↓ ← →", action: "Move (↑ from the top row: search)" },
        { keys: "Enter", action: "Copy it back to the clipboard" },
        { keys: "Ctrl+S  Alt+S", action: "Pin / unpin" },
        { keys: "Shift+Delete", action: "Delete (a pin: unpin)" },
        { keys: "Ctrl+1", action: "Pins only" },
        { keys: "Ctrl+2 … Ctrl+5", action: "Images, text, code, colors" },
        { keys: "F1", action: "This sheet" },
        { keys: "Esc", action: "Close sheet, close" }
    ]

    signal closeRequested
    signal restoreRequested(int index)

    implicitWidth: screen.width
    implicitHeight: screen.height

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.namespace: "qreep-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        searchInput.forceActiveFocus();
        if (panelOpen)
            enterTimer.restart();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            searchInput.forceActiveFocus();
            enterTimer.restart();
            return;
        }

        enterTimer.stop();
        presented = false;
        shortcutsOpen = false;
    }

    function toggleFilter(key) {
        if (key === "pins")
            service.starredOnly = !service.starredOnly;
        else
            service.toggleTypeFilter(key);
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: {
            if (rootClipboardPanel.shortcutsOpen)
                rootClipboardPanel.shortcutsOpen = false;
            else
                rootClipboardPanel.closeRequested();
        }
    }

    Shortcut {
        sequence: "F1"
        context: Qt.WindowShortcut
        onActivated: rootClipboardPanel.shortcutsOpen = !rootClipboardPanel.shortcutsOpen
    }

    Repeater {
        model: rootClipboardPanel.filterKeys

        Item {
            required property string modelData
            required property int index

            Shortcut {
                sequence: "Ctrl+" + (index + 1)
                context: Qt.WindowShortcut
                onActivated: rootClipboardPanel.toggleFilter(modelData)
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+S"
        context: Qt.WindowShortcut
        onActivated: rootClipboardPanel.service.toggleStar(rootClipboardPanel.service.selectedIndex)
    }

    Shortcut {
        sequence: "Alt+S"
        context: Qt.WindowShortcut
        onActivated: rootClipboardPanel.service.toggleStar(rootClipboardPanel.service.selectedIndex)
    }

    Shortcut {
        sequence: "Shift+Delete"
        context: Qt.WindowShortcut
        onActivated: rootClipboardPanel.service.deleteEntry(rootClipboardPanel.service.selectedIndex)
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: presented = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rootClipboardPanel.closeRequested()
    }

    Rectangle {
        id: panel

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: rootClipboardPanel.theme.modules.clipboard.panelMargin
        }
        height: rootClipboardPanel.theme.modules.clipboard.panelHeight
        radius: rootClipboardPanel.theme.modules.clipboard.cardRadius
        color: rootClipboardPanel.theme.modules.clipboard.panelColor
        border.width: 1
        border.color: rootClipboardPanel.theme.modules.clipboard.borderColor
        opacity: rootClipboardPanel.presented ? 1 : 0
        y: rootClipboardPanel.presented ? 0 : 26
        clip: true

        Behavior on opacity {
            NumberAnimation {
                duration: rootClipboardPanel.theme.modules.clipboard.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: rootClipboardPanel.theme.modules.clipboard.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Item {
            id: header

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: rootClipboardPanel.theme.modules.clipboard.panelPadding
            }
            height: rootClipboardPanel.theme.modules.clipboard.headerHeight

            property int pinButtonWidth: 72
            property int typeButtonCount: 4
            property int typeGroupWidth: typeButtonCount * rootClipboardPanel.theme.modules.clipboard.typeFilterWidth + (typeButtonCount - 1) * typeFilters.spacing

            Row {
                id: headerControls

                anchors.centerIn: parent
                height: parent.height
                spacing: 8

                Rectangle {
                    width: rootClipboardPanel.theme.modules.clipboard.searchWidth
                    height: parent.height
                    radius: 6
                    color: rootClipboardPanel.theme.modules.clipboard.searchColor
                    border.width: 1
                    border.color: searchInput.activeFocus ? rootClipboardPanel.theme.modules.clipboard.selectedBorderColor : rootClipboardPanel.theme.modules.clipboard.borderColor

                    TextInput {
                        id: searchInput

                        anchors {
                            fill: parent
                            leftMargin: 9
                            rightMargin: 9
                        }
                        text: rootClipboardPanel.service.searchText
                        color: rootClipboardPanel.theme.modules.clipboard.primaryTextColor
                        selectionColor: rootClipboardPanel.theme.modules.clipboard.accentColor
                        selectedTextColor: rootClipboardPanel.theme.modules.clipboard.panelColor
                        font.pixelSize: rootClipboardPanel.theme.modules.clipboard.bodyPixelSize
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true

                        onTextEdited: rootClipboardPanel.service.searchText = text

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                grid.forceActiveFocus();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                rootClipboardPanel.restoreRequested(rootClipboardPanel.service.selectedIndex);
                                event.accepted = true;
                            }
                        }
                    }
                }

                Rectangle {
                    width: header.pinButtonWidth
                    height: parent.height
                    radius: 6
                    color: rootClipboardPanel.service.starredOnly ? rootClipboardPanel.theme.modules.clipboard.selectedCardColor : rootClipboardPanel.theme.modules.clipboard.searchColor
                    border.width: 1
                    border.color: rootClipboardPanel.service.starredOnly ? rootClipboardPanel.theme.modules.clipboard.selectedBorderColor : rootClipboardPanel.theme.modules.clipboard.borderColor

                    Text {
                        anchors.centerIn: parent
                        text: "󰐃 pins"
                        color: rootClipboardPanel.theme.modules.clipboard.primaryTextColor
                        font.pixelSize: rootClipboardPanel.theme.modules.clipboard.bodyPixelSize
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: rootClipboardPanel.service.starredOnly = !rootClipboardPanel.service.starredOnly
                    }
                }

                Row {
                    id: typeFilters

                    width: header.typeGroupWidth
                    height: parent.height
                    spacing: 6

                    Repeater {
                        model: [
                            {
                                "key": "image",
                                "label": "image"
                            },
                            {
                                "key": "text",
                                "label": "text"
                            },
                            {
                                "key": "code",
                                "label": "code"
                            },
                            {
                                "key": "color",
                                "label": "color"
                            }
                        ]

                        Rectangle {
                            required property var modelData

                            width: rootClipboardPanel.theme.modules.clipboard.typeFilterWidth
                            height: typeFilters.height
                            radius: 6
                            color: rootClipboardPanel.service.typeFilterActive(modelData.key) ? rootClipboardPanel.theme.modules.clipboard.selectedCardColor : rootClipboardPanel.theme.modules.clipboard.searchColor
                            border.width: 1
                            border.color: rootClipboardPanel.service.typeFilterActive(modelData.key) ? rootClipboardPanel.theme.modules.clipboard.selectedBorderColor : rootClipboardPanel.theme.modules.clipboard.borderColor

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: rootClipboardPanel.theme.modules.clipboard.primaryTextColor
                                font.pixelSize: rootClipboardPanel.theme.modules.clipboard.bodyPixelSize
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: rootClipboardPanel.service.toggleTypeFilter(modelData.key)
                            }
                        }
                    }
                }
            }

            Text {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                width: 96
                height: parent.height
                text: statusText()
                color: rootClipboardPanel.theme.modules.clipboard.secondaryTextColor
                font.pixelSize: rootClipboardPanel.theme.modules.clipboard.metaPixelSize
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
            }
        }

        GridView {
            id: grid

            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                bottom: parent.bottom
                leftMargin: rootClipboardPanel.theme.modules.clipboard.panelPadding
                rightMargin: rootClipboardPanel.theme.modules.clipboard.panelPadding
                topMargin: rootClipboardPanel.theme.modules.clipboard.cardGap
                bottomMargin: rootClipboardPanel.theme.modules.clipboard.panelPadding
            }
            model: rootClipboardPanel.service.filteredEntries
            // Extra room for selected-card scale and shadow.
            cellWidth: rootClipboardPanel.theme.modules.clipboard.cardWidth + rootClipboardPanel.theme.modules.clipboard.cardGap + 24
            cellHeight: rootClipboardPanel.theme.modules.clipboard.cardHeight + rootClipboardPanel.theme.modules.clipboard.cardGap + 24
            currentIndex: rootClipboardPanel.service.selectedIndex
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            onCurrentIndexChanged: rootClipboardPanel.service.setSelection(currentIndex)

            delegate: Item {
                required property var modelData
                required property int index
                readonly property int imagePreviewRevision: rootClipboardPanel.service.imagePreviewRevision

                width: grid.cellWidth
                height: grid.cellHeight
                z: rootClipboardPanel.service.selectedIndex === index ? 20 : 0

                ClipboardCard {
                    id: card

                    anchors.centerIn: parent

                    theme: rootClipboardPanel.theme
                    entry: modelData
                    imageSource: rootClipboardPanel.service.imagePreviewSource(modelData.id, imagePreviewRevision)
                    selected: rootClipboardPanel.service.selectedIndex === index

                    onClicked: {
                        rootClipboardPanel.service.setSelection(index);
                        rootClipboardPanel.restoreRequested(index);
                    }

                    onStarRequested: {
                        rootClipboardPanel.service.setSelection(index);
                        rootClipboardPanel.service.toggleStar(index);
                    }

                    onDeleteRequested: {
                        rootClipboardPanel.service.setSelection(index);
                        rootClipboardPanel.service.deleteEntry(index);
                    }
                }
            }

            Keys.onPressed: event => {
                const columns = Math.max(1, Math.floor(width / cellWidth));

                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    rootClipboardPanel.restoreRequested(rootClipboardPanel.service.selectedIndex);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                    rootClipboardPanel.service.moveSelection(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right) {
                    rootClipboardPanel.service.moveSelection(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    if (rootClipboardPanel.service.selectedIndex < columns)
                        searchInput.forceActiveFocus();
                    else
                        rootClipboardPanel.service.moveSelection(-1, columns);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    rootClipboardPanel.service.moveSelection(1, columns);
                    event.accepted = true;
                } else if (event.text && event.text.length === 1 && event.text >= " ") {
                    searchInput.forceActiveFocus();
                    searchInput.insert(searchInput.cursorPosition, event.text);
                    rootClipboardPanel.service.searchText = searchInput.text;
                    event.accepted = true;
                }
            }
        }
    }

    // --- F1 shortcuts sheet, above the panel (the strip is too low for it) ---
    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: panel.top
            bottomMargin: 12
        }
        width: 480
        height: sheet.implicitHeight + 32
        visible: opacity > 0.01
        opacity: rootClipboardPanel.shortcutsOpen ? 1 : 0
        radius: rootClipboardPanel.theme.modules.clipboard.cardRadius
        color: rootClipboardPanel.theme.modules.clipboard.sheetColor
        border.width: 1
        border.color: rootClipboardPanel.theme.modules.clipboard.selectedBorderColor

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: rootClipboardPanel.shortcutsOpen = false
        }

        Column {
            id: sheet

            anchors {
                fill: parent
                margins: 16
            }
            spacing: 8

            Text {
                bottomPadding: 6
                text: "Shortcuts"
                color: rootClipboardPanel.theme.modules.clipboard.accentColor
                font.pixelSize: rootClipboardPanel.theme.modules.clipboard.bodyPixelSize
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
            }

            Repeater {
                model: rootClipboardPanel.shortcuts

                Row {
                    required property var modelData

                    spacing: 16

                    Rectangle {
                        width: 140
                        height: 24
                        radius: 6
                        color: rootClipboardPanel.theme.modules.clipboard.searchColor

                        Text {
                            anchors.centerIn: parent
                            text: modelData.keys
                            color: rootClipboardPanel.theme.modules.clipboard.accentColor
                            font.family: rootClipboardPanel.theme.iconFontFamily
                            font.pixelSize: rootClipboardPanel.theme.modules.clipboard.bodyPixelSize
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.action
                        color: rootClipboardPanel.theme.modules.clipboard.primaryTextColor
                        font.pixelSize: rootClipboardPanel.theme.modules.clipboard.bodyPixelSize + 1
                    }
                }
            }
        }
    }

    function statusText() {
        if (rootClipboardPanel.service.error.length > 0)
            return rootClipboardPanel.service.error;

        if (rootClipboardPanel.service.loading)
            return "loading";

        return rootClipboardPanel.service.filteredEntries.length + " / " + rootClipboardPanel.service.entries.length;
    }
}
