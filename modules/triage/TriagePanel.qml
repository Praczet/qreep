import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootTriagePanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen
    property int topReservedHeight: 0

    property bool presented: false
    property bool decisionHistoryOpen: false
    property bool commandEventsOpen: false

    signal closeRequested

    implicitWidth: screen.width
    implicitHeight: screen.height

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.namespace: "qreep-triage"
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
        commandEventsOpen = false;
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: {
            if (rootTriagePanel.commandEventsOpen) {
                rootTriagePanel.commandEventsOpen = false;
                return;
            }

            rootTriagePanel.closeRequested();
        }
    }

    Shortcut {
        sequence: "Return"
        context: Qt.WindowShortcut
        onActivated: rootTriagePanel.service.inspectSelected()
    }

    Shortcut {
        sequence: "Ctrl+R"
        context: Qt.WindowShortcut
        onActivated: rootTriagePanel.service.refresh()
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: presented = true
    }

    Connections {
        target: rootTriagePanel.service
        function onSelectedItemChanged() {
            rootTriagePanel.decisionHistoryOpen = false;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rootTriagePanel.closeRequested()
    }

    Rectangle {
        id: panel

        width: Math.min(rootTriagePanel.theme.modules.triage.panelWidth, rootTriagePanel.width - rootTriagePanel.theme.modules.triage.screenMargin * 2)
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            bottom: parent.bottom
            topMargin: rootTriagePanel.topReservedHeight + rootTriagePanel.theme.modules.triage.screenMargin
            bottomMargin: rootTriagePanel.theme.modules.triage.screenMargin
        }
        radius: rootTriagePanel.theme.modules.triage.panelRadius
        color: rootTriagePanel.theme.modules.triage.panelColor
        border.width: 1
        border.color: rootTriagePanel.theme.modules.triage.borderColor
        opacity: rootTriagePanel.presented ? 1 : 0
        scale: rootTriagePanel.presented ? 1 : 0.985
        clip: true

        Behavior on opacity {
            NumberAnimation {
                duration: rootTriagePanel.theme.modules.triage.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: rootTriagePanel.theme.modules.triage.animationDuration
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
                margins: rootTriagePanel.theme.modules.triage.panelPadding
            }
            height: rootTriagePanel.theme.modules.triage.headerHeight

            Text {
                id: title

                anchors {
                    left: parent.left
                    top: parent.top
                    right: actionRow.left
                    rightMargin: 14
                }
                height: 26
                text: "Triage"
                color: rootTriagePanel.theme.modules.triage.primaryTextColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.titlePixelSize
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                anchors {
                    left: parent.left
                    right: actionRow.left
                    bottom: parent.bottom
                    rightMargin: 14
                }
                height: 18
                text: rootTriagePanel.service.status
                color: rootTriagePanel.service.error.length > 0 ? rootTriagePanel.theme.modules.triage.errorColor : rootTriagePanel.theme.modules.triage.secondaryTextColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Row {
                id: actionRow

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                height: rootTriagePanel.theme.modules.triage.actionHeight
                spacing: 8

                ActionButton {
                    label: "Refresh"
                    onClicked: rootTriagePanel.service.refresh()
                }

                ActionButton {
                    label: "Events"
                    width: 78
                    active: rootTriagePanel.commandEventsOpen
                    onClicked: rootTriagePanel.toggleCommandEvents()
                }

                ActionButton {
                    label: "Export JSON"
                    width: 96
                    onClicked: rootTriagePanel.service.exportJson()
                }

                ActionButton {
                    label: "Export MD"
                    width: 86
                    onClicked: rootTriagePanel.service.exportMarkdown()
                }
            }
        }

        Row {
            id: summaryRow

            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                leftMargin: rootTriagePanel.theme.modules.triage.panelPadding
                rightMargin: rootTriagePanel.theme.modules.triage.panelPadding
                topMargin: 8
            }
            height: rootTriagePanel.theme.modules.triage.summaryHeight
            spacing: 8

            SummaryBox {
                label: "Updates"
                category: "updates"
                value: rootTriagePanel.service.summaryCount("updates")
                tooltip: rootTriagePanel.service.summaryError("updates")
                active: rootTriagePanel.service.activeCategory === "updates"
            }

            SummaryBox {
                label: "Orphans"
                category: "orphans"
                value: rootTriagePanel.service.summaryCount("orphans")
                tooltip: rootTriagePanel.service.summaryError("orphans")
                active: rootTriagePanel.service.activeCategory === "orphans"
            }

            SummaryBox {
                label: "Deps"
                category: "dependencies"
                value: rootTriagePanel.service.summaryCount("dependencies")
                tooltip: rootTriagePanel.service.summaryError("dependencies")
                active: rootTriagePanel.service.activeCategory === "dependencies"
            }

            SummaryBox {
                label: "Explicit"
                category: "explicit"
                value: rootTriagePanel.service.summaryCount("explicit")
                tooltip: rootTriagePanel.service.summaryError("explicit")
                active: rootTriagePanel.service.activeCategory === "explicit"
            }

            SummaryBox {
                label: "Total"
                category: "total"
                value: rootTriagePanel.service.summaryCount("total")
                tooltip: rootTriagePanel.service.summaryError("total")
                active: rootTriagePanel.service.activeCategory === "total"
            }
        }

        Row {
            id: decisionFilterRow

            anchors {
                left: parent.left
                right: parent.right
                top: summaryRow.bottom
                leftMargin: rootTriagePanel.theme.modules.triage.panelPadding
                rightMargin: rootTriagePanel.theme.modules.triage.panelPadding
                topMargin: 8
            }
            height: rootTriagePanel.theme.modules.triage.actionHeight
            spacing: 8

            FilterChip {
                label: "All"
                filter: "all"
                count: rootTriagePanel.service.decisionCount("all")
            }

            FilterChip {
                label: "None"
                filter: "none"
                count: rootTriagePanel.service.decisionCount("none")
            }

            FilterChip {
                label: "Keep"
                filter: "keep"
                count: rootTriagePanel.service.decisionCount("keep")
            }

            FilterChip {
                label: "Investigate"
                filter: "investigate"
                count: rootTriagePanel.service.decisionCount("investigate")
                width: 122
            }

            FilterChip {
                label: "Plan Remove"
                filter: "plan-remove"
                count: rootTriagePanel.service.decisionCount("plan-remove")
                width: 126
            }

            FilterChip {
                label: "Skip"
                filter: "skip"
                count: rootTriagePanel.service.decisionCount("skip")
            }
        }

        Rectangle {
            id: searchBox

            anchors {
                left: parent.left
                top: decisionFilterRow.bottom
                leftMargin: rootTriagePanel.theme.modules.triage.panelPadding
                topMargin: 10
            }
            width: rootTriagePanel.theme.modules.triage.listWidth
            height: rootTriagePanel.theme.modules.triage.searchHeight
            radius: 6
            color: rootTriagePanel.theme.modules.triage.controlColor
            border.width: 1
            border.color: searchInput.activeFocus ? rootTriagePanel.theme.modules.triage.focusBorderColor : rootTriagePanel.theme.modules.triage.borderColor

            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                }
                visible: searchInput.text.length === 0
                text: "filter package, source, decision"
                color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
            }

            TextInput {
                id: searchInput

                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                text: rootTriagePanel.service.searchText
                color: rootTriagePanel.theme.modules.triage.primaryTextColor
                selectionColor: rootTriagePanel.theme.modules.triage.accentColor
                selectedTextColor: rootTriagePanel.theme.modules.triage.panelColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                verticalAlignment: TextInput.AlignVCenter
                clip: true

                onTextEdited: rootTriagePanel.service.searchText = text

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                        packageList.forceActiveFocus();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        rootTriagePanel.service.inspectSelected();
                        event.accepted = true;
                    }
                }
            }
        }

        ListView {
            id: packageList

            anchors {
                left: parent.left
                top: searchBox.bottom
                bottom: bottomStrip.top
                leftMargin: rootTriagePanel.theme.modules.triage.panelPadding
                topMargin: 8
                bottomMargin: 10
            }
            width: rootTriagePanel.theme.modules.triage.listWidth
            model: rootTriagePanel.service.filteredItems
            currentIndex: rootTriagePanel.service.selectedIndex
            spacing: rootTriagePanel.theme.modules.triage.rowGap
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            onCurrentIndexChanged: rootTriagePanel.service.setSelection(currentIndex)

            delegate: TriageCard {
                required property var modelData
                required property int index

                theme: rootTriagePanel.theme
                itemData: modelData
                selected: rootTriagePanel.service.selectedIndex === index

                onClicked: rootTriagePanel.service.setSelection(index)
                onInspectRequested: {
                    rootTriagePanel.service.setSelection(index);
                    rootTriagePanel.service.inspectSelected();
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    rootTriagePanel.service.inspectSelected();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    if (rootTriagePanel.service.selectedIndex <= 0)
                        searchInput.forceActiveFocus();
                    else
                        rootTriagePanel.service.moveSelection(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    rootTriagePanel.service.moveSelection(1);
                    event.accepted = true;
                } else if (event.text && event.text.length === 1 && event.text >= " ") {
                    searchInput.forceActiveFocus();
                    searchInput.insert(searchInput.cursorPosition, event.text);
                    rootTriagePanel.service.searchText = searchInput.text;
                    event.accepted = true;
                }
            }
        }

        Rectangle {
            id: detailPane

            anchors {
                left: packageList.right
                right: parent.right
                top: decisionFilterRow.bottom
                bottom: decisionPanel.top
                leftMargin: rootTriagePanel.theme.modules.triage.detailGap
                rightMargin: rootTriagePanel.theme.modules.triage.panelPadding
                topMargin: 10
                bottomMargin: rootTriagePanel.theme.modules.triage.detailGap
            }
            radius: 6
            color: rootTriagePanel.theme.modules.triage.eventPanelColor
            border.width: 1
            border.color: rootTriagePanel.theme.modules.triage.borderColor
            clip: true

            Text {
                id: detailTitle

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                height: 24
                text: selectedPackageName()
                color: rootTriagePanel.theme.modules.triage.primaryTextColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.titlePixelSize
                font.bold: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: detailMeta

                anchors {
                    left: parent.left
                    right: parent.right
                    top: detailTitle.bottom
                    leftMargin: 14
                    rightMargin: 14
                    topMargin: 4
                }
                height: 18
                text: selectedMeta()
                color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                id: descriptionBox

                anchors {
                    left: parent.left
                    right: parent.right
                    top: detailMeta.bottom
                    leftMargin: 14
                    rightMargin: 14
                    topMargin: 10
                }
                height: 54
                radius: 6
                color: rootTriagePanel.theme.modules.triage.controlColor
                border.width: 1
                border.color: rootTriagePanel.theme.modules.triage.borderColor
                clip: true

                Text {
                    anchors {
                        fill: parent
                        margins: 10
                    }
                    text: packageDescription()
                    color: rootTriagePanel.theme.modules.triage.primaryTextColor
                    font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                id: dependencySections

                anchors {
                    left: parent.left
                    right: parent.right
                    top: descriptionBox.bottom
                    bottom: parent.bottom
                    leftMargin: 14
                    rightMargin: 14
                    topMargin: 12
                    bottomMargin: 14
                }

                Item {
                    id: requiresSection

                    anchors {
                        left: parent.left
                        right: dependencyDivider.left
                        top: parent.top
                        bottom: parent.bottom
                        rightMargin: 10
                    }

                    Text {
                        id: requiresTitle

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        height: 22
                        text: "Requires"
                        color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                        font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize + 1
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        id: requiresSubtitle

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: requiresTitle.bottom
                            topMargin: 1
                        }
                        height: 14
                        text: "Direct dependencies"
                        color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                        font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: requiresSubtitle.bottom
                            leftMargin: 12
                            topMargin: 7
                        }
                        height: 18
                        visible: selectedRequiresDependencies().length === 0
                        text: "none"
                        color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                        font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    ListView {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: requiresSubtitle.bottom
                            bottom: parent.bottom
                            leftMargin: 12
                            topMargin: 5
                        }
                        model: selectedRequiresDependencies()
                        visible: selectedRequiresDependencies().length > 0
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        spacing: 4

                        delegate: Rectangle {
                            required property string modelData

                            width: ListView.view.width
                            height: 22
                            radius: 5
                            color: requiresDepHover.hovered ? rootTriagePanel.theme.modules.triage.hoveredRowColor : "transparent"

                            HoverHandler {
                                id: requiresDepHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 8
                                    rightMargin: 8
                                }
                                height: 18
                                text: modelData
                                color: requiresDepHover.hovered ? rootTriagePanel.theme.modules.triage.accentColor : rootTriagePanel.theme.modules.triage.primaryTextColor
                                font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootTriagePanel.service.focusPackage(modelData)
                            }
                        }
                    }
                }

                Rectangle {
                    id: dependencyDivider

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    color: rootTriagePanel.theme.modules.triage.borderColor
                    opacity: 0.7
                }

                Item {
                    id: requiredBySection

                    anchors {
                        left: dependencyDivider.right
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 10
                    }

                    Text {
                        id: requiredByTitle

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        height: 22
                        text: "Required by"
                        color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                        font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize + 1
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        id: requiredBySubtitle

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: requiredByTitle.bottom
                            topMargin: 1
                        }
                        height: 14
                        text: "Direct reverse dependencies"
                        color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                        font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: requiredBySubtitle.bottom
                            leftMargin: 12
                            topMargin: 7
                        }
                        height: 18
                        visible: selectedRequiredByDependencies().length === 0
                        text: "none"
                        color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                        font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    ListView {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: requiredBySubtitle.bottom
                            bottom: parent.bottom
                            leftMargin: 12
                            topMargin: 5
                        }
                        model: selectedRequiredByDependencies()
                        visible: selectedRequiredByDependencies().length > 0
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        spacing: 4

                        delegate: Rectangle {
                            required property string modelData

                            width: ListView.view.width
                            height: 22
                            radius: 5
                            color: requiredByDepHover.hovered ? rootTriagePanel.theme.modules.triage.hoveredRowColor : "transparent"

                            HoverHandler {
                                id: requiredByDepHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 8
                                    rightMargin: 8
                                }
                                height: 18
                                text: modelData
                                color: requiredByDepHover.hovered ? rootTriagePanel.theme.modules.triage.accentColor : rootTriagePanel.theme.modules.triage.primaryTextColor
                                font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootTriagePanel.service.focusPackage(modelData)
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: inspectHintBox

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    margins: 10
                }
                z: 10
                visible: inspectHintText().length > 0
                radius: 6
                color: inspectHintHover.hovered ? rootTriagePanel.theme.modules.triage.inspectHintHoverColor : rootTriagePanel.theme.modules.triage.inspectHintColor
                border.width: 1
                border.color: inspectHintHover.hovered ? rootTriagePanel.theme.modules.triage.focusBorderColor : rootTriagePanel.theme.modules.triage.borderColor
                clip: true

                HoverHandler {
                    id: inspectHintHover
                    cursorShape: Qt.PointingHandCursor
                }

                Text {
                    anchors {
                        fill: parent
                        margins: 14
                    }
                    text: inspectHintText()
                    color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                    font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize + 1
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootTriagePanel.service.inspectSelected()
                }
            }

        }

        Rectangle {
            id: decisionPanel

            anchors {
                left: packageList.right
                right: parent.right
                bottom: bottomStrip.top
                leftMargin: rootTriagePanel.theme.modules.triage.detailGap
                rightMargin: rootTriagePanel.theme.modules.triage.panelPadding
                bottomMargin: 10
            }
            height: rootTriagePanel.theme.modules.triage.decisionPanelHeight
            radius: 6
            color: rootTriagePanel.theme.modules.triage.decisionPanelColor
            border.width: 1
            border.color: noteInput.activeFocus ? rootTriagePanel.theme.modules.triage.focusBorderColor : rootTriagePanel.theme.modules.triage.borderColor

            Text {
                id: currentDecisionLabel

                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 10
                    topMargin: 9
                }
                width: 112
                height: 16
                text: "Current decision"
                color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
                font.bold: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                anchors {
                    left: currentDecisionLabel.right
                    right: historyButton.left
                    top: parent.top
                    leftMargin: 8
                    rightMargin: 8
                    topMargin: 9
                }
                height: 16
                text: currentDecisionText()
                color: currentDecisionColor()
                font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            MiniButton {
                id: historyButton

                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: 10
                    topMargin: 7
                }
                label: "History"
                active: rootTriagePanel.decisionHistoryOpen
                onClicked: rootTriagePanel.decisionHistoryOpen = !rootTriagePanel.decisionHistoryOpen
            }

            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: currentDecisionLabel.bottom
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 5
                }
                height: 18
                text: selectedDecisionNote().length > 0 ? selectedDecisionNote() : "No decision note recorded."
                color: selectedDecisionNote().length > 0 ? rootTriagePanel.theme.modules.triage.primaryTextColor : rootTriagePanel.theme.modules.triage.secondaryTextColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                id: noteBox

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 54
                }
                height: rootTriagePanel.theme.modules.triage.noteHeight
                visible: !rootTriagePanel.decisionHistoryOpen
                radius: 6
                color: rootTriagePanel.theme.modules.triage.controlColor
                border.width: 1
                border.color: noteInput.activeFocus ? rootTriagePanel.theme.modules.triage.focusBorderColor : rootTriagePanel.theme.modules.triage.borderColor

                Text {
                    anchors {
                        left: parent.left
                        top: parent.top
                        leftMargin: 10
                        topMargin: 8
                    }
                    visible: noteInput.text.length === 0
                    text: "optional decision note"
                    color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                    font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                }

                TextInput {
                    id: noteInput

                    anchors {
                        fill: parent
                        margins: 10
                    }
                    text: rootTriagePanel.service.noteText
                    color: rootTriagePanel.theme.modules.triage.primaryTextColor
                    selectionColor: rootTriagePanel.theme.modules.triage.accentColor
                    selectedTextColor: rootTriagePanel.theme.modules.triage.panelColor
                    font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                    wrapMode: TextInput.Wrap
                    clip: true

                    onTextEdited: rootTriagePanel.service.noteText = text
                }
            }

            Rectangle {
                id: historyBox

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 54
                }
                height: rootTriagePanel.theme.modules.triage.noteHeight
                visible: rootTriagePanel.decisionHistoryOpen
                radius: 6
                color: rootTriagePanel.theme.modules.triage.controlColor
                border.width: 1
                border.color: rootTriagePanel.theme.modules.triage.borderColor
                clip: true

                Text {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 10
                        rightMargin: 10
                        topMargin: 8
                    }
                    visible: selectedDecisionHistory().length === 0
                    height: 18
                    text: "No decision history yet."
                    color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                    font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                ListView {
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    model: selectedDecisionHistory()
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 3

                    delegate: Text {
                        required property var modelData

                        width: ListView.view.width
                        height: 18
                        text: decisionHistoryLine(modelData)
                        color: rootTriagePanel.theme.modules.triage.primaryTextColor
                        font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Row {
                id: decisionRow

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 10
                    rightMargin: 10
                    bottomMargin: 10
                }
                height: rootTriagePanel.theme.modules.triage.actionHeight
                spacing: 8

                ActionButton {
                    label: "Keep"
                    decisionKind: "keep"
                    active: currentDecisionText() === "keep"
                    onClicked: rootTriagePanel.service.decideSelected("keep")
                }

                ActionButton {
                    label: "Investigate"
                    width: 98
                    decisionKind: "investigate"
                    active: currentDecisionText() === "investigate"
                    onClicked: rootTriagePanel.service.decideSelected("investigate")
                }

                ActionButton {
                    label: "Plan Remove"
                    width: 100
                    decisionKind: "plan-remove"
                    active: currentDecisionText() === "plan-remove"
                    onClicked: rootTriagePanel.service.decideSelected("plan-remove")
                }

                ActionButton {
                    label: "Skip"
                    decisionKind: "skip"
                    active: currentDecisionText() === "skip"
                    onClicked: rootTriagePanel.service.decideSelected("skip")
                }
            }
        }

        Rectangle {
            id: commandEventsPanel

            anchors {
                left: packageList.right
                right: parent.right
                top: decisionFilterRow.bottom
                bottom: bottomStrip.top
                leftMargin: rootTriagePanel.theme.modules.triage.detailGap
                rightMargin: rootTriagePanel.theme.modules.triage.panelPadding
                topMargin: 10
                bottomMargin: 10
            }
            visible: rootTriagePanel.commandEventsOpen
            z: 30
            radius: 6
            color: rootTriagePanel.theme.modules.triage.eventPanelColor
            border.width: 1
            border.color: rootTriagePanel.theme.modules.triage.focusBorderColor
            clip: true

            Text {
                id: commandEventsTitle

                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 14
                    topMargin: 12
                }
                width: 220
                height: 22
                text: "Command Events"
                color: rootTriagePanel.theme.modules.triage.primaryTextColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.titlePixelSize
                font.bold: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                anchors {
                    left: commandEventsTitle.right
                    right: commandEventsActions.left
                    verticalCenter: commandEventsTitle.verticalCenter
                    leftMargin: 8
                    rightMargin: 8
                }
                height: 18
                text: rootTriagePanel.service.loadingEvents ? "loading" : rootTriagePanel.service.commandEvents.length + " recent"
                color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Row {
                id: commandEventsActions

                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: 10
                    topMargin: 10
                }
                height: 24
                spacing: 6

                MiniButton {
                    label: "Refresh"
                    onClicked: rootTriagePanel.service.loadEvents()
                }

                MiniButton {
                    label: "Close"
                    width: 58
                    onClicked: rootTriagePanel.commandEventsOpen = false
                }
            }

            Text {
                id: commandEventsEmpty

                anchors {
                    left: parent.left
                    right: parent.right
                    top: commandEventsTitle.bottom
                    leftMargin: 14
                    rightMargin: 14
                    topMargin: 22
                }
                visible: !rootTriagePanel.service.loadingEvents && rootTriagePanel.service.commandEvents.length === 0
                height: 22
                text: "No command events recorded yet."
                color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            ListView {
                id: commandEventsList

                anchors {
                    left: parent.left
                    right: parent.right
                    top: commandEventsTitle.bottom
                    bottom: parent.bottom
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 14
                    bottomMargin: 10
                }
                model: rootTriagePanel.service.commandEvents
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: 6

                delegate: Rectangle {
                    required property var modelData

                    width: ListView.view.width
                    height: 58
                    radius: 6
                    color: eventRowHover.hovered ? rootTriagePanel.theme.modules.triage.eventRowHoverColor : rootTriagePanel.theme.modules.triage.eventRowColor
                    border.width: 1
                    border.color: modelData.ok ? rootTriagePanel.theme.modules.triage.borderColor : rootTriagePanel.theme.modules.triage.dangerBorderColor

                    HoverHandler {
                        id: eventRowHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    Text {
                        id: eventHeader

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 10
                            rightMargin: 10
                            topMargin: 7
                        }
                        height: 16
                        text: eventTimeText(modelData.ts) + " | " + eventResultText(modelData) + " | " + String(modelData.commandId || "")
                        color: modelData.ok ? rootTriagePanel.theme.modules.triage.secondaryTextColor : rootTriagePanel.theme.modules.triage.errorColor
                        font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
                        font.bold: true
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        id: eventCommand

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: eventHeader.bottom
                            leftMargin: 10
                            rightMargin: 10
                            topMargin: 3
                        }
                        height: 16
                        text: rootTriagePanel.service.eventCommandLine(modelData)
                        color: rootTriagePanel.theme.modules.triage.primaryTextColor
                        font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: eventCommand.bottom
                            leftMargin: 10
                            rightMargin: 10
                            topMargin: 2
                        }
                        height: 14
                        text: eventMetaLine(modelData)
                        color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                        font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootTriagePanel.service.copyEventCommand(modelData)
                    }
                }
            }
        }

        Rectangle {
            id: bottomStrip

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: rootTriagePanel.theme.modules.triage.panelPadding
                rightMargin: rootTriagePanel.theme.modules.triage.panelPadding
                bottomMargin: rootTriagePanel.theme.modules.triage.panelPadding
            }
            height: 30
            radius: 6
            color: bottomStripHover.hovered ? rootTriagePanel.theme.modules.triage.hoveredRowColor : rootTriagePanel.theme.modules.triage.controlColor

            HoverHandler {
                id: bottomStripHover
                cursorShape: Qt.PointingHandCursor
            }

            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                    rightMargin: 10
                }
                text: eventLine()
                color: rootTriagePanel.theme.modules.triage.secondaryTextColor
                font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: rootTriagePanel.service.copyLastCommand()
            }
        }
    }

    component SummaryBox: Rectangle {
        required property string label
        required property string category
        required property string value
        property bool active: false
        property string tooltip: ""

        width: (summaryRow.width - summaryRow.spacing * 4) / 5
        height: summaryRow.height
        radius: 6
        color: active ? rootTriagePanel.theme.modules.triage.selectedRowColor : summaryHover.hovered ? rootTriagePanel.theme.modules.triage.hoveredRowColor : rootTriagePanel.theme.modules.triage.sectionColor
        border.width: 1
        border.color: active ? rootTriagePanel.theme.modules.triage.focusBorderColor : value === "!" ? rootTriagePanel.theme.modules.triage.dangerBorderColor : rootTriagePanel.theme.modules.triage.borderColor

        HoverHandler {
            id: summaryHover
        }

        MouseArea {
            anchors.fill: parent
            onClicked: rootTriagePanel.service.setCategory(category)
        }

        Text {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 10
                rightMargin: 10
                topMargin: 8
            }
            height: 18
            text: value
            color: parent.value === "!" ? rootTriagePanel.theme.modules.triage.errorColor : rootTriagePanel.theme.modules.triage.primaryTextColor
            font.pixelSize: rootTriagePanel.theme.modules.triage.valuePixelSize
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 10
                rightMargin: 10
                bottomMargin: 8
            }
            height: 16
            text: label
            color: tooltip.length > 0 ? rootTriagePanel.theme.modules.triage.warningColor : rootTriagePanel.theme.modules.triage.secondaryTextColor
            font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    component FilterChip: Rectangle {
        required property string label
        required property string filter
        required property int count
        readonly property bool active: rootTriagePanel.service.activeDecisionFilter === filter

        width: 92
        height: decisionFilterRow.height
        radius: 6
        color: active ? rootTriagePanel.theme.modules.triage.selectedRowColor : chipHover.hovered ? rootTriagePanel.theme.modules.triage.hoveredRowColor : rootTriagePanel.theme.modules.triage.controlColor
        border.width: 1
        border.color: active ? rootTriagePanel.theme.modules.triage.focusBorderColor : rootTriagePanel.theme.modules.triage.borderColor

        HoverHandler {
            id: chipHover
        }

        Text {
            anchors {
                left: parent.left
                right: countText.left
                verticalCenter: parent.verticalCenter
                leftMargin: 10
                rightMargin: 6
            }
            height: parent.height
            text: label
            color: rootTriagePanel.theme.modules.triage.primaryTextColor
            font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: countText

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 10
            }
            width: 28
            height: parent.height
            text: String(count)
            color: rootTriagePanel.theme.modules.triage.secondaryTextColor
            font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            onClicked: rootTriagePanel.service.setDecisionFilter(filter)
        }
    }

    component ActionButton: Rectangle {
        property string label: ""
        property string decisionKind: ""
        property bool active: false
        property bool danger: false
        signal clicked

        width: 82
        height: rootTriagePanel.theme.modules.triage.actionHeight
        radius: 6
        color: buttonColor()
        border.width: decisionKind.length > 0 || active || danger || buttonHover.hovered ? 1 : 0
        border.color: decisionKind.length > 0 ? decisionButtonColor() : danger && !active ? rootTriagePanel.theme.modules.triage.dangerBorderColor : rootTriagePanel.theme.modules.triage.focusBorderColor

        HoverHandler {
            id: buttonHover
        }

        Text {
            anchors.fill: parent
            text: label
            color: decisionKind.length > 0 ? decisionButtonTextColor() : active || danger ? rootTriagePanel.theme.modules.triage.primaryTextColor : rootTriagePanel.theme.modules.triage.actionTextColor
            font.pixelSize: rootTriagePanel.theme.modules.triage.bodyPixelSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }

        function buttonColor() {
            if (decisionKind.length > 0) {
                const base = decisionButtonColor();
                const opacity = active ? 0.28 : buttonHover.hovered ? 0.18 : 0.10;
                return Qt.rgba(base.r, base.g, base.b, opacity);
            }
            if (active)
                return rootTriagePanel.theme.modules.triage.selectedRowColor;
            if (danger)
                return rootTriagePanel.theme.modules.triage.dangerColor;
            if (buttonHover.hovered)
                return rootTriagePanel.theme.modules.triage.selectedRowColor;

            return rootTriagePanel.theme.modules.triage.actionColor;
        }

        function decisionButtonColor() {
            if (decisionKind === "keep")
                return rootTriagePanel.theme.modules.triage.successColor;
            if (decisionKind === "investigate")
                return rootTriagePanel.theme.modules.triage.warningColor;
            if (decisionKind === "plan-remove")
                return rootTriagePanel.theme.modules.triage.errorColor;

            return rootTriagePanel.theme.modules.triage.secondaryTextColor;
        }

        function decisionButtonTextColor() {
            if (active)
                return rootTriagePanel.theme.modules.triage.primaryTextColor;

            return decisionButtonColor();
        }
    }

    component MiniButton: Rectangle {
        property string label: ""
        property bool active: false
        signal clicked

        width: 72
        height: 24
        radius: 5
        color: active ? rootTriagePanel.theme.modules.triage.selectedRowColor : miniButtonHover.hovered ? rootTriagePanel.theme.modules.triage.hoveredRowColor : rootTriagePanel.theme.modules.triage.controlColor
        border.width: 1
        border.color: active ? rootTriagePanel.theme.modules.triage.focusBorderColor : rootTriagePanel.theme.modules.triage.borderColor

        HoverHandler {
            id: miniButtonHover
        }

        Text {
            anchors.fill: parent
            text: label
            color: rootTriagePanel.theme.modules.triage.primaryTextColor
            font.pixelSize: rootTriagePanel.theme.modules.triage.metaPixelSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }

    function selectedPackageName() {
        if (rootTriagePanel.service.selectedItem)
            return rootTriagePanel.service.selectedItem.package || "No package selected";

        return "No package selected";
    }

    function toggleCommandEvents() {
        rootTriagePanel.commandEventsOpen = !rootTriagePanel.commandEventsOpen;
        if (rootTriagePanel.commandEventsOpen)
            rootTriagePanel.service.loadEvents();
    }

    function selectedMeta() {
        const item = rootTriagePanel.service.selectedItem;
        const details = selectedPackageDetails();
        const bits = [];

        if (details && details.version)
            bits.push("version: " + details.version);
        if (details && details.installReason)
            bits.push(details.installReason);

        return bits.length > 0 ? bits.join(" | ") : "Select a package and press Enter to inspect it.";
    }

    function inspectHintText() {
        const item = rootTriagePanel.service.selectedItem;
        const details = selectedPackageDetails();
        if (!item || rootTriagePanel.service.loadingDetails)
            return "";
        if (details)
            return "";

        return "Press Enter or double-click to load package metadata and dependencies.";
    }

    function currentDecisionText() {
        return rootTriagePanel.service.selectedDecisionKind();
    }

    function currentDecisionColor() {
        const decision = currentDecisionText();
        if (decision === "keep")
            return rootTriagePanel.theme.modules.triage.successColor;
        if (decision === "investigate")
            return rootTriagePanel.theme.modules.triage.warningColor;
        if (decision === "plan-remove")
            return rootTriagePanel.theme.modules.triage.errorColor;

        return rootTriagePanel.theme.modules.triage.secondaryTextColor;
    }

    function selectedDecisionNote() {
        const item = rootTriagePanel.service.selectedItem;
        if (!item || !item.latestDecision || !item.latestDecision.note)
            return "";

        return String(item.latestDecision.note);
    }

    function selectedDecisionHistory() {
        const item = rootTriagePanel.service.selectedItem;
        if (!item || !Array.isArray(item.decisions))
            return [];

        return item.decisions.slice().reverse();
    }

    function decisionHistoryLine(decision) {
        if (!decision)
            return "";

        const kind = String(decision.kind || "none");
        const note = decision.note ? " | " + String(decision.note) : "";
        return decisionTimeText(decision.ts) + "  " + kind + note;
    }

    function decisionTimeText(ts) {
        if (!ts)
            return "unknown";

        return Qt.formatDateTime(new Date(Number(ts) * 1000), "MM-dd HH:mm");
    }

    function eventTimeText(ts) {
        if (!ts)
            return "unknown";

        return Qt.formatDateTime(new Date(Number(ts) * 1000), "MM-dd HH:mm:ss");
    }

    function eventResultText(event) {
        if (!event)
            return "unknown";

        if (event.ok)
            return "ok";

        return "failed";
    }

    function eventMetaLine(event) {
        if (!event)
            return "";

        const code = event.exitCode === null || event.exitCode === undefined ? "no exit code" : "exit " + event.exitCode;
        const stderr = event.stderr ? " | " + String(event.stderr) : "";
        return String(event.trigger || "manual") + " | " + String(event.risk || "unknown") + " | " + code + stderr;
    }

    function packageDescription() {
        const details = selectedPackageDetails();
        if (rootTriagePanel.service.loadingDetails)
            return "Loading package details.";
        if (details && details.description)
            return details.description;
        if (rootTriagePanel.service.selectedItem)
            return "Package metadata has not been loaded yet.";

        return "Pick a package category, select a package, then inspect it.";
    }

    function selectedPackageDetails() {
        const details = rootTriagePanel.service.packageDetails;
        if (!details || details.package !== selectedPackageName())
            return null;

        return details;
    }

    function selectedRequiresDependencies() {
        const details = selectedPackageDetails();
        return details && Array.isArray(details.requires) ? details.requires : [];
    }

    function selectedRequiredByDependencies() {
        const details = selectedPackageDetails();
        return details && Array.isArray(details.requiredBy) ? details.requiredBy : [];
    }

    function eventLine() {
        const event = rootTriagePanel.service.lastEvent;
        if (!event)
            return "No command event yet.";

        const command = rootTriagePanel.service.eventCommandLine(event);
        const code = event.exitCode === null || event.exitCode === undefined ? "no exit code" : "exit " + event.exitCode;
        const stderr = event.stderr ? " | " + event.stderr : "";
        return event.commandId + " | " + command + " | " + event.risk + " | " + code + stderr;
    }
}
