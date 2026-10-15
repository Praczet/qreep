import QtQuick
import Quickshell
import Quickshell.Wayland

// KIP surface. All opening/closing geometry derives from one number,
// openProgress (0 → 1), so a toggle mid-animation just reverses direction.
// Content state (compose vs. service results) is separate from motion.
PanelWindow {
    id: rootKipPanel

    required property QtObject theme
    required property QtObject commands
    required property QtObject messages
    required property QtObject service
    required property QtObject shots
    required property QtObject files
    required property QtObject tldr
    required property bool panelOpen

    signal closeRequested
    // Dragging the bottom edge; the controller keeps it so a reopen remembers.
    signal bodyLimitRequested(real limit)
    signal closeFinished
    // option is an entry of markdownOpeners / screenshotActions (or the plain
    // default opener); the controller runs its command for item.
    signal actionRequested(var item, var option)
    signal copyRequested(string text)

    readonly property QtObject kt: theme.modules.kip

    property real openProgress: 0
    readonly property var parsed: commands.parse(promptInput.text)

    // compose: reacting to typing. service: a submitted notes/ask/general
    // request. shots: /last screenshots. files: /fd. doc: static markdown
    // (/help) shown in the answer viewer.
    property string contentState: "compose"
    property int paletteIndex: 0
    property int resultIndex: 0
    property int shotIndex: 0
    property int fileIndex: 0
    property bool hasInteracted: false
    // Original retrieved text of the selected hit, toggled with Tab.
    property bool showSnippet: false
    // Item waiting for an action choice ("Open with", screenshot actions);
    // null when the chooser is closed.
    property var chooserHit: null
    property var chooserOptions: []
    property string chooserTitle: ""
    property int chooserIndex: 0
    property string notice: ""
    property string currentMessage: ""
    property string docMarkdown: ""
    // help | tldr; and the message key a doc wants (empty: use the command's).
    property string docKind: ""
    property string docEventKey: ""
    // service.answer as rich text, rebuilt at most every answerRenderInterval
    // while streaming so the document is not re-parsed per token.
    property var renderedAnswer: ({
            html: "",
            codeBlocks: []
        })

    readonly property string messageKey: contentState === "service" ? service.eventKey : contentState === "shots" ? shots.eventKey : contentState === "files" ? files.eventKey : contentState === "doc" && docEventKey.length > 0 ? docEventKey : (parsed.mode === "idle" && !hasInteracted ? "kip.open" : parsed.eventKey)
    readonly property bool paletteVisible: contentState === "compose" && (parsed.mode === "palette" || parsed.mode === "candidate" || parsed.mode === "unknown" || (parsed.mode === "ready" && parsed.command && !parsed.command.takesArgument))
    readonly property var paletteItems: paletteVisible ? parsed.matches : []
    readonly property bool resultsVisible: contentState === "service" && service.results.length > 0
    readonly property bool shotsVisible: contentState === "shots" && shots.shots.length > 0
    readonly property int shotColumns: Math.max(1, Math.min(kt.screenshotColumns, shots.shots.length))
    readonly property var shownFiles: files.results.slice(0, kt.fdShownResults)
    readonly property bool filesVisible: contentState === "files" && shownFiles.length > 0

    readonly property string phase: {
        if (!panelOpen)
            return openProgress > 0 ? "closing" : "hidden";
        if (openProgress < kt.signalEnd)
            return "signal";
        if (openProgress < kt.descendEnd)
            return "descend";
        if (openProgress < kt.morphEnd)
            return "morph";
        if (openProgress < 1)
            return "assemble";
        if (contentState === "service")
            return service.busy ? "processing" : (service.status === "error" ? "error" : "results");
        return "ready";
    }

    // Motion slices, each eased on its own.
    readonly property real signalT: ease(segment(0, kt.signalEnd))
    readonly property real descendT: ease(segment(kt.signalEnd, kt.descendEnd))
    readonly property real morphT: ease(segment(kt.descendEnd, kt.morphEnd))
    readonly property real inputContentT: ease(segment(kt.descendEnd + (kt.morphEnd - kt.descendEnd) * 0.5, kt.morphEnd))
    readonly property real headerT: ease(segment(kt.morphEnd, kt.morphEnd + (1 - kt.morphEnd) * 0.6))
    readonly property real bodyT: ease(segment(kt.morphEnd + (1 - kt.morphEnd) * 0.3, 1))

    // Geometry.
    readonly property real cardWidth: Math.max(0, Math.min(kt.panelWidth, width - kt.screenMargin * 2))
    readonly property real inputFinalWidth: cardWidth - kt.cardPadding * 2
    readonly property real inputCenterY: kt.anchorY + kt.inputHeight / 2
    readonly property real lineCenterY: lerp(kt.signalTopY, inputCenterY, descendT)
    readonly property real lineWidth: lerp(kt.lineStartWidth * signalT, inputFinalWidth * kt.lineDescendWidthRatio, descendT)
    readonly property real boxWidth: lerp(lineWidth, inputFinalWidth, morphT)
    readonly property real boxHeight: lerp(kt.lineHeight, kt.inputHeight, morphT)
    readonly property real boxX: (width - boxWidth) / 2
    readonly property real boxY: lineCenterY - boxHeight / 2
    // Height cap for the body: the theme default, or what the bottom edge was
    // dragged to (userBodyLimit > 0), never past the bottom of the screen.
    property real userBodyLimit: 0
    property bool resizing: false
    readonly property real availableBodyHeight: height - (kt.anchorY + kt.inputHeight + kt.bodyGap + kt.cardPadding + kt.screenMargin)
    readonly property real maxBodyHeight: Math.max(80, Math.min(userBodyLimit > 0 ? userBodyLimit : kt.maxBodyHeight, availableBodyHeight))
    // The answer gets whatever the drag added on top of the default.
    readonly property real answerLimit: kt.answerMaxHeight + Math.max(0, maxBodyHeight - kt.maxBodyHeight)
    property real bodyAreaHeight: Math.min(bodyContent.implicitHeight, maxBodyHeight)

    Behavior on bodyAreaHeight {
        // Off while dragging, or the edge lags behind the pointer.
        enabled: !rootKipPanel.kt.reducedMotion && rootKipPanel.openProgress >= 1 && !rootKipPanel.resizing

        NumberAnimation {
            duration: rootKipPanel.kt.bodyResizeDuration
            easing.type: Easing.OutCubic
        }
    }

    implicitWidth: screen ? screen.width : 1280
    implicitHeight: screen ? screen.height : 720

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    // While closing, let clicks fall through instead of eating them for 300ms.
    mask: panelOpen ? null : passThroughRegion

    WlrLayershell.namespace: "qreep-kip"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: panelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property Region passThroughRegion: Region {}

    Component.onCompleted: {
        promptInput.forceActiveFocus();
        refreshMessage();
        if (panelOpen)
            animateTo(1);
    }

    onPanelOpenChanged: {
        if (panelOpen)
            promptInput.forceActiveFocus();
        animateTo(panelOpen ? 1 : 0);
    }

    onMessageKeyChanged: refreshMessage()

    KipMarkdown {
        id: markdown

        kipTheme: rootKipPanel.kt
    }

    Timer {
        id: answerRenderTimer

        interval: rootKipPanel.kt.answerRenderInterval
        repeat: false
        onTriggered: rootKipPanel.renderAnswer()
    }

    Connections {
        target: rootKipPanel.service

        function onAnswerChanged() {
            // Throttle, not debounce: a steady stream still repaints.
            if (rootKipPanel.service.answer.length === 0)
                rootKipPanel.renderAnswer();
            else if (!answerRenderTimer.running)
                answerRenderTimer.start();
        }

        function onStatusChanged() {
            if (!rootKipPanel.service.busy)
                rootKipPanel.renderAnswer();
        }
    }

    // /tldr looks up after a pause, so "ta" on the way to "tar" stays quiet.
    Timer {
        id: tldrTimer

        interval: rootKipPanel.kt.tldrDebounce
        repeat: false
        onTriggered: {
            if (rootKipPanel.liveTldrWanted()) {
                rootKipPanel.tldr.lookup(rootKipPanel.parsed.argument);
                rootKipPanel.showTldr();
            }
        }
    }

    // The cache probe answers asynchronously for missing pages.
    Connections {
        target: rootKipPanel.tldr

        function onStatusChanged() {
            if (rootKipPanel.liveTldrWanted())
                rootKipPanel.showTldr();
        }
    }

    // /fd searches after a pause in typing, not per keystroke.
    Timer {
        id: fileSearchTimer

        interval: rootKipPanel.kt.fdDebounce
        repeat: false
        onTriggered: {
            if (rootKipPanel.liveFilesWanted())
                rootKipPanel.runFiles();
        }
    }

    // Typing "/last 12" refreshes once, not once per digit.
    Timer {
        id: shotRefreshTimer

        interval: 120
        repeat: false
        onTriggered: {
            if (rootKipPanel.liveShotsWanted())
                rootKipPanel.runShots(rootKipPanel.parsed.argument);
        }
    }

    NumberAnimation {
        id: progressAnimation

        target: rootKipPanel
        property: "openProgress"
        easing.type: Easing.Linear

        onStopped: {
            if (!rootKipPanel.panelOpen && rootKipPanel.openProgress <= 0)
                rootKipPanel.closeFinished();
        }
    }

    // Outside click closes.
    MouseArea {
        anchors.fill: parent
        enabled: rootKipPanel.panelOpen
        onClicked: rootKipPanel.closeRequested()
    }

    // Glow: brightest mid-morph, settles to a faint focus halo.
    Rectangle {
        x: rootKipPanel.boxX - 3
        y: rootKipPanel.boxY - 3
        width: rootKipPanel.boxWidth + 6
        height: rootKipPanel.boxHeight + 6
        radius: rootKipPanel.lerp(2, rootKipPanel.kt.inputRadius + 3, rootKipPanel.morphT)
        color: "transparent"
        border.width: 3
        border.color: rootKipPanel.kt.glowColor
        opacity: rootKipPanel.signalT * (0.45 + 0.55 * Math.sin(Math.PI * rootKipPanel.morphT)) * (1 - 0.6 * rootKipPanel.headerT)
        visible: opacity > 0.01
    }

    // The card assembles outward from the input box.
    Rectangle {
        id: card

        readonly property real topExtent: (rootKipPanel.kt.cardPadding + rootKipPanel.kt.headerHeight + rootKipPanel.kt.headerGap) * rootKipPanel.headerT
        readonly property real bottomExtent: rootKipPanel.kt.cardPadding * rootKipPanel.headerT + (rootKipPanel.kt.bodyGap + rootKipPanel.bodyAreaHeight) * rootKipPanel.bodyT

        x: rootKipPanel.boxX - rootKipPanel.kt.cardPadding * rootKipPanel.headerT
        y: rootKipPanel.boxY - topExtent
        width: rootKipPanel.boxWidth + rootKipPanel.kt.cardPadding * 2 * rootKipPanel.headerT
        height: rootKipPanel.boxHeight + topExtent + bottomExtent
        radius: rootKipPanel.kt.cardRadius
        color: rootKipPanel.kt.cardColor
        border.width: 1
        border.color: rootKipPanel.kt.borderColor
        opacity: rootKipPanel.headerT
        visible: opacity > 0.01

        // Swallow clicks so the outside-click catcher does not close KIP.
        MouseArea {
            anchors.fill: parent
            onClicked: promptInput.forceActiveFocus()
        }
    }

    // Header: slides up from behind the input; icon drifts left, status right.
    Item {
        id: header

        x: rootKipPanel.boxX
        y: rootKipPanel.boxY - rootKipPanel.kt.headerGap - rootKipPanel.kt.headerHeight + (1 - rootKipPanel.headerT) * rootKipPanel.kt.headerHeight * 0.7
        width: rootKipPanel.boxWidth
        height: rootKipPanel.kt.headerHeight
        opacity: rootKipPanel.headerT
        visible: opacity > 0.01

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: (1 - rootKipPanel.headerT) * 36
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: rootKipPanel.kt.kipIcon
                color: rootKipPanel.kt.accentColor
                font.family: rootKipPanel.theme.iconFontFamily
                font.pixelSize: rootKipPanel.kt.headerIconPixelSize
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "KIP"
                color: rootKipPanel.kt.primaryTextColor
                font.pixelSize: rootKipPanel.kt.titlePixelSize
                font.bold: true
                font.letterSpacing: 2
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Knowledge & Intelligence Presence"
                color: rootKipPanel.kt.secondaryTextColor
                font.pixelSize: rootKipPanel.kt.subtitlePixelSize
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width - width - (1 - rootKipPanel.headerT) * 36
            width: statusRow.implicitWidth + 16
            height: statusRow.implicitHeight + 8
            radius: rootKipPanel.kt.chipRadius
            color: rootKipPanel.kt.chipColor

            Row {
                id: statusRow

                anchors.centerIn: parent
                spacing: 6

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 7
                    height: 7
                    radius: 4
                    // Mock backend: amber, not green. Green is for things that exist.
                    color: rootKipPanel.service.status === "error" || !rootKipPanel.service.backendAvailable ? rootKipPanel.kt.errorColor : (rootKipPanel.service.mock ? rootKipPanel.kt.warningColor : rootKipPanel.kt.successColor)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: rootKipPanel.service.mock ? "Local AI · mock" : (rootKipPanel.service.model.length > 0 ? "Local AI · " + rootKipPanel.service.model : "Local AI")
                    color: rootKipPanel.kt.secondaryTextColor
                    font.pixelSize: rootKipPanel.kt.metaPixelSize
                }
            }
        }
    }

    // Body: unfolds downward under the input, clipped while it grows.
    Item {
        id: body

        x: rootKipPanel.boxX
        y: rootKipPanel.boxY + rootKipPanel.boxHeight + rootKipPanel.kt.bodyGap
        width: rootKipPanel.boxWidth
        height: rootKipPanel.bodyAreaHeight * rootKipPanel.bodyT
        opacity: rootKipPanel.bodyT
        visible: height > 0.5
        clip: true

        Column {
            id: bodyContent

            width: parent.width
            spacing: 10

            // Microcopy. Changes only when messageKey changes.
            Text {
                id: messageText

                width: parent.width
                text: rootKipPanel.currentMessage
                visible: text.length > 0
                color: rootKipPanel.contentState === "service" && rootKipPanel.service.status === "error" ? rootKipPanel.kt.errorColor : rootKipPanel.kt.secondaryTextColor
                font.pixelSize: rootKipPanel.kt.bodyPixelSize
                font.italic: true
                wrapMode: Text.WordWrap
            }

            // Recognized command with an argument slot (/ask, /notes).
            Column {
                width: parent.width
                spacing: 6
                visible: rootKipPanel.contentState === "compose" && rootKipPanel.parsed.mode === "ready" && rootKipPanel.parsed.command !== null && rootKipPanel.parsed.command.takesArgument

                Row {
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: rootKipPanel.parsed.command ? rootKipPanel.parsed.command.icon : ""
                        color: rootKipPanel.kt.accentColor
                        font.family: rootKipPanel.theme.iconFontFamily
                        font.pixelSize: rootKipPanel.kt.iconPixelSize
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: rootKipPanel.parsed.command ? rootKipPanel.parsed.command.label : ""
                        color: rootKipPanel.kt.primaryTextColor
                        font.pixelSize: rootKipPanel.kt.bodyPixelSize + 1
                        font.bold: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: rootKipPanel.parsed.command ? rootKipPanel.parsed.command.sourceHint : ""
                        color: rootKipPanel.kt.tertiaryAccentColor
                        font.pixelSize: rootKipPanel.kt.metaPixelSize
                    }
                }

                Text {
                    width: parent.width
                    text: rootKipPanel.parsed.command ? rootKipPanel.parsed.command.description + " " + rootKipPanel.parsed.command.helper : ""
                    color: rootKipPanel.kt.primaryTextColor
                    font.pixelSize: rootKipPanel.kt.bodyPixelSize
                    wrapMode: Text.WordWrap
                }
            }

            // Plain text: explicit, simulated general-question mode.
            Row {
                spacing: 8
                visible: rootKipPanel.contentState === "compose" && rootKipPanel.parsed.mode === "plain"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍩"
                    color: rootKipPanel.kt.accentColor
                    font.family: rootKipPanel.theme.iconFontFamily
                    font.pixelSize: rootKipPanel.kt.iconPixelSize
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "General question"
                    color: rootKipPanel.kt.primaryTextColor
                    font.pixelSize: rootKipPanel.kt.bodyPixelSize + 1
                    font.bold: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "no notes as context · simulated in Phase 1"
                    color: rootKipPanel.kt.tertiaryAccentColor
                    font.pixelSize: rootKipPanel.kt.metaPixelSize
                }
            }

            // Command palette: "/", partial commands, unknown commands, /help.
            Column {
                width: parent.width
                spacing: rootKipPanel.kt.rowGap
                visible: rootKipPanel.paletteVisible

                Repeater {
                    model: rootKipPanel.paletteItems

                    Rectangle {
                        id: commandRow

                        required property var modelData
                        required property int index

                        readonly property bool selected: index === rootKipPanel.paletteIndex

                        width: parent.width
                        height: rootKipPanel.kt.commandRowHeight
                        radius: rootKipPanel.kt.rowRadius
                        color: selected ? rootKipPanel.kt.selectedRowColor : (commandMouse.containsMouse ? rootKipPanel.kt.hoveredRowColor : "transparent")
                        border.width: selected ? 1 : 0
                        border.color: rootKipPanel.kt.focusBorderColor

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 10
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                text: commandRow.modelData.icon
                                color: rootKipPanel.kt.accentColor
                                font.family: rootKipPanel.theme.iconFontFamily
                                font.pixelSize: rootKipPanel.kt.iconPixelSize
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 90
                                text: "/" + commandRow.modelData.name
                                color: rootKipPanel.kt.primaryTextColor
                                font.pixelSize: rootKipPanel.kt.bodyPixelSize
                                font.bold: true
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: commandRow.width - 160
                                text: commandRow.modelData.description
                                color: rootKipPanel.kt.secondaryTextColor
                                font.pixelSize: rootKipPanel.kt.bodyPixelSize - 1
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: commandMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                rootKipPanel.paletteIndex = commandRow.index;
                                rootKipPanel.complete(commandRow.modelData);
                            }
                        }
                    }
                }
            }

            // Service status line: real events only (mock events in Phase 1).
            Row {
                spacing: 8
                visible: rootKipPanel.contentState === "service"

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    visible: rootKipPanel.service.busy

                    Repeater {
                        model: 3

                        Rectangle {
                            id: dot

                            required property int index

                            width: 5
                            height: 5
                            radius: 3
                            color: rootKipPanel.kt.accentColor

                            SequentialAnimation on opacity {
                                running: rootKipPanel.service.busy && !rootKipPanel.kt.reducedMotion
                                loops: Animation.Infinite

                                PauseAnimation {
                                    duration: dot.index * 120
                                }
                                NumberAnimation {
                                    from: 0.25
                                    to: 1
                                    duration: 260
                                }
                                NumberAnimation {
                                    from: 1
                                    to: 0.25
                                    duration: 260
                                }
                                PauseAnimation {
                                    duration: (2 - dot.index) * 120
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: rootKipPanel.statusLabel()
                    color: rootKipPanel.kt.tertiaryAccentColor
                    font.pixelSize: rootKipPanel.kt.metaPixelSize
                }
            }

            Text {
                width: parent.width
                visible: rootKipPanel.contentState === "service" && rootKipPanel.service.status === "error"
                text: rootKipPanel.service.errorText
                color: rootKipPanel.kt.errorColor
                font.pixelSize: rootKipPanel.kt.bodyPixelSize
                wrapMode: Text.WordWrap
            }

            // Ask sources come before the answer: evidence first, prose second.
            KipResultList {
                width: parent.width
                height: Math.min(contentHeight, rootKipPanel.maxBodyHeight * (rootKipPanel.service.kind === "search" ? 0.8 : 0.4))
                visible: rootKipPanel.resultsVisible
                kipTheme: rootKipPanel.kt
                results: rootKipPanel.service.results
                compact: rootKipPanel.service.kind === "ask"
                currentIndex: rootKipPanel.resultIndex

                onActivated: index => {
                    rootKipPanel.resultIndex = index;
                    rootKipPanel.activateResult();
                }
            }

            // /last: newest screenshots. One gets a big preview, more get a grid.
            Text {
                width: parent.width
                visible: rootKipPanel.contentState === "shots"
                text: rootKipPanel.shotsStatus()
                color: rootKipPanel.shots.status === "error" ? rootKipPanel.kt.errorColor : rootKipPanel.kt.tertiaryAccentColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideMiddle
            }

            // /fd: files and folders, best guesses first.
            Text {
                width: parent.width
                visible: rootKipPanel.contentState === "files"
                text: rootKipPanel.filesStatus()
                color: rootKipPanel.files.status === "error" ? rootKipPanel.kt.errorColor : rootKipPanel.kt.tertiaryAccentColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideMiddle
            }

            KipResultList {
                width: parent.width
                height: Math.min(contentHeight, rootKipPanel.maxBodyHeight * 0.75)
                visible: rootKipPanel.filesVisible
                kipTheme: rootKipPanel.kt
                results: rootKipPanel.shownFiles
                compact: true
                currentIndex: rootKipPanel.fileIndex

                onActivated: index => {
                    rootKipPanel.fileIndex = index;
                    rootKipPanel.activateFile();
                }
            }

            KipShotGrid {
                width: parent.width
                visible: rootKipPanel.shotsVisible
                kipTheme: rootKipPanel.kt
                shots: rootKipPanel.shots
                columns: rootKipPanel.shotColumns
                selectedIndex: rootKipPanel.shotIndex
                maxHeight: rootKipPanel.maxBodyHeight * 0.75

                onActivated: index => {
                    rootKipPanel.shotIndex = index;
                    rootKipPanel.activateShot();
                }
            }

            KipChooser {
                width: parent.width
                visible: rootKipPanel.chooserHit !== null
                kipTheme: rootKipPanel.kt
                iconFontFamily: rootKipPanel.theme.iconFontFamily
                title: rootKipPanel.chooserTitle
                options: rootKipPanel.chooserOptions
                selectedIndex: rootKipPanel.chooserIndex

                onPicked: index => {
                    rootKipPanel.chooserIndex = index;
                    rootKipPanel.confirmChooser();
                }
            }

            // The retrieved text itself, for when the model's paraphrase of
            // SQL or code should not be trusted with your evening.
            Rectangle {
                id: snippetBox

                readonly property var hit: rootKipPanel.resultsVisible ? rootKipPanel.service.results[rootKipPanel.resultIndex] : null

                width: parent.width
                height: Math.min(snippetText.implicitHeight + 16, rootKipPanel.kt.snippetMaxHeight)
                visible: rootKipPanel.showSnippet && hit !== null && hit !== undefined
                radius: rootKipPanel.kt.rowRadius
                color: rootKipPanel.kt.inputColor
                border.width: 1
                border.color: rootKipPanel.kt.borderColor
                clip: true

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 8
                    contentHeight: snippetText.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    Text {
                        id: snippetText

                        width: parent.width
                        text: snippetBox.hit ? (snippetBox.hit.snippet || "") : ""
                        color: rootKipPanel.kt.primaryTextColor
                        font.family: rootKipPanel.kt.monoFontFamily
                        font.pixelSize: rootKipPanel.kt.metaPixelSize + 1
                        wrapMode: Text.WrapAnywhere
                        textFormat: Text.PlainText
                    }
                }
            }

            // One growing answer, never a pile of bubbles. A single read-only
            // TextEdit so a selection can span the whole answer. It follows the
            // stream only while the reader is at the bottom.
            Flickable {
                id: answerFlick

                property bool follow: true
                property bool autoScrolling: false

                width: parent.width
                height: Math.min(answerText.implicitHeight, rootKipPanel.answerLimit)
                visible: (rootKipPanel.contentState === "service" && rootKipPanel.service.answer.length > 0) || (rootKipPanel.contentState === "doc" && rootKipPanel.docMarkdown.length > 0)
                contentHeight: answerText.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                onContentYChanged: {
                    if (!autoScrolling)
                        follow = contentY >= contentHeight - height - 8;
                }

                onContentHeightChanged: {
                    if (!follow || contentHeight <= height)
                        return;
                    autoScrolling = true;
                    contentY = contentHeight - height;
                    autoScrolling = false;
                }

                TextEdit {
                    id: answerText

                    width: answerFlick.width
                    text: rootKipPanel.renderedAnswer.html
                    textFormat: TextEdit.RichText
                    readOnly: true
                    selectByMouse: true
                    persistentSelection: true
                    wrapMode: TextEdit.Wrap
                    color: rootKipPanel.kt.primaryTextColor
                    selectionColor: rootKipPanel.kt.selectedRowColor
                    selectedTextColor: rootKipPanel.kt.primaryTextColor
                    font.pixelSize: rootKipPanel.kt.answerPixelSize

                    onLinkActivated: link => rootKipPanel.answerLink(link)
                    Keys.onPressed: event => rootKipPanel.answerKey(event)

                    HoverHandler {
                        cursorShape: answerText.hoveredLink.length > 0 ? Qt.PointingHandCursor : Qt.IBeamCursor
                    }
                }
            }

            Text {
                width: parent.width
                visible: rootKipPanel.notice.length > 0
                text: rootKipPanel.notice
                color: rootKipPanel.kt.warningColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize + 1
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                text: rootKipPanel.keyHints()
                color: rootKipPanel.kt.secondaryTextColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideRight
            }
        }
    }

    // The line, then the input box. Same geometry; they crossfade during morph.
    Rectangle {
        x: rootKipPanel.boxX
        y: rootKipPanel.boxY
        width: rootKipPanel.boxWidth
        height: rootKipPanel.boxHeight
        radius: Math.min(height / 2, rootKipPanel.lerp(1, rootKipPanel.kt.inputRadius, rootKipPanel.morphT))
        color: rootKipPanel.kt.lineColor
        opacity: rootKipPanel.signalT * (1 - rootKipPanel.morphT)
        visible: opacity > 0.01
    }

    Rectangle {
        id: inputBox

        x: rootKipPanel.boxX
        y: rootKipPanel.boxY
        width: rootKipPanel.boxWidth
        height: rootKipPanel.boxHeight
        radius: Math.min(height / 2, rootKipPanel.lerp(1, rootKipPanel.kt.inputRadius, rootKipPanel.morphT))
        color: rootKipPanel.kt.inputColor
        border.width: 1
        border.color: promptInput.activeFocus ? rootKipPanel.kt.focusBorderColor : rootKipPanel.kt.borderColor
        opacity: rootKipPanel.morphT
        clip: true

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: promptInput.forceActiveFocus()
        }

        Text {
            id: inputIcon

            anchors.verticalCenter: parent.verticalCenter
            x: rootKipPanel.kt.inputPadding
            width: rootKipPanel.kt.inputIconWidth
            opacity: rootKipPanel.inputContentT
            text: rootKipPanel.parsed.mode === "ready" && rootKipPanel.parsed.command ? rootKipPanel.parsed.command.icon : (rootKipPanel.parsed.mode === "plain" ? "󰍩" : rootKipPanel.kt.kipIcon)
            color: rootKipPanel.kt.accentColor
            font.family: rootKipPanel.theme.iconFontFamily
            font.pixelSize: rootKipPanel.kt.iconPixelSize
        }

        // Flag chips, e.g. "--f=/". Red outline for flags /fd does not know.
        Repeater {
            model: rootKipPanel.parsed.flagRanges

            Rectangle {
                required property var modelData

                readonly property real startX: promptInput.text.length >= 0 ? promptInput.positionToRectangle(modelData.start).x : 0
                readonly property real endX: promptInput.text.length >= 0 ? promptInput.positionToRectangle(Math.min(promptInput.text.length, modelData.end)).x : 0

                anchors.verticalCenter: parent.verticalCenter
                x: promptInput.x + startX - 3
                width: endX - startX + 6
                height: promptInput.height + 4
                radius: rootKipPanel.kt.chipRadius
                color: modelData.known ? rootKipPanel.kt.commandHighlightColor : "transparent"
                border.width: 1
                border.color: modelData.known ? rootKipPanel.kt.focusBorderColor : rootKipPanel.kt.errorColor
                opacity: rootKipPanel.inputContentT
            }
        }

        // Highlight behind the recognized command token, e.g. "/ask".
        Rectangle {
            readonly property bool active: rootKipPanel.parsed.mode === "ready" || (rootKipPanel.parsed.mode === "candidate" && rootKipPanel.parsed.command !== null)
            readonly property real startX: promptInput.text.length >= 0 ? promptInput.positionToRectangle(0).x : 0
            readonly property real endX: promptInput.text.length >= 0 ? promptInput.positionToRectangle(Math.min(promptInput.text.length, rootKipPanel.parsed.token.length + 1)).x : 0

            anchors.verticalCenter: parent.verticalCenter
            x: promptInput.x + startX - 5
            width: endX - startX + 10
            height: promptInput.height + 6
            radius: rootKipPanel.kt.chipRadius
            color: rootKipPanel.kt.commandHighlightColor
            border.width: 1
            border.color: rootKipPanel.parsed.mode === "ready" ? rootKipPanel.kt.focusBorderColor : "transparent"
            opacity: active ? rootKipPanel.inputContentT : 0
            visible: opacity > 0.01

            Behavior on opacity {
                enabled: !rootKipPanel.kt.reducedMotion

                NumberAnimation {
                    duration: rootKipPanel.kt.contentFadeDuration
                }
            }
        }

        TextInput {
            id: promptInput

            anchors.verticalCenter: parent.verticalCenter
            x: inputIcon.x + inputIcon.width + 6
            width: parent.width - x - enterHint.width - rootKipPanel.kt.inputPadding * 2
            // Focused from frame one; only its opacity waits for the morph.
            opacity: rootKipPanel.inputContentT
            color: rootKipPanel.kt.primaryTextColor
            selectionColor: rootKipPanel.kt.selectedRowColor
            selectedTextColor: rootKipPanel.kt.primaryTextColor
            font.pixelSize: rootKipPanel.kt.inputPixelSize
            clip: true
            focus: true

            onTextChanged: rootKipPanel.handleTextChanged()

            Keys.onPressed: event => rootKipPanel.handleKey(event)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: promptInput.text.length === 0 || (rootKipPanel.parsed.mode === "ready" && rootKipPanel.parsed.argument.length === 0 && rootKipPanel.parsed.command && rootKipPanel.parsed.command.takesArgument)
                x: promptInput.text.length === 0 ? 0 : promptInput.contentWidth + 2
                text: promptInput.text.length === 0 ? "Ask, search, or type / for commands" : (rootKipPanel.parsed.command ? (promptInput.text.endsWith(" ") ? "" : " ") + rootKipPanel.parsed.command.placeholder : "")
                color: rootKipPanel.kt.secondaryTextColor
                font: promptInput.font
            }
        }

        Rectangle {
            id: enterHint

            readonly property string label: rootKipPanel.enterLabel()

            anchors.verticalCenter: parent.verticalCenter
            x: parent.width - width - rootKipPanel.kt.inputPadding
            width: label.length > 0 ? enterText.implicitWidth + 14 : 0
            height: enterText.implicitHeight + 6
            radius: rootKipPanel.kt.chipRadius
            color: rootKipPanel.kt.chipColor
            opacity: label.length > 0 ? rootKipPanel.inputContentT : 0
            visible: opacity > 0.01

            Text {
                id: enterText

                anchors.centerIn: parent
                text: "↵ " + enterHint.label
                color: rootKipPanel.kt.accentColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize + 1
            }
        }
    }

    // Bottom-edge grip. Drag to raise or lower the height cap; double-click
    // goes back to the theme default. Longer content uses the room; short
    // content does not stretch to fill it.
    MouseArea {
        id: resizeHandle

        property real pressY: 0
        property real pressLimit: 0

        x: card.x + card.width * 0.25
        y: card.y + card.height - height / 2
        width: card.width * 0.5
        height: 14
        visible: rootKipPanel.bodyT >= 1 && rootKipPanel.panelOpen
        hoverEnabled: true
        cursorShape: Qt.SizeVerCursor
        preventStealing: true

        onPressed: mouse => {
            pressY = mapToItem(null, mouse.x, mouse.y).y;
            pressLimit = rootKipPanel.maxBodyHeight;
            rootKipPanel.resizing = true;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;

            const delta = mapToItem(null, mouse.x, mouse.y).y - pressY;

            rootKipPanel.bodyLimitRequested(Math.max(rootKipPanel.kt.minBodyHeight, Math.min(rootKipPanel.availableBodyHeight, pressLimit + delta)));
        }
        onReleased: rootKipPanel.resizing = false
        onCanceled: rootKipPanel.resizing = false
        onDoubleClicked: rootKipPanel.bodyLimitRequested(0)

        Rectangle {
            anchors.centerIn: parent
            width: 44
            height: 4
            radius: 2
            color: resizeHandle.pressed || resizeHandle.containsMouse ? rootKipPanel.kt.accentColor : rootKipPanel.kt.borderColor
            opacity: resizeHandle.pressed || resizeHandle.containsMouse ? 1 : 0.7
        }
    }

    function animateTo(target) {
        progressAnimation.stop();

        const distance = Math.abs(target - openProgress);

        if (kt.reducedMotion || distance <= 0) {
            openProgress = target;
            if (target <= 0 && !panelOpen)
                Qt.callLater(() => rootKipPanel.closeFinished());
            return;
        }

        progressAnimation.from = openProgress;
        progressAnimation.to = target;
        progressAnimation.duration = Math.max(1, Math.round((target > openProgress ? kt.openDuration : kt.closeDuration) * distance));
        progressAnimation.start();
    }

    function handleTextChanged() {
        if (promptInput.text.length > 0)
            hasInteracted = true;

        notice = "";
        showSnippet = false;
        chooserHit = null;

        if (paletteIndex >= paletteItems.length)
            paletteIndex = 0;

        // "/help" and "/help fd" render as you type.
        if (parsed.mode === "ready" && parsed.command !== null && parsed.command.kind === "help") {
            showDoc(commands.helpMarkdown(parsed.argument), "help", "");
            return;
        }

        if (parsed.mode === "ready" && parsed.command !== null && parsed.command.kind === "tldr") {
            if (parsed.argument.length > 0) {
                tldrTimer.restart();
                return;
            }
            tldrTimer.stop();
        }

        if (parsed.mode === "unknown" && parsed.token.length > 0) {
            const guess = commands.suggest(parsed.token);

            if (guess)
                notice = "Did you mean /" + guess.name + "?";
        }

        // "/fd words" searches live after a short pause.
        if (liveFilesWanted()) {
            if (contentState === "service")
                service.reset();
            if (contentState === "shots")
                shots.reset();
            fileSearchTimer.restart();
            return;
        }

        if (fileFlagProblem().length > 0)
            notice = fileFlagProblem();

        // "/last " and "/last 2" preview live, no Enter needed.
        if (liveShotsWanted()) {
            if (contentState === "service")
                service.reset();
            if (contentState === "shots") {
                shotRefreshTimer.restart();
            } else {
                runShots(parsed.argument);
            }
            return;
        }

        // Editing after a submit means a new question; drop the old request.
        if (contentState !== "compose")
            backToCompose();
    }

    // /last followed by a space (and maybe a count). A bare "/last" waits,
    // so typing "/la" on the way to something else does not run find.
    function liveShotsWanted() {
        return parsed.mode === "ready" && parsed.command !== null && parsed.command.kind === "screenshots" && promptInput.text.length > parsed.token.length + 1;
    }

    function liveFilesWanted() {
        return parsed.mode === "ready" && parsed.command !== null && parsed.command.kind === "files" && parsed.argument.length > 0 && parsed.unknownFlags.length === 0;
    }

    // "--f" without a value or an unknown flag: say which, instead of searching.
    function fileFlagProblem() {
        if (parsed.mode !== "ready" || !parsed.command || parsed.command.kind !== "files" || parsed.unknownFlags.length === 0)
            return "";

        const flag = parsed.unknownFlags[0];
        const key = flag.replace(/^--/, "").replace(/=.*$/, "");

        if (key === "f")
            return "--f needs a folder: --f=/ or --f=~/Notes.";
        if (key === "h")
            return "--h takes no value; it just means hidden files too.";
        return "I don't know " + flag + ". /fd knows --f=<dir> and --h.";
    }

    // Keeps the current list up while a new search runs (refresh in place).
    function runFiles() {
        const fresh = contentState !== "files";

        if (fresh)
            fileIndex = 0;

        contentState = "files";
        chooserHit = null;
        files.search(parsed.argument, parsed.flags.from || "", parsed.flags.hidden === true, !fresh);
    }

    function activateFile() {
        const hit = shownFiles[fileIndex];

        if (!hit)
            return;

        if (hit.isDir) {
            openChooser(hit, hit.folder + hit.file, kt.folderActions);
            return;
        }

        if (/\.md$/i.test(hit.file)) {
            openChooser(hit, "Open " + hit.file + " with", kt.markdownOpeners.filter(opener => !opener.logseqOnly || hit.inLogseq));
            return;
        }

        openChooser(hit, hit.folder + hit.file, kt.fileActions);
    }

    function filesStatus() {
        const where = files.tilde(files.root);
        const hiddenNote = files.hidden ? " · hidden included" : "";

        switch (files.status) {
        case "searching":
            return "searching " + where + hiddenNote;
        case "done":
            return Math.min(files.results.length, kt.fdShownResults) + (files.truncated ? " of " + kt.fdMaxResults + "+" : (files.results.length > kt.fdShownResults ? " of " + files.results.length : "")) + " in " + where + hiddenNote;
        case "empty":
            return "nothing in " + where + hiddenNote;
        case "error":
            return files.errorText;
        }
        return "";
    }

    function backToCompose() {
        chooserHit = null;
        service.reset();
        shots.reset();
        files.reset();
        docMarkdown = "";
        docKind = "";
        docEventKey = "";
        contentState = "compose";
        renderAnswer();
    }

    function liveTldrWanted() {
        return parsed.mode === "ready" && parsed.command !== null && parsed.command.kind === "tldr" && parsed.argument.length > 0;
    }

    function showTldr() {
        if (tldr.status !== "idle")
            showDoc(tldr.markdown, "tldr", tldr.eventKey);
    }

    // Static markdown in the answer viewer: /help now, /tldr pages next.
    function showDoc(text, kind, eventKey) {
        if (contentState !== "doc" && contentState !== "compose") {
            service.reset();
            shots.reset();
            files.reset();
        }
        chooserHit = null;
        docMarkdown = text;
        docKind = kind;
        docEventKey = eventKey;
        contentState = "doc";
        answerFlick.follow = false;
        renderAnswer();
        answerFlick.contentY = 0;
    }

    function handleKey(event) {
        if (chooserHit !== null && handleChooserKey(event))
            return;

        switch (event.key) {
        case Qt.Key_Escape:
            event.accepted = true;
            if (contentState !== "compose") {
                backToCompose();
                notice = "";
            } else {
                closeRequested();
            }
            return;
        case Qt.Key_Left:
        case Qt.Key_Right:
            // Only in the screenshot grid; otherwise the cursor keeps them.
            if (shotsVisible) {
                shotIndex = clampIndex(shotIndex + (event.key === Qt.Key_Right ? 1 : -1), shots.shots.length);
                event.accepted = true;
            }
            return;
        case Qt.Key_Up:
        case Qt.Key_Down:
            {
                const step = event.key === Qt.Key_Down ? 1 : -1;

                if (shotsVisible) {
                    shotIndex = clampIndex(shotIndex + step * shotColumns, shots.shots.length);
                    event.accepted = true;
                } else if (filesVisible) {
                    fileIndex = clampIndex(fileIndex + step, shownFiles.length);
                    event.accepted = true;
                } else if (resultsVisible) {
                    resultIndex = clampIndex(resultIndex + step, service.results.length);
                    event.accepted = true;
                } else if (paletteItems.length > 0) {
                    paletteIndex = clampIndex(paletteIndex + step, paletteItems.length);
                    event.accepted = true;
                }
                return;
            }
        case Qt.Key_Tab:
            event.accepted = true;
            if (resultsVisible)
                showSnippet = !showSnippet;
            else if (paletteItems.length > 0)
                complete(paletteItems[paletteIndex]);
            return;
        case Qt.Key_C:
            if (resultsVisible && (event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier)) {
                event.accepted = true;
                copyResult();
            }
            return;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            event.accepted = true;
            submit();
            return;
        }
    }

    function submit() {
        if (contentState === "doc") {
            if (docKind === "tldr" && tldr.status === "done") {
                copyRequested(tldr.rawPage);
                notice = "Copied the tldr page for " + tldr.name + ".";
            }
            return;
        }

        if (contentState === "files") {
            if (filesVisible)
                activateFile();
            else if (files.status === "error" && liveFilesWanted())
                runFiles();
            return;
        }

        if (contentState === "shots") {
            if (shots.status === "error")
                runShots(String(shots.requested));
            else if (shotsVisible)
                activateShot();
            return;
        }

        if (contentState === "service") {
            if (service.status === "error")
                run(service.kind, service.query, service.explain);
            else if (answerDone())
                openAnswerActions();
            else if (resultsVisible)
                activateResult();
            return;
        }

        switch (parsed.mode) {
        case "palette":
        case "candidate":
        case "unknown":
            if (paletteItems.length > 0 && parsed.mode !== "unknown")
                complete(paletteItems[paletteIndex]);
            return;
        case "ready":
            if (!parsed.command.takesArgument) {
                if (paletteItems.length > 0)
                    complete(paletteItems[paletteIndex]);
                return;
            }
            if (parsed.argument.length === 0 && !parsed.command.argumentOptional) {
                notice = "/" + parsed.command.name + " needs " + parsed.command.placeholder + ".";
                return;
            }
            run(parsed.command.kind, parsed.argument);
            return;
        case "plain":
            run("general", parsed.argument);
            return;
        }
    }

    function run(kind, argument, detailed) {
        if (kind === "files") {
            if (fileFlagProblem().length === 0)
                runFiles();
            return;
        }

        if (kind === "screenshots") {
            runShots(argument);
            return;
        }

        contentState = "service";
        answerFlick.follow = true;
        resultIndex = 0;
        showSnippet = false;
        chooserHit = null;
        notice = "";

        if (kind === "search")
            service.search(argument);
        else if (kind === "ask")
            service.ask(argument, detailed === true);
        else
            service.general(argument, detailed === true);
    }

    function answerDone() {
        return contentState === "service" && !service.busy && service.status !== "error" && service.answer.length > 0;
    }

    // Question → answer → Enter → these. Options that cannot apply are left
    // out, so the numbers always match what is shown.
    function openAnswerActions() {
        const options = kt.answerActions.filter(option => {
            if (option.id === "copy-selection")
                return answerText.selectedText.length > 0;
            if (option.id === "open-source")
                return service.kind === "ask" && resultsVisible && !service.mock;
            return true;
        });

        openChooser({
            kind: "answer"
        }, service.kind === "ask" ? "Answer, sources above" : "Answer", options);
    }

    function runLocalAction(id) {
        switch (id) {
        case "copy-markdown":
            copyRequested(service.answer);
            notice = "Copied the answer as Markdown.";
            return;
        case "copy-plain":
            copyRequested(markdown.toPlain(service.answer));
            notice = "Copied the answer as plain text.";
            return;
        case "copy-selection":
            copyRequested(answerText.selectedText);
            notice = "Copied the selection.";
            return;
        case "open-source":
            activateResult();
            return;
        case "retry":
            run(service.kind, service.query, service.explain);
            return;
        case "explain":
            run(service.kind, service.query, true);
            return;
        }
    }

    function renderAnswer() {
        answerRenderTimer.stop();
        const source = contentState === "doc" ? docMarkdown : service.citedAnswer(service.answer);

        renderedAnswer = source.length > 0 ? markdown.toRich(source) : {
            html: "",
            codeBlocks: []
        };
    }

    function answerLink(link) {
        const copy = /^kip-copy:(\d+)$/.exec(link);

        if (copy) {
            const code = renderedAnswer.codeBlocks[Number(copy[1])];

            if (code !== undefined) {
                copyRequested(code);
                notice = "Copied code block (" + code.split("\n").length + (code.split("\n").length === 1 ? " line)." : " lines).");
            }
            return;
        }

        // Only web links leave KIP; anything else in model output is ignored.
        if (/^https?:\/\//.test(link))
            Qt.openUrlExternally(link);
    }

    // Keys while the answer has focus (after a mouse selection). Copy and
    // select-all stay native; typing goes back to the prompt.
    function answerKey(event) {
        const modifiers = event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier);

        if (modifiers !== 0)
            return;

        switch (event.key) {
        case Qt.Key_Escape:
        case Qt.Key_Tab:
            event.accepted = true;
            answerText.deselect();
            promptInput.forceActiveFocus();
            return;
        case Qt.Key_Up:
        case Qt.Key_Down:
        case Qt.Key_PageUp:
        case Qt.Key_PageDown:
            {
                event.accepted = true;
                const step = (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) ? answerFlick.height * 0.9 : 40;
                const direction = (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp) ? -1 : 1;

                answerFlick.contentY = Math.max(0, Math.min(answerFlick.contentHeight - answerFlick.height, answerFlick.contentY + step * direction));
                return;
            }
        case Qt.Key_Return:
        case Qt.Key_Enter:
            event.accepted = true;
            promptInput.forceActiveFocus();
            submit();
            return;
        }

        if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            event.accepted = true;
            promptInput.forceActiveFocus();
            promptInput.insert(promptInput.cursorPosition, event.text);
        }
    }

    function activateResult() {
        const hit = service.results[resultIndex];

        if (!hit)
            return;

        // Mock hits point at files that do not exist; say so instead.
        if (service.mock || !hit.absolutePath) {
            notice = "Mock result: would open " + hit.folder + hit.file + ":" + hit.line + ".";
            return;
        }

        if (/\.md$/i.test(hit.file)) {
            openChooser(hit, "Open " + hit.file + " with", kt.markdownOpeners.filter(opener => !opener.logseqOnly || hit.origin === "logseq"));
            return;
        }

        actionRequested(hit, {
            id: "default",
            command: kt.openCommand
        });
    }

    // "/last" → 1, "/last 4" → 4, capped at maxScreenshots.
    function runShots(argument) {
        const text = String(argument || "").trim();

        if (text.length > 0 && !/^\d+$/.test(text)) {
            if (contentState === "shots")
                backToCompose();
            notice = "/last takes a number, like /last 3.";
            return;
        }

        const wanted = text.length > 0 ? Number(text) : 1;
        const count = Math.max(1, Math.min(kt.maxScreenshots, wanted));

        chooserHit = null;
        notice = wanted > count ? "Capped at " + count + ". Nobody needs " + wanted + " screenshots at once." : "";

        // Already showing shots: refresh in place, keep the selection if it still fits.
        if (contentState === "shots") {
            shotIndex = Math.min(shotIndex, count - 1);
            shots.refresh(count);
            return;
        }

        contentState = "shots";
        shotIndex = 0;
        shots.load(count);
    }

    function activateShot() {
        const shot = shots.shots[shotIndex];

        if (shot)
            openChooser(shot, shot.file, kt.screenshotActions);
    }

    function openChooser(item, title, options) {
        chooserOptions = options;
        chooserTitle = title;
        chooserIndex = 0;
        chooserHit = item;
    }

    // Returns true when the chooser consumed the key. Typing anything else
    // falls through to the input, which closes the chooser via handleTextChanged.
    function handleChooserKey(event) {
        const count = chooserOptions.length;

        switch (event.key) {
        case Qt.Key_Escape:
            chooserHit = null;
            break;
        case Qt.Key_Up:
            chooserIndex = clampIndex(chooserIndex - 1, count);
            break;
        case Qt.Key_Down:
            chooserIndex = clampIndex(chooserIndex + 1, count);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            confirmChooser();
            break;
        case Qt.Key_Tab:
            break;
        default:
            {
                const number = event.key - Qt.Key_1;

                if (number < 0 || number >= count)
                    return false;

                chooserIndex = number;
                confirmChooser();
            }
        }

        event.accepted = true;
        return true;
    }

    function confirmChooser() {
        const hit = chooserHit;
        const opener = chooserOptions[chooserIndex];

        chooserHit = null;

        if (hit && opener && opener.local)
            runLocalAction(opener.id);
        else if (hit && opener)
            actionRequested(hit, opener);
    }

    function copyResult() {
        const hit = service.results[resultIndex];

        if (!hit || !hit.absolutePath) {
            notice = "Nothing real to copy from a mock result.";
            return;
        }

        const text = hit.absolutePath + ":" + hit.line;

        copyRequested(text);
        notice = "Copied " + text;
    }

    function complete(command) {
        if (!command)
            return;

        promptInput.text = "/" + command.name + (command.takesArgument ? " " : "");
        promptInput.cursorPosition = promptInput.text.length;
        paletteIndex = 0;
    }

    function refreshMessage() {
        currentMessage = messages.pick(messageKey, {
            count: contentState === "shots" ? shots.shots.length : contentState === "files" ? files.results.length : service.results.length
        });
    }

    function enterLabel() {
        if (chooserHit !== null)
            return "pick";
        if (contentState === "shots")
            return shots.status === "error" ? "retry" : (shotsVisible ? "actions" : "");
        if (contentState === "files")
            return filesVisible ? "actions" : (files.status === "error" ? "retry" : "");
        if (contentState === "doc")
            return docKind === "tldr" && tldr.status === "done" ? "copy page" : "";
        if (contentState === "service") {
            if (service.status === "error")
                return "retry";
            if (answerDone())
                return "actions";
            return resultsVisible ? "open" : "";
        }

        if (parsed.mode === "ready" && parsed.command && parsed.command.takesArgument)
            return parsed.argument.length > 0 || parsed.command.argumentOptional ? parsed.command.name : "";
        if (parsed.mode === "palette" || parsed.mode === "candidate")
            return "complete";
        if (parsed.mode === "plain")
            return "send";
        return "";
    }

    function statusLabel() {
        const prefix = service.mock ? "mock · " : "";

        switch (service.status) {
        case "searching":
            return prefix + (service.kind === "ask" ? "finding sources" : "searching notes");
        case "generating":
            if (service.answer.length === 0)
                return prefix + "waiting for " + (service.model.length > 0 ? service.model : "the model");
            return prefix + "streaming answer";
        case "done":
            return prefix + (service.kind === "search" ? service.results.length + " files" : "done");
        case "empty":
            return prefix + "0 results";
        case "error":
            return prefix + ({
                    ollama: "Ollama unavailable",
                    index: "index problem",
                    malformed: "malformed reply",
                    process: "jarvis failed",
                    missing: "jarvis not found"
                }[service.errorKind] || "backend error");
        }
        return prefix + service.status;
    }

    function shotsStatus() {
        switch (shots.status) {
        case "loading":
            return "listing " + kt.screenshotDir;
        case "done":
            return shots.shots.length + (shots.shots.length === 1 ? " newest · " : " newest · ") + kt.screenshotDir;
        case "empty":
            return "no images in " + kt.screenshotDir;
        case "error":
            return shots.errorText;
        }
        return "";
    }

    function keyHints() {
        if (chooserHit !== null)
            return "↑↓ or 1–" + chooserOptions.length + " choose · Enter do it · Esc cancel";
        if (contentState === "doc" && docKind === "tldr")
            return tldr.status === "done" ? "Copy on an example · Enter copies the page · Esc back" : "Esc back · keep typing";
        if (contentState === "doc")
            return "select + Ctrl+C copies · Esc back · keep typing";
        if (contentState === "files") {
            if (files.status === "error")
                return "Enter retry · Esc back · fix --f= to search elsewhere";
            return filesVisible ? "↑↓ move · Enter actions · Esc back · keep typing to refine" : "Esc back · keep typing to refine";
        }
        if (contentState === "shots") {
            if (shots.status === "error")
                return "Enter retry · Esc back";
            return shotsVisible ? (shotColumns > 1 ? "←→↑↓ move · " : "") + "Enter actions · Esc back" : "Esc back";
        }
        if (contentState === "service") {
            if (service.status === "error")
                return "Enter retry · Esc back · keep typing to start over";
            if (answerDone())
                return (resultsVisible ? "↑↓ sources · Tab source text · " : "") + "Enter actions · select + Ctrl+C · Esc back";
            return resultsVisible ? "↑↓ move · Enter open · Tab source · Ctrl+Shift+C copy path · Esc back" : "Esc back · keep typing to start over";
        }
        if (paletteVisible)
            return "↑↓ choose · Tab complete · Esc close";
        return "/ commands · Enter submit · Esc close";
    }

    function clampIndex(index, count) {
        if (count <= 0)
            return 0;
        return Math.max(0, Math.min(count - 1, index));
    }

    function segment(start, end) {
        if (end <= start)
            return openProgress >= end ? 1 : 0;
        return Math.max(0, Math.min(1, (openProgress - start) / (end - start)));
    }

    function ease(value) {
        return 1 - Math.pow(1 - value, 3);
    }

    function lerp(from, to, t) {
        return from + (to - from) * t;
    }
}
