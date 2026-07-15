import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootFastPasswordPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    property bool presented: false

    signal closeRequested
    signal copyRequested(int index)

    implicitWidth: screen.width
    implicitHeight: screen.height

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.namespace: "qreep-fast-password"
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
        onActivated: rootFastPasswordPanel.closeRequested()
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: presented = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rootFastPasswordPanel.closeRequested()
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent
        width: Math.min(rootFastPasswordPanel.theme.modules.fastPassword.panelWidth, parent.width - rootFastPasswordPanel.theme.modules.fastPassword.screenMargin * 2)
        height: Math.min(rootFastPasswordPanel.theme.modules.fastPassword.panelHeight, parent.height - rootFastPasswordPanel.theme.modules.fastPassword.screenMargin * 2)
        radius: rootFastPasswordPanel.theme.modules.fastPassword.panelRadius
        color: rootFastPasswordPanel.theme.modules.fastPassword.panelColor
        border.width: 1
        border.color: rootFastPasswordPanel.theme.modules.fastPassword.borderColor
        opacity: rootFastPasswordPanel.presented ? 1 : 0
        scale: rootFastPasswordPanel.presented ? 1 : 0.98
        clip: true

        Behavior on opacity {
            NumberAnimation {
                duration: rootFastPasswordPanel.theme.modules.fastPassword.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: rootFastPasswordPanel.theme.modules.fastPassword.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Column {
            anchors.fill: parent
            anchors.margins: rootFastPasswordPanel.theme.modules.fastPassword.panelPadding
            spacing: rootFastPasswordPanel.theme.modules.fastPassword.contentGap

            Row {
                width: parent.width
                height: rootFastPasswordPanel.theme.modules.fastPassword.headerHeight
                spacing: rootFastPasswordPanel.theme.modules.fastPassword.contentGap

                Rectangle {
                    width: rootFastPasswordPanel.theme.modules.fastPassword.iconBoxSize
                    height: rootFastPasswordPanel.theme.modules.fastPassword.iconBoxSize
                    radius: rootFastPasswordPanel.theme.modules.fastPassword.controlRadius
                    color: rootFastPasswordPanel.theme.modules.fastPassword.controlColor
                    border.width: 1
                    border.color: rootFastPasswordPanel.theme.modules.fastPassword.borderColor

                    Text {
                        anchors.centerIn: parent
                        text: "󰌾"
                        color: rootFastPasswordPanel.theme.modules.fastPassword.accentColor
                        font.family: rootFastPasswordPanel.theme.iconFontFamily
                        font.pixelSize: rootFastPasswordPanel.theme.modules.fastPassword.titleIconPixelSize
                    }
                }

                Column {
                    width: parent.width - rootFastPasswordPanel.theme.modules.fastPassword.iconBoxSize - statusText.width - parent.spacing * 2
                    height: parent.height
                    spacing: 2

                    Text {
                        width: parent.width
                        text: "Fast Password"
                        color: rootFastPasswordPanel.theme.modules.fastPassword.primaryTextColor
                        font.pixelSize: rootFastPasswordPanel.theme.modules.fastPassword.titlePixelSize
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: "Polkit-gated copy"
                        color: rootFastPasswordPanel.theme.modules.fastPassword.secondaryTextColor
                        font.pixelSize: rootFastPasswordPanel.theme.modules.fastPassword.metaPixelSize
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: statusText

                    width: rootFastPasswordPanel.theme.modules.fastPassword.statusWidth
                    height: parent.height
                    text: rootFastPasswordPanel.statusText()
                    color: rootFastPasswordPanel.service.error.length > 0 ? rootFastPasswordPanel.theme.modules.fastPassword.errorColor : rootFastPasswordPanel.theme.modules.fastPassword.secondaryTextColor
                    font.pixelSize: rootFastPasswordPanel.theme.modules.fastPassword.metaPixelSize
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }

            Rectangle {
                width: parent.width
                height: rootFastPasswordPanel.theme.modules.fastPassword.searchHeight
                radius: rootFastPasswordPanel.theme.modules.fastPassword.controlRadius
                color: rootFastPasswordPanel.theme.modules.fastPassword.controlColor
                border.width: 1
                border.color: searchInput.activeFocus ? rootFastPasswordPanel.theme.modules.fastPassword.focusBorderColor : rootFastPasswordPanel.theme.modules.fastPassword.borderColor

                TextInput {
                    id: searchInput

                    anchors.fill: parent
                    anchors.leftMargin: rootFastPasswordPanel.theme.modules.fastPassword.searchPadding
                    anchors.rightMargin: rootFastPasswordPanel.theme.modules.fastPassword.searchPadding
                    text: rootFastPasswordPanel.service.searchText
                    color: rootFastPasswordPanel.theme.modules.fastPassword.primaryTextColor
                    selectionColor: rootFastPasswordPanel.theme.modules.fastPassword.accentColor
                    selectedTextColor: rootFastPasswordPanel.theme.modules.fastPassword.panelColor
                    font.pixelSize: rootFastPasswordPanel.theme.modules.fastPassword.bodyPixelSize
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true

                    onTextEdited: rootFastPasswordPanel.service.searchText = text

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            list.forceActiveFocus();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            rootFastPasswordPanel.copyRequested(rootFastPasswordPanel.service.selectedIndex);
                            event.accepted = true;
                        }
                    }
                }
            }

            ListView {
                id: list

                width: parent.width
                height: parent.height - rootFastPasswordPanel.theme.modules.fastPassword.headerHeight - rootFastPasswordPanel.theme.modules.fastPassword.searchHeight - parent.spacing * 2
                model: rootFastPasswordPanel.service.filteredEntries
                currentIndex: rootFastPasswordPanel.service.selectedIndex
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: rootFastPasswordPanel.theme.modules.fastPassword.rowGap

                onCurrentIndexChanged: rootFastPasswordPanel.service.setSelection(currentIndex)

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: list.width
                    height: rootFastPasswordPanel.theme.modules.fastPassword.rowHeight
                    radius: rootFastPasswordPanel.theme.modules.fastPassword.rowRadius
                    color: rootFastPasswordPanel.service.selectedIndex === index ? rootFastPasswordPanel.theme.modules.fastPassword.selectedRowColor : rowHover.hovered ? rootFastPasswordPanel.theme.modules.fastPassword.hoveredRowColor : "transparent"
                    border.width: rootFastPasswordPanel.service.selectedIndex === index ? 1 : 0
                    border.color: rootFastPasswordPanel.theme.modules.fastPassword.focusBorderColor

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: rootFastPasswordPanel.theme.modules.fastPassword.rowPadding
                        anchors.rightMargin: rootFastPasswordPanel.theme.modules.fastPassword.rowPadding
                        anchors.topMargin: rootFastPasswordPanel.theme.modules.fastPassword.rowVerticalPadding
                        anchors.bottomMargin: rootFastPasswordPanel.theme.modules.fastPassword.rowVerticalPadding
                        spacing: rootFastPasswordPanel.theme.modules.fastPassword.rowGap

                        Text {
                            width: rootFastPasswordPanel.theme.modules.fastPassword.rowIconWidth
                            height: parent.height
                            text: modelData.icon
                            color: rootFastPasswordPanel.service.selectedIndex === index ? rootFastPasswordPanel.theme.modules.fastPassword.accentColor : rootFastPasswordPanel.theme.modules.fastPassword.secondaryTextColor
                            font.family: rootFastPasswordPanel.theme.iconFontFamily
                            font.pixelSize: rootFastPasswordPanel.theme.modules.fastPassword.rowIconPixelSize
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Column {
                            width: parent.width - rootFastPasswordPanel.theme.modules.fastPassword.rowIconWidth - parent.spacing
                            height: parent.height
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                height: rootFastPasswordPanel.theme.modules.fastPassword.bodyPixelSize + 4
                                text: modelData.label
                                color: rootFastPasswordPanel.theme.modules.fastPassword.primaryTextColor
                                font.pixelSize: rootFastPasswordPanel.theme.modules.fastPassword.bodyPixelSize
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                height: rootFastPasswordPanel.theme.modules.fastPassword.metaPixelSize + 4
                                text: modelData.group
                                color: rootFastPasswordPanel.theme.modules.fastPassword.secondaryTextColor
                                font.pixelSize: rootFastPasswordPanel.theme.modules.fastPassword.metaPixelSize
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                    }

                    HoverHandler {
                        id: rowHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            rootFastPasswordPanel.service.setSelection(index);
                            rootFastPasswordPanel.copyRequested(index);
                        }
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        rootFastPasswordPanel.copyRequested(rootFastPasswordPanel.service.selectedIndex);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        if (rootFastPasswordPanel.service.selectedIndex <= 0)
                            searchInput.forceActiveFocus();
                        else
                            rootFastPasswordPanel.service.moveSelection(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        rootFastPasswordPanel.service.moveSelection(1);
                        event.accepted = true;
                    } else if (event.text && event.text.length === 1 && event.text >= " ") {
                        searchInput.forceActiveFocus();
                        searchInput.insert(searchInput.cursorPosition, event.text);
                        rootFastPasswordPanel.service.searchText = searchInput.text;
                        event.accepted = true;
                    }
                }
            }
        }
    }

    function statusText() {
        if (rootFastPasswordPanel.service.error.length > 0)
            return rootFastPasswordPanel.service.error;

        if (rootFastPasswordPanel.service.loading)
            return "loading";

        if (rootFastPasswordPanel.service.authenticating)
            return "authenticating";

        if (rootFastPasswordPanel.service.copying)
            return "copying";

        return rootFastPasswordPanel.service.filteredEntries.length + " / " + rootFastPasswordPanel.service.entries.length;
    }
}
