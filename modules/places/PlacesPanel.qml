import QtQuick
import Quickshell
import Quickshell.Wayland

// Places overlay: dimmed backdrop, one centered card with search on top,
// the project list on the left and the selected project on the right.
PanelWindow {
    id: rootPlacesPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    readonly property QtObject pt: theme.modules.places
    property bool presented: false
    // F1 sheet. Esc closes it before it clears the filter or closes Places.
    property bool shortcutsOpen: false
    readonly property var shortcuts: [
        { keys: "type", action: "Filter by name, id, group or path" },
        { keys: "↑ ↓  PgUp PgDn", action: "Move through projects" },
        { keys: "Enter", action: "Run the highlighted button (editor by default)" },
        { keys: "Tab  Shift+Tab", action: "Move through the buttons" },
        { keys: "Shift+Enter", action: "Cockpit (dev workspace)" },
        { keys: "Ctrl+E", action: "Open in the other editor" },
        { keys: "Ctrl+O", action: "File manager" },
        { keys: "Ctrl+T", action: "Terminal in the project folder" },
        { keys: "Ctrl+R", action: "Re-read config, git and stats" },
        { keys: "double click", action: "Open in the editor" },
        { keys: "click a file", action: "Open that file in the editor" },
        { keys: "F1", action: "This sheet" },
        { keys: "Esc", action: "Close sheet, clear filter, close" }
    ]

    signal closeRequested

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "qreep-places"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        search.forceActiveFocus();
        if (panelOpen)
            enterTimer.restart();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            search.forceActiveFocus();
            enterTimer.restart();
            return;
        }
        enterTimer.stop();
        presented = false;
        shortcutsOpen = false;
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: rootPlacesPanel.presented = true
    }

    Rectangle {
        anchors.fill: parent
        color: rootPlacesPanel.pt.overlayColor
        opacity: rootPlacesPanel.presented ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: rootPlacesPanel.pt.animationDuration
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rootPlacesPanel.closeRequested()
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        anchors.verticalCenterOffset: rootPlacesPanel.presented ? 0 : 24
        width: rootPlacesPanel.pt.panelWidthFor(parent.width, parent.height)
        height: rootPlacesPanel.pt.panelHeightFor(parent.width, parent.height)
        radius: rootPlacesPanel.pt.panelRadius
        color: rootPlacesPanel.pt.panelColor
        border.width: 1
        border.color: rootPlacesPanel.pt.borderColor
        opacity: rootPlacesPanel.presented ? 1 : 0
        scale: rootPlacesPanel.presented ? 1 : 0.98
        clip: true

        Behavior on opacity {
            NumberAnimation {
                duration: rootPlacesPanel.pt.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: rootPlacesPanel.pt.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: rootPlacesPanel.pt.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        // Swallow clicks so only the backdrop closes.
        MouseArea {
            anchors.fill: parent
        }

        // --- search ----------------------------------------------------------
        Rectangle {
            id: searchBox

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: rootPlacesPanel.pt.panelPadding
            }
            height: rootPlacesPanel.pt.searchHeight
            radius: height / 2
            color: rootPlacesPanel.pt.searchColor
            border.width: search.activeFocus ? 1 : 0
            border.color: rootPlacesPanel.pt.selectedBorderColor

            Text {
                id: searchIcon

                anchors {
                    left: parent.left
                    leftMargin: 18
                    verticalCenter: parent.verticalCenter
                }
                text: "󰉋"
                color: rootPlacesPanel.pt.accentColor
                font.family: rootPlacesPanel.theme.iconFontFamily
                font.pixelSize: 20
            }

            Text {
                id: searchLabel

                anchors {
                    left: searchIcon.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                text: "Places"
                color: rootPlacesPanel.pt.accentColor
                font.pixelSize: rootPlacesPanel.pt.searchPixelSize
                font.bold: true
            }

            TextInput {
                id: search

                anchors {
                    left: searchLabel.right
                    leftMargin: 14
                    right: countText.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                color: rootPlacesPanel.pt.primaryTextColor
                selectionColor: rootPlacesPanel.pt.selectedRowColor
                font.pixelSize: rootPlacesPanel.pt.searchPixelSize
                text: rootPlacesPanel.service.query
                clip: true

                onTextEdited: rootPlacesPanel.service.setQuery(text)
                Keys.onPressed: event => rootPlacesPanel.handleKey(event)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text.length === 0
                    text: "type to filter projects"
                    color: rootPlacesPanel.pt.secondaryTextColor
                    font.pixelSize: rootPlacesPanel.pt.searchPixelSize
                }
            }

            Text {
                id: countText

                anchors {
                    right: parent.right
                    rightMargin: 18
                    verticalCenter: parent.verticalCenter
                }
                text: rootPlacesPanel.service.configError.length > 0 ? rootPlacesPanel.service.configError : rootPlacesPanel.service.filtered.length + " of " + rootPlacesPanel.service.projects.length
                color: rootPlacesPanel.service.configError.length > 0 ? rootPlacesPanel.pt.errorColor : rootPlacesPanel.pt.secondaryTextColor
                font.pixelSize: rootPlacesPanel.pt.metaPixelSize + 1
            }
        }

        // --- project list -------------------------------------------------------
        Rectangle {
            id: listPane

            anchors {
                left: parent.left
                top: searchBox.bottom
                bottom: footer.top
                leftMargin: rootPlacesPanel.pt.panelPadding
                topMargin: rootPlacesPanel.pt.sectionGap
                bottomMargin: 8
            }
            width: rootPlacesPanel.pt.listWidthFor(card.width)
            radius: rootPlacesPanel.pt.cardRadius
            color: rootPlacesPanel.pt.listColor

            ListView {
                id: list

                anchors {
                    fill: parent
                    margins: 8
                }
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: rootPlacesPanel.service.filtered
                currentIndex: rootPlacesPanel.service.selectedIndex

                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: PlacesProjectRow {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    theme: rootPlacesPanel.theme
                    service: rootPlacesPanel.service
                    project: modelData
                    selected: index === rootPlacesPanel.service.selectedIndex
                    firstOfGroup: index === 0 || rootPlacesPanel.service.filtered[index - 1].group !== modelData.group

                    onClicked: {
                        rootPlacesPanel.service.selectedIndex = index;
                        search.forceActiveFocus();
                    }
                    onDoubleClicked: rootPlacesPanel.activate("editor")
                }
            }

            Text {
                anchors.centerIn: parent
                visible: rootPlacesPanel.service.filtered.length === 0
                text: rootPlacesPanel.service.projects.length === 0 ? "No projects yet.\nAdd some to ~/.config/qreep/places.json" : "Nothing matches."
                horizontalAlignment: Text.AlignHCenter
                color: rootPlacesPanel.pt.secondaryTextColor
                font.pixelSize: rootPlacesPanel.pt.bodyPixelSize
            }
        }

        // --- detail -------------------------------------------------------------
        PlacesDetail {
            id: detail

            anchors {
                left: listPane.right
                right: parent.right
                top: searchBox.bottom
                bottom: footer.top
                leftMargin: rootPlacesPanel.pt.sectionGap + 4
                rightMargin: rootPlacesPanel.pt.panelPadding
                topMargin: rootPlacesPanel.pt.sectionGap
                bottomMargin: 8
            }
            theme: rootPlacesPanel.theme
            service: rootPlacesPanel.service
        }

        // --- key hints ------------------------------------------------------------
        Text {
            id: footer

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: rootPlacesPanel.pt.panelPadding + 6
                rightMargin: rootPlacesPanel.pt.panelPadding
            }
            height: rootPlacesPanel.pt.footerHeight
            verticalAlignment: Text.AlignVCenter
            text: "↑↓ move · ⇥ buttons · ↵ run · ⇧↵ cockpit · ^E other editor · ^O folder · ^T terminal · ^R refresh · F1 shortcuts · Esc clear / close"
            color: rootPlacesPanel.pt.secondaryTextColor
            font.pixelSize: rootPlacesPanel.pt.metaPixelSize
            elide: Text.ElideRight
        }

        // --- F1 shortcuts sheet ----------------------------------------------------
        Rectangle {
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: rootPlacesPanel.shortcutsOpen ? 1 : 0
            color: rootPlacesPanel.pt.overlayColor
            radius: card.radius

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: rootPlacesPanel.shortcutsOpen = false
            }

            Rectangle {
                anchors.centerIn: parent
                width: 520
                height: sheet.implicitHeight + 2 * rootPlacesPanel.pt.panelPadding
                radius: rootPlacesPanel.pt.cardRadius
                color: rootPlacesPanel.pt.panelColor
                border.width: 1
                border.color: rootPlacesPanel.pt.selectedBorderColor

                Column {
                    id: sheet

                    anchors {
                        fill: parent
                        margins: rootPlacesPanel.pt.panelPadding
                    }
                    spacing: 8

                    Text {
                        bottomPadding: 6
                        text: "Shortcuts"
                        color: rootPlacesPanel.pt.sectionColor
                        font.pixelSize: rootPlacesPanel.pt.sectionPixelSize
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                    }

                    Repeater {
                        model: rootPlacesPanel.shortcuts

                        Row {
                            required property var modelData

                            spacing: 16

                            Rectangle {
                                width: 150
                                height: 24
                                radius: 6
                                color: rootPlacesPanel.pt.chipColor

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.keys
                                    color: rootPlacesPanel.pt.accentColor
                                    font.family: rootPlacesPanel.pt.monoFontFamily
                                    font.pixelSize: rootPlacesPanel.pt.metaPixelSize + 1
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.action
                                color: rootPlacesPanel.pt.primaryTextColor
                                font.pixelSize: rootPlacesPanel.pt.bodyPixelSize
                            }
                        }
                    }
                }
            }
        }
    }

    function handleKey(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;

        if (event.key === Qt.Key_F1) {
            event.accepted = true;
            shortcutsOpen = !shortcutsOpen;
            return;
        }

        switch (event.key) {
        case Qt.Key_Escape:
            event.accepted = true;
            if (shortcutsOpen)
                shortcutsOpen = false;
            else if (search.text.length > 0)
                service.setQuery("");
            else
                closeRequested();
            return;
        case Qt.Key_Up:
        case Qt.Key_Down:
            event.accepted = true;
            service.move(event.key === Qt.Key_Down ? 1 : -1);
            return;
        case Qt.Key_PageUp:
        case Qt.Key_PageDown:
            event.accepted = true;
            service.move(event.key === Qt.Key_PageDown ? 5 : -5);
            return;
        case Qt.Key_Tab:
        case Qt.Key_Backtab:
            event.accepted = true;
            detail.cycleAction(event.key === Qt.Key_Backtab || shift ? -1 : 1);
            return;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            event.accepted = true;
            activate(shift ? "cockpit" : "selected");
            return;
        }

        if (!ctrl)
            return;

        const actions = {
            [Qt.Key_O]: "folder",
            [Qt.Key_T]: "terminal",
            [Qt.Key_E]: "other-editor",
            [Qt.Key_R]: "refresh"
        };
        const action = actions[event.key];

        if (action) {
            event.accepted = true;
            activate(action);
        }
    }

    // Everything that launches something closes Places; refresh stays.
    function activate(action) {
        const project = service.selected;

        if (action === "refresh") {
            service.refresh();
            return;
        }
        if (!project)
            return;

        if (action === "selected")
            detail.runAction(detail.actions[detail.actionIndex]);
        else if (action === "editor")
            service.openInEditor(project, "");
        else if (action === "cockpit")
            service.openCockpit(project);
        else if (action === "folder")
            service.openFolder(project, "");
        else if (action === "terminal")
            service.openTerminal(project);
        else if (action === "other-editor") {
            const config = service.config || {};
            const current = project.editor || config.defaultEditor || "nvim";
            const other = service.editorNames().find(name => name !== current);

            if (!other)
                return;
            service.openInEditor(project, "", other);
        }

        closeRequested();
    }
}
