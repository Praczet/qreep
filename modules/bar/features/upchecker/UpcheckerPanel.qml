import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootUpcheckerPanel

    required property QtObject theme
    required property QtObject service
    property string filterText: ""
    property bool filterVisible: false
    readonly property string normalizedFilterText: filterText.trim()
    readonly property bool excludeFilter: normalizedFilterText.charAt(0) === "~"
    readonly property string filterNeedle: excludeFilter ? normalizedFilterText.slice(1).trim().toLowerCase() : normalizedFilterText.toLowerCase()
    readonly property bool filterActive: filterNeedle.length > 0
    readonly property var filteredUpdates: filteredUpdateList()
    readonly property int panelWidth: Math.max(1, Math.min(theme.modules.bar.upchecker.windowWidth, width - theme.modules.bar.upchecker.screenMargin * 2))
    readonly property int panelHeight: Math.max(1, height - theme.modules.bar.upchecker.topMargin - theme.modules.bar.upchecker.bottomMargin)

    function listPreview(values) {
        if (!Array.isArray(values) || values.length === 0)
            return "--";

        const limit = rootUpcheckerPanel.theme.modules.bar.upchecker.dependencyPreviewLimit;
        const shown = values.slice(0, limit).join(", ");
        return values.length > limit ? shown + " +" + (values.length - limit) + " more" : shown;
    }

    function filteredUpdateList() {
        const rows = [];

        for (let index = 0; index < service.updates.length; index++) {
            const update = service.updates[index];

            if (matchesFilter(update))
                rows.push({
                    sourceIndex: index,
                    name: update.name,
                    oldVer: update.oldVer,
                    newVer: update.newVer
                });
        }

        return rows;
    }

    function matchesFilter(update) {
        if (!filterActive)
            return true;

        const haystack = [update.name, update.oldVer, update.newVer].join(" ").toLowerCase();
        const containsNeedle = haystack.indexOf(filterNeedle) >= 0;

        return excludeFilter ? !containsNeedle : containsNeedle;
    }

    function currentFilteredIndex() {
        for (let index = 0; index < filteredUpdates.length; index++) {
            if (filteredUpdates[index].sourceIndex === service.selectedIndex)
                return index;
        }

        return -1;
    }

    function selectFilteredIndex(index) {
        if (filteredUpdates.length === 0)
            return;

        const boundedIndex = Math.max(0, Math.min(index, filteredUpdates.length - 1));
        service.selectIndex(filteredUpdates[boundedIndex].sourceIndex);
        updatesList.currentIndex = boundedIndex;
        updatesList.positionViewAtIndex(boundedIndex, ListView.Contain);
    }

    function selectFilteredOffset(offset) {
        const currentIndex = currentFilteredIndex();

        if (currentIndex < 0) {
            selectFilteredIndex(offset > 0 ? 0 : filteredUpdates.length - 1);
            return;
        }

        selectFilteredIndex(currentIndex + offset);
    }

    function showFilter(initialText) {
        filterVisible = true;
        filterInput.forceActiveFocus();

        if (initialText !== undefined && initialText.length > 0)
            filterText += initialText;

        filterInput.cursorPosition = filterInput.text.length;
    }

    function hideFilter() {
        filterVisible = false;
        background.forceActiveFocus();
    }

    function handleEscape() {
        if (filterVisible) {
            hideFilter();
            return;
        }

        if (filterText.length > 0) {
            filterText = "";
            background.forceActiveFocus();
            return;
        }

        visible = false;
    }

    function handlePanelKey(event) {
        if (event.key === Qt.Key_Down) {
            selectFilteredOffset(1);
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Up) {
            selectFilteredOffset(-1);
            event.accepted = true;
            return;
        }

        if (event.modifiers !== Qt.NoModifier && event.modifiers !== Qt.ShiftModifier)
            return;

        if (event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
            showFilter(event.text);
            event.accepted = true;
            return;
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: false
    color: "transparent"

    WlrLayershell.namespace: "qreep-popup-upchecker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusiveZone: 0

    onVisibleChanged: {
        if (visible) {
            service.refresh();
            background.forceActiveFocus();
        } else {
            filterVisible = false;
            filterText = "";
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: rootUpcheckerPanel.visible
        onActivated: rootUpcheckerPanel.handleEscape()
    }

    // Root background
    Rectangle {
        id: background

        anchors.fill: parent
        color: "transparent"
        focus: true

        Keys.onPressed: event => rootUpcheckerPanel.handlePanelKey(event)

        TapHandler {
            onTapped: eventPoint => {
                const clickX = eventPoint.position.x;
                const clickY = eventPoint.position.y;
                const insidePanel = clickX >= panel.x && clickX <= panel.x + panel.width && clickY >= panel.y && clickY <= panel.y + panel.height;

                if (!insidePanel)
                    rootUpcheckerPanel.visible = false;
            }
        }

        // Main panel
        Rectangle {
            id: panel

            x: (parent.width - width) / 2
            anchors {
                top: parent.top
                bottom: parent.bottom
                topMargin: rootUpcheckerPanel.theme.modules.bar.upchecker.topMargin
                bottomMargin: rootUpcheckerPanel.theme.modules.bar.upchecker.topMargin
            }

            width: rootUpcheckerPanel.panelWidth
            height: rootUpcheckerPanel.panelHeight
            radius: rootUpcheckerPanel.theme.modules.bar.upchecker.radius
            color: rootUpcheckerPanel.theme.modules.bar.upchecker.backgroundColor
            border.color: rootUpcheckerPanel.theme.modules.bar.upchecker.borderColor
            border.width: rootUpcheckerPanel.theme.modules.bar.upchecker.borderWidth

            Text {
                id: title

                text: rootUpcheckerPanel.filterActive ? "Updates Available: " + rootUpcheckerPanel.filteredUpdates.length + " / " + rootUpcheckerPanel.service.updates.length : "Updates Available: " + rootUpcheckerPanel.service.updates.length
                color: theme.modules.bar.primaryTextColor
                font.pixelSize: theme.modules.bar.upchecker.titlePixelSize
                font.weight: Font.DemiBold

                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: theme.modules.bar.upchecker.contentPadding
                }
            }

            // Restart banner
            Rectangle {
                id: restartBanner

                visible: rootUpcheckerPanel.service.restartNeeded
                anchors {
                    top: title.bottom
                    left: parent.left
                    right: parent.right
                    margins: theme.modules.bar.upchecker.contentPadding
                    topMargin: theme.modules.bar.upchecker.titleBottomMargin
                }
                height: theme.modules.bar.upchecker.restartBannerHeight
                radius: theme.modules.bar.upchecker.restartBannerRadius
                color: Qt.rgba(theme.modules.bar.borg.warningColor.r, theme.modules.bar.borg.warningColor.g, theme.modules.bar.borg.warningColor.b, 0.16)
                border.color: theme.modules.bar.borg.warningColor
                border.width: theme.modules.bar.upchecker.borderWidth

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: theme.modules.bar.upchecker.restartBannerPadding
                        rightMargin: theme.modules.bar.upchecker.restartBannerPadding
                    }
                    spacing: 4

                    Text {
                        text: rootUpcheckerPanel.service.restartSummary
                        color: theme.modules.bar.borg.warningColor
                        font.pixelSize: theme.modules.bar.upchecker.restartTitlePixelSize
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: rootUpcheckerPanel.service.restartDetails
                        color: theme.modules.bar.upchecker.rowTextColor
                        font.pixelSize: theme.modules.bar.upchecker.restartDetailPixelSize
                        elide: Text.ElideRight
                    }
                }
            }

            // Content area
            Row {
                id: content

                spacing: theme.modules.bar.upchecker.paneSpacing

                anchors {
                    left: parent.left
                    right: parent.right
                    top: rootUpcheckerPanel.service.restartNeeded ? restartBanner.bottom : title.bottom
                    bottom: actions.top
                    margins: theme.modules.bar.upchecker.contentPadding
                    topMargin: theme.modules.bar.upchecker.titleBottomMargin
                    bottomMargin: theme.modules.bar.upchecker.contentPadding
                }

                Rectangle {
                    width: (content.width - content.spacing) / 2
                    height: content.height
                    color: "transparent"
                    clip: true

                    Text {
                        visible: rootUpcheckerPanel.service.loadingUpdates
                        anchors.centerIn: parent
                        text: "Checking for updates..."
                        color: theme.modules.bar.secondaryTextColor
                        font.pixelSize: theme.modules.bar.upchecker.emptyTextPixelSize
                    }

                    Text {
                        visible: !rootUpcheckerPanel.service.loadingUpdates && rootUpcheckerPanel.service.updates.length === 0
                        anchors.centerIn: parent
                        text: rootUpcheckerPanel.service.error.length > 0 ? "Could not load updates." : "No updates available."
                        color: rootUpcheckerPanel.service.error.length > 0 ? theme.modules.bar.borg.errorColor : theme.modules.bar.secondaryTextColor
                        font.pixelSize: theme.modules.bar.upchecker.emptyTextPixelSize
                    }

                    Text {
                        visible: !rootUpcheckerPanel.service.loadingUpdates && rootUpcheckerPanel.service.updates.length > 0 && rootUpcheckerPanel.filteredUpdates.length === 0
                        anchors.centerIn: parent
                        text: "No updates match the filter."
                        color: theme.modules.bar.secondaryTextColor
                        font.pixelSize: theme.modules.bar.upchecker.emptyTextPixelSize
                    }

                    ListView {
                        id: updatesList

                        anchors.fill: parent
                        visible: !rootUpcheckerPanel.service.loadingUpdates && rootUpcheckerPanel.filteredUpdates.length > 0
                        clip: true
                        spacing: theme.modules.bar.upchecker.rowSpacing
                        model: rootUpcheckerPanel.filteredUpdates

                        delegate: Rectangle {
                            id: updateRow

                            required property var modelData
                            required property int index
                            readonly property bool selected: modelData.sourceIndex === rootUpcheckerPanel.service.selectedIndex

                            width: ListView.view.width - theme.modules.bar.upchecker.scrollbarReserve
                            height: theme.modules.bar.upchecker.rowHeight
                            radius: theme.modules.bar.upchecker.rowRadius
                            color: selected ? theme.modules.bar.upchecker.selectedBackgroundColor : theme.modules.bar.moduleBackgroundColor
                            border.width: selected ? theme.modules.bar.upchecker.selectedBorderWidth : 0
                            border.color: theme.modules.bar.accentColor

                            Row {
                                spacing: theme.modules.bar.upchecker.versionSpacing

                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: theme.modules.bar.upchecker.rowHorizontalPadding
                                    rightMargin: theme.modules.bar.upchecker.rowHorizontalPadding
                                }

                                Text {
                                    width: parent.width - oldVersion.width - newVersion.width - parent.spacing * 2
                                    text: updateRow.modelData.name
                                    color: theme.modules.bar.upchecker.rowTextColor
                                    font.pixelSize: theme.modules.bar.upchecker.rowTextPixelSize
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: oldVersion

                                    width: theme.modules.bar.upchecker.versionWidth
                                    text: updateRow.modelData.oldVer
                                    color: theme.modules.bar.secondaryTextColor
                                    font.pixelSize: theme.modules.bar.upchecker.rowTextPixelSize
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: newVersion

                                    width: theme.modules.bar.upchecker.versionWidth
                                    text: updateRow.modelData.newVer
                                    color: theme.modules.bar.upchecker.titleTextColor
                                    font.pixelSize: theme.modules.bar.upchecker.rowTextPixelSize
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideRight
                                }
                            }

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: rootUpcheckerPanel.selectFilteredIndex(updateRow.index)
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }
                    }
                }

                Item {
                    width: (content.width - content.spacing) / 2
                    height: content.height

                    Text {
                        visible: rootUpcheckerPanel.service.detailsView === "empty"
                        anchors.centerIn: parent
                        text: "Select a package to see details."
                        color: theme.modules.bar.secondaryTextColor
                        font.pixelSize: theme.modules.bar.upchecker.emptyTextPixelSize
                    }

                    Text {
                        visible: rootUpcheckerPanel.service.detailsView === "nodata"
                        anchors.centerIn: parent
                        text: "No details yet."
                        color: theme.modules.bar.secondaryTextColor
                        font.pixelSize: theme.modules.bar.upchecker.emptyTextPixelSize
                    }

                    Text {
                        visible: rootUpcheckerPanel.service.detailsView === "loading"
                        anchors.centerIn: parent
                        text: rootUpcheckerPanel.service.loadingUpdates ? "Checking for updates..." : "Loading package information..."
                        color: theme.modules.bar.secondaryTextColor
                        font.pixelSize: theme.modules.bar.upchecker.emptyTextPixelSize
                    }

                    Text {
                        visible: rootUpcheckerPanel.service.detailsView === "error"
                        anchors.centerIn: parent
                        width: parent.width - theme.modules.bar.upchecker.detailPadding * 2
                        text: rootUpcheckerPanel.service.error
                        color: theme.modules.bar.borg.errorColor
                        font.pixelSize: theme.modules.bar.upchecker.emptyTextPixelSize
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Column {
                        visible: rootUpcheckerPanel.service.detailsView === "details"
                        spacing: theme.modules.bar.upchecker.detailSpacing

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: theme.modules.bar.upchecker.detailPadding
                        }

                        Rectangle {
                            width: parent.width
                            height: theme.modules.bar.upchecker.detailHeaderHeight
                            radius: theme.modules.bar.upchecker.rowRadius
                            color: theme.modules.bar.power.actionBackgroundColor

                            Row {
                                spacing: theme.modules.bar.upchecker.versionSpacing

                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: theme.modules.bar.upchecker.detailHeaderPadding
                                }

                                Text {
                                    width: parent.width - detailOldVersion.width - detailArrow.width - detailNewVersion.width - parent.spacing * 3
                                    text: rootUpcheckerPanel.service.details.name || "---"
                                    color: theme.modules.bar.power.actionTextColor
                                    font.pixelSize: theme.modules.bar.upchecker.detailTitlePixelSize
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: detailOldVersion

                                    width: theme.modules.bar.upchecker.detailVersionWidth
                                    text: rootUpcheckerPanel.service.selectedItem ? rootUpcheckerPanel.service.selectedItem.oldVer : ""
                                    color: theme.modules.bar.power.actionTextColor
                                    opacity: theme.modules.bar.upchecker.dimOpacity
                                    font.pixelSize: theme.modules.bar.upchecker.detailVersionPixelSize
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: detailArrow

                                    text: "->"
                                    color: theme.modules.bar.power.actionTextColor
                                    opacity: theme.modules.bar.upchecker.dimOpacity
                                    font.pixelSize: theme.modules.bar.upchecker.detailVersionPixelSize
                                }

                                Text {
                                    id: detailNewVersion

                                    width: theme.modules.bar.upchecker.detailVersionWidth
                                    text: rootUpcheckerPanel.service.selectedItem ? rootUpcheckerPanel.service.selectedItem.newVer : ""
                                    color: theme.modules.bar.power.actionTextColor
                                    font.pixelSize: theme.modules.bar.upchecker.detailVersionPixelSize
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Text {
                            width: parent.width - theme.modules.bar.upchecker.descriptionHorizontalInset * 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: rootUpcheckerPanel.service.details.desc || ""
                            color: theme.modules.bar.upchecker.mutedTextColor
                            font.pixelSize: theme.modules.bar.upchecker.descriptionPixelSize
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Repeater {
                            model: [
                                {
                                    "label": "Repo",
                                    "value": rootUpcheckerPanel.service.details.repo || "--",
                                    "accent": false
                                },
                                {
                                    "label": "Arch",
                                    "value": rootUpcheckerPanel.service.details.arch || "--",
                                    "accent": false
                                },
                                {
                                    "label": "URL",
                                    "value": rootUpcheckerPanel.service.details.url || "--",
                                    "accent": true
                                },
                                {
                                    "label": "Depends",
                                    "value": rootUpcheckerPanel.listPreview(rootUpcheckerPanel.service.details.depends),
                                    "accent": false
                                },
                                {
                                    "label": "Optional",
                                    "value": rootUpcheckerPanel.listPreview(rootUpcheckerPanel.service.details.optdepends),
                                    "accent": false
                                },
                                {
                                    "label": "Required",
                                    "value": rootUpcheckerPanel.listPreview(rootUpcheckerPanel.service.details.requiredby),
                                    "accent": false
                                }
                            ]

                            delegate: Row {
                                required property var modelData

                                width: parent.width
                                spacing: theme.modules.bar.upchecker.versionSpacing

                                Text {
                                    width: theme.modules.bar.upchecker.metaLabelWidth
                                    text: modelData.label
                                    color: theme.modules.bar.secondaryTextColor
                                    font.pixelSize: theme.modules.bar.upchecker.metaTextPixelSize
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    width: parent.width - theme.modules.bar.upchecker.metaLabelWidth - parent.spacing
                                    text: modelData.value
                                    color: modelData.accent ? theme.modules.bar.accentColor : theme.modules.bar.upchecker.rowTextColor
                                    font.pixelSize: theme.modules.bar.upchecker.metaTextPixelSize
                                    wrapMode: modelData.accent ? Text.WrapAnywhere : Text.Wrap
                                }
                            }
                        }
                    }
                }
            }

            // Action buttons
            Row {
                id: actions

                height: theme.modules.bar.upchecker.actionButtonHeight

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: theme.modules.bar.upchecker.contentPadding
                }

                Rectangle {
                    id: refreshButton

                    width: theme.modules.bar.upchecker.actionButtonWidth
                    height: parent.height
                    radius: theme.modules.bar.upchecker.actionButtonRadius
                    color: refreshHover.hovered ? theme.modules.bar.power.actionHoverBackgroundColor : theme.modules.bar.power.actionBackgroundColor

                    Text {
                        anchors.centerIn: parent
                        text: rootUpcheckerPanel.service.loadingUpdates ? "..." : "Refresh"
                        color: theme.modules.bar.power.actionTextColor
                        font.pixelSize: theme.modules.bar.upchecker.emptyTextPixelSize
                    }

                    HoverHandler {
                        id: refreshHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        enabled: !rootUpcheckerPanel.service.loadingUpdates
                        onTapped: rootUpcheckerPanel.service.refreshWithPulse()
                    }
                }

                Item {
                    width: parent.width - refreshButton.width - updateButton.width
                    height: parent.height
                }

                Rectangle {
                    id: updateButton

                    width: theme.modules.bar.upchecker.actionButtonWidth
                    height: parent.height
                    radius: theme.modules.bar.upchecker.actionButtonRadius
                    color: updateHover.hovered ? theme.modules.bar.power.actionHoverBackgroundColor : theme.modules.bar.power.actionBackgroundColor

                    Text {
                        anchors.centerIn: parent
                        text: "Update"
                        color: theme.modules.bar.power.actionTextColor
                        font.pixelSize: theme.modules.bar.upchecker.emptyTextPixelSize
                    }

                    HoverHandler {
                        id: updateHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: rootUpcheckerPanel.service.update()
                    }
                }
            }

            // Filter bar
            Rectangle {
                id: filterBar

                x: (parent.width - width) / 2
                y: rootUpcheckerPanel.filterVisible ? parent.height - theme.modules.bar.upchecker.filterBottomOffset - height : parent.height - theme.modules.bar.upchecker.filterHiddenBottomInset - height
                width: Math.min(theme.modules.bar.upchecker.filterWidth, parent.width - theme.modules.bar.upchecker.contentPadding * 2)
                height: theme.modules.bar.upchecker.filterHeight
                radius: theme.modules.bar.upchecker.filterRadius
                color: theme.modules.bar.moduleBackgroundColor
                border.color: rootUpcheckerPanel.filterActive ? theme.modules.bar.accentColor : theme.modules.bar.moduleHoverBackgroundColor
                border.width: theme.modules.bar.upchecker.borderWidth
                opacity: rootUpcheckerPanel.filterVisible ? 1 : 0
                z: 20

                Behavior on y {
                    NumberAnimation {
                        duration: theme.modules.bar.upchecker.filterAnimationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: theme.modules.bar.upchecker.filterAnimationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: theme.modules.bar.upchecker.filterHorizontalPadding
                        rightMargin: theme.modules.bar.upchecker.filterHorizontalPadding
                    }
                    spacing: theme.modules.bar.upchecker.versionSpacing

                    Text {
                        id: filterModeLabel

                        anchors.verticalCenter: parent.verticalCenter
                        text: rootUpcheckerPanel.excludeFilter ? "hide" : "show"
                        color: rootUpcheckerPanel.excludeFilter ? theme.modules.bar.borg.warningColor : theme.modules.bar.accentColor
                        font.pixelSize: theme.modules.bar.upchecker.filterHintPixelSize
                        font.weight: Font.DemiBold
                    }

                    Item {
                        width: parent.width - filterModeLabel.width - parent.spacing
                        height: filterInput.implicitHeight
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            visible: filterInput.text.length === 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: "type to filter, prefix ~ to hide matches"
                            color: theme.modules.bar.secondaryTextColor
                            font.pixelSize: theme.modules.bar.upchecker.filterHintPixelSize
                        }

                        TextInput {
                            id: filterInput

                            anchors.fill: parent
                            text: rootUpcheckerPanel.filterText
                            color: theme.modules.bar.upchecker.rowTextColor
                            selectionColor: theme.modules.bar.upchecker.selectedBackgroundColor
                            selectedTextColor: theme.modules.bar.upchecker.selectedTextColor
                            font.pixelSize: theme.modules.bar.upchecker.filterTextPixelSize
                            clip: true

                            onTextChanged: {
                                if (rootUpcheckerPanel.filterText !== text)
                                    rootUpcheckerPanel.filterText = text;
                            }

                            Keys.onReturnPressed: rootUpcheckerPanel.hideFilter()
                            Keys.onEnterPressed: rootUpcheckerPanel.hideFilter()
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down || event.key === Qt.Key_Up)
                                    rootUpcheckerPanel.handlePanelKey(event);
                            }
                        }
                    }
                }
            }
        }
    }
}
