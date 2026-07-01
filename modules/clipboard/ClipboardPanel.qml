import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootClipboardPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    property bool presented: false

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
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: rootClipboardPanel.closeRequested()
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

        Row {
            id: header

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                margins: rootClipboardPanel.theme.modules.clipboard.panelPadding
            }
            height: rootClipboardPanel.theme.modules.clipboard.headerHeight
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
                width: 72
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

            Text {
                width: parent.width - rootClipboardPanel.theme.modules.clipboard.searchWidth - 72 - parent.spacing * 2
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

                width: grid.cellWidth
                height: grid.cellHeight
                z: rootClipboardPanel.service.selectedIndex === index ? 20 : 0

                ClipboardCard {
                    id: card

                    anchors.centerIn: parent

                    theme: rootClipboardPanel.theme
                    entry: modelData
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

    function statusText() {
        if (rootClipboardPanel.service.error.length > 0)
            return rootClipboardPanel.service.error;

        if (rootClipboardPanel.service.loading)
            return "loading";

        return rootClipboardPanel.service.filteredEntries.length + " / " + rootClipboardPanel.service.entries.length;
    }
}
