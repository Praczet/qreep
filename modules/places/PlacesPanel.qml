import QtQuick
import QtQuick.Effects
import "../kip" as Kip
import Quickshell
import Quickshell.Wayland

// Places overlay: dimmed backdrop, one centered card with search on top,
// the project list on the left and the selected project on the right.
PanelWindow {
    id: rootPlacesPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen
    property QtObject kipController: null

    readonly property QtObject pt: theme.modules.places
    property bool presented: false
    // F1 sheet. Esc closes it before it clears the filter or closes Places.
    property bool shortcutsOpen: false
    // Ctrl+/: the search box finds items on this page instead of projects.
    property bool findMode: false
    // "Open with" for a clicked file: KIP's chooser and KIP's file actions,
    // editor first. chooserFile is relative to the selected project.
    property string chooserFile: ""
    // Set for a Logseq todo: the chooser then runs through Kip.runAction.
    property var chooserTodo: null
    // Set for a USB drive: the chooser's options are udisksctl actions.
    property var chooserUsb: null
    // A plain file chooser (not folder / todo / usb / smb): its choice is
    // remembered per file type, and xdg-mime refines its order.
    property bool chooserIsFile: false
    property string chooserMime: ""

    Connections {
        target: rootPlacesPanel.service

        function onFileTypeKnown(path, mime, appName, apps) {
            if (!rootPlacesPanel.chooserIsFile || rootPlacesPanel.chooserFile !== path)
                return;
            rootPlacesPanel.chooserMime = mime;
            rootPlacesPanel.refineFileChooser(path, mime, appName, apps);
        }
    }
    // Set for an SMB share: the chooser's options are mount actions.
    property var chooserSmb: null
    // SMB password dialog: the share being logged into, and why.
    property var loginShare: null
    property string loginMessage: ""
    property bool loginRemember: true
    readonly property bool loginOpen: loginShare !== null

    Connections {
        target: rootPlacesPanel.service

        function onSmbPasswordNeeded(share, message) {
            rootPlacesPanel.openLogin(share, message);
        }
    }

    function openLogin(share, message) {
        chooserFile = "";
        loginShare = share;
        loginMessage = message;
        loginRemember = true;
        loginDomain.text = share.domain;
        loginPassword.text = "";
        loginPassword.forceActiveFocus();
    }

    function closeLogin() {
        loginPassword.text = "";
        loginShare = null;
        search.forceActiveFocus();
    }

    function submitLogin() {
        if (!loginShare || loginPassword.text.length === 0)
            return;

        const share = loginShare;
        const password = loginPassword.text;

        closeLogin();
        service.smbLogin(share, loginDomain.text, password, loginRemember);
        closeRequested();
    }
    property var chooserOptions: []
    property int chooserIndex: 0
    readonly property bool chooserOpen: chooserFile.length > 0

    // Tips: built-in plus places.json "tips": { "enabled", "items" }.
    readonly property var tipsConfig: service.config && service.config.tips ? service.config.tips : ({})
    readonly property var tips: tipsConfig.enabled === false ? [] : tipSource.builtIn.concat(Array.isArray(tipsConfig.items) ? tipsConfig.items.map(String) : [])
    property int tipIndex: 0

    PlacesTips {
        id: tipSource
    }

    function nextTip() {
        if (tips.length > 0)
            tipIndex = (tipIndex + 1) % tips.length;
    }

    function randomTip() {
        tipIndex = tips.length > 0 ? Math.floor(Math.random() * tips.length) : 0;
    }
    readonly property var shortcuts: [
        { keys: "type", action: "Filter by name, id, group or path" },
        { keys: "↑ ↓  PgUp PgDn", action: "Move through projects" },
        { keys: "Enter", action: "Run the highlighted button (editor by default)" },
        { keys: "Tab  Shift+Tab", action: "Buttons, then file cards, around again" },
        { keys: "Shift+Enter", action: "Cockpit (dev workspace)" },
        { keys: "Ctrl+E", action: "Open in the other editor" },
        { keys: "Ctrl+O", action: "File manager" },
        { keys: "Ctrl+T", action: "Terminal in the project folder" },
        { keys: "Ctrl+R", action: "Re-read config, git and stats" },
        { keys: "double click", action: "Open in the editor" },
        { keys: "click a file", action: "Open with: editor, Vivify, app, folder, terminal, copy path" },
        { keys: "1–9  ↑↓ Enter", action: "Pick in the Open with chooser" },
        { keys: "Alt+1 … Alt+9", action: "Jump into a card (file cards, then blocks)" },
        { keys: "Ctrl+1 … Ctrl+0", action: "Select the 1st … 10th entry in the list" },
        { keys: "Ctrl+/", action: "Find anything on this page; ↑↓ next match" },
        { keys: "in a card: ↑↓ ← →", action: "Move between files and cards" },
        { keys: "in a card: Enter", action: "Open with … for that file" },
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
    // Let go of the keyboard as soon as closing starts, not after the fade:
    // whatever Places just launched should get it. Same as KIP.
    WlrLayershell.keyboardFocus: panelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Component.onCompleted: {
        randomTip();
        search.forceActiveFocus();
        if (panelOpen)
            enterTimer.restart();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            randomTip();
            search.forceActiveFocus();
            enterTimer.restart();
            return;
        }
        enterTimer.stop();
        presented = false;
        shortcutsOpen = false;
        loginPassword.text = "";
        loginShare = null;
        findMode = false;
        chooserFile = "";
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

        // Everything under the overlays. Blurred while the chooser or the F1
        // sheet is open: Hyprland only blurs what is behind the whole window,
        // so blur inside the card has to happen here.
        Item {
            id: cardContent

            anchors.fill: parent
            layer.enabled: rootPlacesPanel.chooserOpen || rootPlacesPanel.shortcutsOpen || rootPlacesPanel.loginOpen
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: rootPlacesPanel.pt.overlayBlurMax
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
                    text: rootPlacesPanel.findMode ? "Find" : "Places"
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

                    onTextEdited: {
                        if (rootPlacesPanel.findMode) {
                            detail.find(text);
                            return;
                        }
                        // Typing means "find a project": the file cards let go of the arrows.
                        detail.focusedCard = "";
                        rootPlacesPanel.service.setQuery(text);
                    }
                    Keys.onPressed: event => rootPlacesPanel.handleKey(event)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text.length === 0
                        text: rootPlacesPanel.findMode ? "find on this page: ↑↓ next match, Enter open, Esc back" : "type to filter projects"
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
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        bottom: tipCard.visible ? tipCard.top : parent.bottom
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

                // Tip of the open, zsh style. Click for the next one.
                Rectangle {
                    id: tipCard

                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 8
                    }
                    visible: rootPlacesPanel.tips.length > 0
                    height: tipText.implicitHeight + 2 * rootPlacesPanel.pt.cardPadding - 4
                    radius: rootPlacesPanel.pt.rowRadius
                    color: tipMouse.containsMouse ? rootPlacesPanel.pt.hoveredRowColor : rootPlacesPanel.pt.cardColor
                    border.width: 1
                    border.color: rootPlacesPanel.pt.withAlpha(rootPlacesPanel.pt.borderColor, 0.6)

                    Text {
                        id: tipIcon

                        x: rootPlacesPanel.pt.cardPadding - 2
                        y: rootPlacesPanel.pt.cardPadding - 3
                        text: "󰌵"
                        color: rootPlacesPanel.pt.warningColor
                        font.family: rootPlacesPanel.theme.iconFontFamily
                        font.pixelSize: rootPlacesPanel.pt.bodyPixelSize + 2
                    }

                    Text {
                        id: tipText

                        anchors {
                            left: tipIcon.right
                            leftMargin: 10
                            right: parent.right
                            rightMargin: rootPlacesPanel.pt.cardPadding
                        }
                        y: rootPlacesPanel.pt.cardPadding - 2
                        text: "<b>Tip</b>  " + (rootPlacesPanel.tips[rootPlacesPanel.tipIndex] || "")
                        textFormat: Text.StyledText
                        color: rootPlacesPanel.pt.secondaryTextColor
                        font.pixelSize: rootPlacesPanel.pt.metaPixelSize + 1
                        wrapMode: Text.Wrap
                    }

                    MouseArea {
                        id: tipMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootPlacesPanel.nextTip()
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

                onItemChosen: item => rootPlacesPanel.activateItem(item)
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
                text: "↑↓ move · ⇥ buttons · ↵ run · Alt+1–9 cards · ⇧↵ cockpit · ^E other editor · ^O folder · ^T terminal · ^R refresh · F1 shortcuts · Esc clear / close"
                color: rootPlacesPanel.pt.secondaryTextColor
                font.pixelSize: rootPlacesPanel.pt.metaPixelSize
                elide: Text.ElideRight
            }
        }

        // --- "Open with" chooser for a file -------------------------------------------
        Rectangle {
            anchors.fill: parent
            visible: rootPlacesPanel.chooserOpen
            color: rootPlacesPanel.pt.overlayColor
            radius: card.radius

            MouseArea {
                anchors.fill: parent
                onClicked: rootPlacesPanel.chooserFile = ""
            }

            Kip.KipChooser {
                anchors.centerIn: parent
                width: Math.min(560, parent.width - 80)
                kipTheme: rootPlacesPanel.theme.modules.kip
                iconFontFamily: rootPlacesPanel.theme.iconFontFamily
                title: rootPlacesPanel.service.shortPath(rootPlacesPanel.chooserFile)
                options: rootPlacesPanel.chooserOptions
                selectedIndex: rootPlacesPanel.chooserIndex

                onPicked: index => {
                    rootPlacesPanel.chooserIndex = index;
                    rootPlacesPanel.confirmChooser();
                }
            }
        }

        // --- SMB password dialog ---------------------------------------------------
        // The password only ever lives in loginPassword.text until it is
        // handed to the service, which pipes it to sh on stdin.
        Rectangle {
            anchors.fill: parent
            visible: rootPlacesPanel.loginOpen
            color: rootPlacesPanel.pt.overlayColor
            radius: card.radius

            MouseArea {
                anchors.fill: parent
                onClicked: rootPlacesPanel.closeLogin()
            }

            Rectangle {
                anchors.centerIn: parent
                width: 460
                height: loginColumn.implicitHeight + 2 * rootPlacesPanel.pt.panelPadding
                radius: rootPlacesPanel.pt.cardRadius
                color: rootPlacesPanel.pt.panelColor
                border.width: 1
                border.color: rootPlacesPanel.pt.selectedBorderColor

                MouseArea {
                    anchors.fill: parent
                }

                Column {
                    id: loginColumn

                    anchors {
                        fill: parent
                        margins: rootPlacesPanel.pt.panelPadding
                    }
                    spacing: 10

                    Text {
                        text: rootPlacesPanel.loginShare ? "󰒍  " + rootPlacesPanel.loginShare.label : ""
                        color: rootPlacesPanel.pt.primaryTextColor
                        font.family: rootPlacesPanel.theme.iconFontFamily
                        font.pixelSize: rootPlacesPanel.pt.bodyPixelSize + 2
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: (rootPlacesPanel.loginShare ? rootPlacesPanel.loginShare.key + (rootPlacesPanel.loginShare.user ? " as " + rootPlacesPanel.loginShare.user : "") + "\n" : "") + rootPlacesPanel.loginMessage
                        color: rootPlacesPanel.pt.secondaryTextColor
                        font.pixelSize: rootPlacesPanel.pt.metaPixelSize + 1
                        wrapMode: Text.Wrap
                    }

                    Rectangle {
                        width: loginColumn.width
                        height: 36
                        radius: 8
                        color: rootPlacesPanel.pt.searchColor
                        border.width: loginDomain.activeFocus ? 1 : 0
                        border.color: rootPlacesPanel.pt.selectedBorderColor

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: "Domain"
                            color: rootPlacesPanel.pt.secondaryTextColor
                            font.pixelSize: rootPlacesPanel.pt.metaPixelSize + 1
                        }

                        TextInput {
                            id: loginDomain

                            anchors {
                                left: parent.left
                                leftMargin: 92
                                right: parent.right
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            color: rootPlacesPanel.pt.primaryTextColor
                            font.pixelSize: rootPlacesPanel.pt.bodyPixelSize
                            clip: true
                            Keys.onPressed: event => rootPlacesPanel.handleLoginKey(event)
                        }
                    }

                    Rectangle {
                        width: loginColumn.width
                        height: 36
                        radius: 8
                        color: rootPlacesPanel.pt.searchColor
                        border.width: loginPassword.activeFocus ? 1 : 0
                        border.color: rootPlacesPanel.pt.selectedBorderColor

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: "Password"
                            color: rootPlacesPanel.pt.secondaryTextColor
                            font.pixelSize: rootPlacesPanel.pt.metaPixelSize + 1
                        }

                        TextInput {
                            id: loginPassword

                            anchors {
                                left: parent.left
                                leftMargin: 92
                                right: parent.right
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            echoMode: TextInput.Password
                            color: rootPlacesPanel.pt.primaryTextColor
                            font.pixelSize: rootPlacesPanel.pt.bodyPixelSize
                            clip: true
                            Keys.onPressed: event => rootPlacesPanel.handleLoginKey(event)
                        }
                    }

                    Rectangle {
                        width: loginColumn.width
                        height: 26
                        color: "transparent"

                        Row {
                            spacing: 8
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: rootPlacesPanel.loginRemember ? "󰄵" : "󰄱"
                                color: rootPlacesPanel.pt.accentColor
                                font.family: rootPlacesPanel.theme.iconFontFamily
                                font.pixelSize: rootPlacesPanel.pt.bodyPixelSize + 4
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Remember in GNOME Keyring  (Ctrl+K)"
                                color: rootPlacesPanel.pt.primaryTextColor
                                font.pixelSize: rootPlacesPanel.pt.metaPixelSize + 1
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootPlacesPanel.loginRemember = !rootPlacesPanel.loginRemember
                        }
                    }

                    Text {
                        text: "Enter connect · Tab switch field · Esc cancel"
                        color: rootPlacesPanel.pt.secondaryTextColor
                        font.pixelSize: rootPlacesPanel.pt.metaPixelSize
                    }
                }

            }
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

        if (chooserOpen && handleChooserKey(event))
            return;

        // Ctrl+/: find on this page. Ctrl+/ again or Esc leaves it.
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Slash) {
            event.accepted = true;
            setFindMode(!findMode);
            return;
        }

        if (findMode && handleFindKey(event))
            return;

        // Ctrl+1..9, Ctrl+0: select the 1st..10th entry, clearing the filter.
        if ((event.modifiers & Qt.ControlModifier) && event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            event.accepted = true;
            detail.focusedCard = "";
            service.selectEntryNumber(event.key === Qt.Key_0 ? 10 : event.key - Qt.Key_0);
            return;
        }

        // Alt+1..9: jump into the Nth card (project file cards, then blocks).
        if ((event.modifiers & Qt.AltModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            event.accepted = true;
            detail.focusCardNumber(event.key - Qt.Key_0);
            return;
        }

        if (detail.focusedCard.length > 0 && handleCardKey(event))
            return;

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
            // Buttons, then the file cards, then around again.
            detail.cycleFocus(event.key === Qt.Key_Backtab || shift ? -1 : 1);
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

    function setFindMode(on) {
        findMode = on;
        // Leaving find mode re-links the box to the project filter.
        if (on)
            search.text = "";
        else
            search.text = Qt.binding(() => service.query);
        if (on)
            detail.startFind();
        search.forceActiveFocus();
    }

    // While finding: arrows walk the matches, Enter opens, Esc leaves find
    // mode with the match still selected (arrows then work in its card).
    function handleFindKey(event) {
        switch (event.key) {
        case Qt.Key_Up:
        case Qt.Key_Down:
            detail.stepMatch(event.key === Qt.Key_Down ? 1 : -1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (detail.focusedItem())
                activateItem(detail.focusedItem());
            break;
        case Qt.Key_Escape:
            setFindMode(false);
            break;
        default:
            return false;
        }

        event.accepted = true;
        return true;
    }

    function handleLoginKey(event) {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true;
            closeLogin();
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            event.accepted = true;
            submitLogin();
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            event.accepted = true;
            (loginPassword.activeFocus ? loginDomain : loginPassword).forceActiveFocus();
        } else if (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)) {
            event.accepted = true;
            loginRemember = !loginRemember;
        }
    }

    // Arrows and Enter while a file card has focus. Returns true when used.
    function handleCardKey(event) {
        switch (event.key) {
        case Qt.Key_Up:
        case Qt.Key_Down:
            // A row of app tiles has no up/down inside it: change card instead.
            if (detail.focusedCardIsRow())
                detail.stepCard(event.key === Qt.Key_Down ? 1 : -1);
            else
                detail.moveFile(event.key === Qt.Key_Down ? 1 : -1);
            break;
        case Qt.Key_Left:
        case Qt.Key_Right:
            // App tiles: move along the row, leave the card only past its ends.
            if (detail.focusedCardIsRow() && detail.canMoveInRow(event.key === Qt.Key_Right ? 1 : -1))
                detail.moveFile(event.key === Qt.Key_Right ? 1 : -1);
            else
                detail.stepCard(event.key === Qt.Key_Right ? 1 : -1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (detail.focusedItem())
                activateItem(detail.focusedItem());
            break;
        case Qt.Key_Escape:
            detail.focusedCard = "";
            break;
        default:
            return false;
        }

        event.accepted = true;
        return true;
    }

    // Same options as KIP's file chooser (KipTheme.fileActions), with the
    // editor first and Vivify after it for markdown.
    // Card item picked: Open with for files and folders, launch for apps.
    function activateItem(item) {
        if (!item)
            return;

        // Calendar event: its page (Google has one), else nothing to open.
        if (item.kind === "event") {
            if (item.url.length > 0) {
                service.run(["xdg-open", item.url], service.home);
                closeRequested();
            }
            return;
        }

        // SMB share: open / terminal / mount / unmount / password.
        if (item.kind === "smb") {
            chooserTodo = null;
            chooserUsb = null;
            chooserSmb = item;
            chooserIsFile = false;
            chooserOptions = [{ id: "open", label: "Open", icon: "󰉋", hint: item.mounted ? "in yazi" : "mount, then yazi" }].concat(item.mounted ? [
                    { id: "terminal", label: "Terminal", icon: "󰆍", hint: theme.terminal + " in it" },
                    { id: "unmount", label: "Unmount", icon: "󰕔", hint: "gio mount -u" }
                ] : [
                    { id: "mount", label: "Mount", icon: "󰒍", hint: "no window" }
                ], [
                    { id: "password", label: "Change password", icon: "󰌋", hint: "ask now, save in the keyring" },
                    { id: "forget", label: "Forget password", icon: "󰆴", hint: "delete it from the keyring" }
                ]);
            chooserIndex = 0;
            chooserFile = item.label + "  (" + item.key + ")";
            return;
        }

        // USB drive: open / terminal / mount / unmount / eject.
        if (item.kind === "usb") {
            const mounted = item.mountpoint.length > 0;

            chooserTodo = null;
            chooserUsb = item;
            chooserIsFile = false;
            chooserOptions = [{ id: "open", label: "Open", icon: "󰉋", hint: mounted ? "in yazi" : "mount, then yazi" }].concat(mounted ? [
                    { id: "terminal", label: "Terminal", icon: "󰆍", hint: theme.terminal + " in it" },
                    { id: "unmount", label: "Unmount", icon: "󰕔", hint: "keep it plugged in" }
                ] : [
                    { id: "mount", label: "Mount", icon: "󰕓", hint: "no window" }
                ], [
                    { id: "eject", label: "Eject", icon: "󱊞", hint: "unmount and power off: safe to pull" }
                ]);
            chooserIndex = 0;
            chooserFile = item.label + "  (" + item.device + ")";
            return;
        }

        // SSH host: a terminal running ssh, straight away.
        if (item.kind === "ssh") {
            service.openSsh(item);
            closeRequested();
            return;
        }

        // Logseq todo: KIP's markdown openers, Logseq page first.
        if (item.kind === "todo") {
            const kt = theme.modules.kip;

            chooserTodo = item;
            chooserIsFile = false;
            chooserOptions = kipController ? kt.markdownOpeners : kt.markdownOpeners.filter(opener => opener.id !== "logseq");
            chooserIndex = 0;
            chooserFile = item.absolutePath;
            return;
        }

        if (item.kind === "app") {
            if (service.launchApp(item.id))
                closeRequested();
            return;
        }

        openChooser(item.path, item.kind === "folder");
    }

    // Documents and images open in their app; nvim is for text.
    readonly property var appFirstExtensions: ["pdf", "doc", "docx", "odt", "rtf", "xls", "xlsx", "ods", "ppt", "pptx", "odp", "png", "jpg", "jpeg", "gif", "webp", "svg", "mp4", "mkv", "mp3", "zip"]

    // KIP's actions (KipTheme.fileActions / folderActions). Files: editor
    // first, Vivify after it for markdown, except documents and images,
    // which put "Open with the default app" first.
    function openChooser(path, isFolder) {
        const kt = theme.modules.kip;

        chooserTodo = null;
        chooserUsb = null;
        chooserSmb = null;
        chooserIsFile = !isFolder;
        chooserMime = "";

        if (isFolder) {
            chooserOptions = kt.folderActions;
        } else {
            // Extension guess now; xdg-mime refines it a moment later.
            const extension = String(path).replace(/^.*\./, "").toLowerCase();
            const appFirst = appFirstExtensions.indexOf(extension) >= 0;
            const open = kt.fileActions.filter(action => action.id === "open");
            const editor = kt.fileActions.filter(action => action.id === "default");
            const rest = kt.fileActions.filter(action => action.id !== "default" && action.id !== "open");
            const vivify = /\.md$/i.test(path) ? kt.markdownOpeners.filter(opener => opener.id === "vivify") : [];

            chooserOptions = promoteRemembered(appFirst ? open.concat(editor, rest) : editor.concat(vivify, open, rest), path, "");
            service.inspectFile(path);
        }
        chooserIndex = 0;
        chooserFile = path;
    }

    // Two groups in the file chooser: "Open with" (apps: the default app or
    // every app that lists the type) and "Actions" (nvim, Vivify, folder,
    // terminal, copy path). Groups stay together; which comes first depends
    // on the file, and a remembered choice pulls its group up with it first.
    function isAppOption(option) {
        return option.id === "open" || option.id.indexOf("app:") === 0;
    }

    function arrangeFileChooser(options, path, mime, textFirst) {
        const remembered = service.openers[service.openerKey(path, mime)];
        const first = list => list.filter(option => option.id === remembered).concat(list.filter(option => option.id !== remembered));
        // The remembered app keeps a number key even when it is not the default.
        const apps = first(options.filter(option => isAppOption(option))).map(option => Object.assign({}, option, {
                    section: "Open with",
                    unnumbered: option.unnumbered === true && option.id !== remembered
                }));
        const actions = first(options.filter(option => !isAppOption(option))).map(option => Object.assign({}, option, {
                    section: "Actions"
                }));
        const actionsFirst = remembered ? actions.some(option => option.id === remembered) : textFirst;

        return actionsFirst ? actions.concat(apps) : apps.concat(actions);
    }

    // The quick, extension-based list before xdg-mime answers.
    function promoteRemembered(options, path, mime) {
        return arrangeFileChooser(options, path, mime, options.length > 0 && !isAppOption(options[0]));
    }

    // xdg-mime answered: one option per app that can open the type (the
    // default first) instead of a single "Open"; text puts Actions (nvim)
    // first, everything else its apps.
    function refineFileChooser(path, mime, appName, apps) {
        const appOptions = (apps || []).map(app => ({
                    id: "app:" + app.id,
                    label: app.name,
                    hint: app.isDefault ? "default app" : "can open it",
                    // Only the default app gets a number key; the rest are
                    // there for the arrows, so the actions keep low numbers.
                    unnumbered: !app.isDefault,
                    icon: "󰏌",
                    command: ["gio", "launch", app.desktopFile, "{path}"]
                }));
        const named = appOptions.length > 0 ? chooserOptions.filter(option => option.id !== "open").concat(appOptions) : chooserOptions.map(option => option.id === "open" && appName ? Object.assign({}, option, {
                    hint: "in " + appName
                }) : option);
        // Inside Actions the editor leads: nvim, Vivify, then the rest.
        const editor = named.filter(option => option.id === "default" || option.id === "vivify");
        const others = named.filter(option => option.id !== "default" && option.id !== "vivify");

        chooserOptions = arrangeFileChooser(editor.concat(others), path, mime, mime.length > 0 && service.isTextMime(mime));
        chooserIndex = 0;
    }

    function handleChooserKey(event) {
        const count = chooserOptions.length;

        switch (event.key) {
        case Qt.Key_Escape:
            chooserFile = "";
            break;
        case Qt.Key_Up:
        case Qt.Key_Down:
            chooserIndex = Math.max(0, Math.min(count - 1, chooserIndex + (event.key === Qt.Key_Down ? 1 : -1)));
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            confirmChooser();
            break;
        default:
            {
                // Keys count numbered options only (KipChooser.numberLabel).
                const wanted = event.key - Qt.Key_0;
                let seen = 0;
                const index = chooserOptions.findIndex(option => !option.unnumbered && ++seen === wanted);

                if (wanted < 1 || wanted > 9 || index < 0)
                    return false;
                chooserIndex = index;
                confirmChooser();
            }
        }

        event.accepted = true;
        return true;
    }

    // Fills KIP's placeholders the way Kip.fill() does: {path}, {line}, {dir}.
    function confirmChooser() {
        const project = service.selected;
        const option = chooserOptions[chooserIndex];
        // Blocks hand over absolute paths; project cards relative ones.
        const path = chooserFile.indexOf("/") === 0 ? chooserFile : (project ? project.path + "/" + chooserFile : "");
        const cwd = project && project.path ? project.path : service.home;
        const todo = chooserTodo;
        const usb = chooserUsb;
        const smb = chooserSmb;

        chooserFile = "";
        chooserTodo = null;
        chooserUsb = null;

        chooserSmb = null;

        // SMB: password goes through the dialog; the rest through the service.
        if (smb && option) {
            if (option.id === "password") {
                openLogin(smb, "Enter the password. It is saved in GNOME Keyring if you keep the box ticked.");
                return;
            }
            service.smbAction(smb, option.id);
            if (option.id === "open" || option.id === "terminal")
                closeRequested();
            return;
        }

        // USB: udisksctl through the service. Only opening leaves Places.
        if (usb && option) {
            service.usbAction(usb, option.id);
            if (option.id === "open" || option.id === "terminal")
                closeRequested();
            return;
        }

        if (!option || path.length === 0)
            return;

        if (todo && kipController) {
            kipController.runAction(todo, option);
            closeRequested();
            return;
        }

        const values = {
            path: path,
            line: todo ? String(todo.line) : "1",
            dir: path.replace(/\/[^\/]*$/, "") || "/"
        };
        const command = option.command.map(part => String(part).replace(/\{(\w+)\}/g, (match, key) => values[key] !== undefined ? values[key] : match));

        if (chooserIsFile)
            service.rememberOpener(path, option.id, chooserMime);

        service.run(command, cwd);
        // Copying a path is not a launch; Places stays for the next click.
        if (option.id !== "copy-path")
            closeRequested();
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

        // A place has no editor or cockpit, and no folder actions without a folder.
        if (project.kind === "place" && (action === "editor" || action === "cockpit" || action === "other-editor" || !project.path) && action !== "selected")
            return;

        if (action === "selected") {
            if (detail.actions.length === 0)
                return;
            detail.runAction(detail.actions[detail.actionIndex]);
        } else if (action === "editor")
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
