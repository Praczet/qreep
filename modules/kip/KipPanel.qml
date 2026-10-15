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
    required property bool panelOpen

    signal closeRequested
    signal closeFinished
    signal openRequested(var hit, string openerId)
    signal copyRequested(string text)

    readonly property QtObject kt: theme.modules.kip

    property real openProgress: 0
    readonly property var parsed: commands.parse(promptInput.text)

    // compose: reacting to typing. service: showing a submitted request.
    property string contentState: "compose"
    property int paletteIndex: 0
    property int resultIndex: 0
    property bool hasInteracted: false
    // Original retrieved text of the selected hit, toggled with Tab.
    property bool showSnippet: false
    // Logseq markdown hit waiting for an "Open with" choice; null when closed.
    property var chooserHit: null
    // Openers that apply to chooserHit: Logseq only for Logseq-graph files.
    property var chooserOptions: []
    property int chooserIndex: 0
    property string notice: ""
    property string currentMessage: ""

    readonly property string messageKey: contentState === "service" ? service.eventKey : (parsed.mode === "idle" && !hasInteracted ? "kip.open" : parsed.eventKey)
    readonly property bool paletteVisible: contentState === "compose" && (parsed.mode === "palette" || parsed.mode === "candidate" || parsed.mode === "unknown" || (parsed.mode === "ready" && parsed.command && !parsed.command.takesArgument))
    readonly property var paletteItems: paletteVisible ? parsed.matches : []
    readonly property bool resultsVisible: contentState === "service" && service.results.length > 0

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
    readonly property real maxBodyHeight: Math.max(80, Math.min(kt.maxBodyHeight, height - (kt.anchorY + kt.inputHeight + kt.bodyGap + kt.cardPadding + kt.screenMargin)))
    property real bodyAreaHeight: Math.min(bodyContent.implicitHeight, maxBodyHeight)

    Behavior on bodyAreaHeight {
        enabled: !rootKipPanel.kt.reducedMotion && rootKipPanel.openProgress >= 1

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

            // "Open with" for Logseq markdown. Logseq is first, so the default.
            Rectangle {
                width: parent.width
                height: chooserColumn.implicitHeight + 16
                visible: rootKipPanel.chooserHit !== null
                radius: rootKipPanel.kt.rowRadius
                color: rootKipPanel.kt.inputColor
                border.width: 1
                border.color: rootKipPanel.kt.focusBorderColor

                Column {
                    id: chooserColumn

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 8
                    }
                    spacing: 2

                    Text {
                        width: parent.width
                        text: "Open " + (rootKipPanel.chooserHit ? rootKipPanel.chooserHit.file : "") + " with"
                        color: rootKipPanel.kt.secondaryTextColor
                        font.pixelSize: rootKipPanel.kt.metaPixelSize + 1
                        elide: Text.ElideMiddle
                        bottomPadding: 4
                    }

                    Repeater {
                        model: rootKipPanel.chooserOptions

                        Rectangle {
                            id: openerRow

                            required property var modelData
                            required property int index

                            readonly property bool selected: index === rootKipPanel.chooserIndex

                            width: parent.width
                            height: rootKipPanel.kt.commandRowHeight - 6
                            radius: rootKipPanel.kt.rowRadius
                            color: selected ? rootKipPanel.kt.selectedRowColor : (openerMouse.containsMouse ? rootKipPanel.kt.hoveredRowColor : "transparent")

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 8
                                spacing: 10

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 22
                                    text: openerRow.modelData.icon
                                    color: rootKipPanel.kt.accentColor
                                    font.family: rootKipPanel.theme.iconFontFamily
                                    font.pixelSize: rootKipPanel.kt.iconPixelSize - 2
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 90
                                    text: (openerRow.index + 1) + "  " + openerRow.modelData.label
                                    color: rootKipPanel.kt.primaryTextColor
                                    font.pixelSize: rootKipPanel.kt.bodyPixelSize
                                    font.bold: openerRow.selected
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: openerRow.modelData.hint
                                    color: rootKipPanel.kt.secondaryTextColor
                                    font.pixelSize: rootKipPanel.kt.metaPixelSize + 1
                                }
                            }

                            MouseArea {
                                id: openerMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    rootKipPanel.chooserIndex = openerRow.index;
                                    rootKipPanel.confirmChooser();
                                }
                            }
                        }
                    }
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

            // One growing answer, never a pile of bubbles. Follows the stream
            // to the bottom while generating; scroll freely once done.
            Flickable {
                id: answerFlick

                width: parent.width
                height: Math.min(answerText.implicitHeight, rootKipPanel.kt.answerMaxHeight)
                visible: rootKipPanel.contentState === "service" && rootKipPanel.service.answer.length > 0
                contentHeight: answerText.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                onContentHeightChanged: {
                    if (rootKipPanel.service.busy && contentHeight > height)
                        contentY = contentHeight - height;
                }

                Text {
                    id: answerText

                    width: parent.width
                    text: rootKipPanel.service.citedAnswer(rootKipPanel.service.answer)
                    textFormat: Text.MarkdownText
                    color: rootKipPanel.kt.primaryTextColor
                    font.pixelSize: rootKipPanel.kt.bodyPixelSize
                    wrapMode: Text.WordWrap
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
                text: promptInput.text.length === 0 ? "Ask, search, or type / for commands" : (rootKipPanel.parsed.command ? rootKipPanel.parsed.command.placeholder : "")
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

        // Editing after a submit means a new question; drop the old request.
        if (contentState === "service") {
            service.reset();
            contentState = "compose";
        }
    }

    function handleKey(event) {
        if (chooserHit !== null && handleChooserKey(event))
            return;

        switch (event.key) {
        case Qt.Key_Escape:
            event.accepted = true;
            if (contentState === "service") {
                chooserHit = null;
                service.reset();
                contentState = "compose";
                notice = "";
            } else {
                closeRequested();
            }
            return;
        case Qt.Key_Up:
        case Qt.Key_Down:
            {
                const step = event.key === Qt.Key_Down ? 1 : -1;

                if (resultsVisible) {
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
        if (contentState === "service") {
            if (service.status === "error")
                run(service.kind, service.query);
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
            if (parsed.argument.length === 0) {
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

    function run(kind, argument) {
        contentState = "service";
        resultIndex = 0;
        showSnippet = false;
        chooserHit = null;
        notice = "";

        if (kind === "search")
            service.search(argument);
        else if (kind === "ask")
            service.ask(argument);
        else
            service.general(argument);
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
            chooserOptions = kt.markdownOpeners.filter(opener => !opener.logseqOnly || hit.origin === "logseq");
            chooserIndex = 0;
            chooserHit = hit;
            return;
        }

        openRequested(hit, "default");
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

        if (hit && opener)
            openRequested(hit, opener.id);
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
            count: service.results.length
        });
    }

    function enterLabel() {
        if (contentState === "service") {
            if (service.status === "error")
                return "retry";
            return resultsVisible ? "open" : "";
        }

        if (parsed.mode === "ready" && parsed.command && parsed.command.takesArgument)
            return parsed.argument.length > 0 ? parsed.command.name : "";
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

    function keyHints() {
        if (chooserHit !== null)
            return "↑↓ or 1–" + chooserOptions.length + " choose · Enter open · Esc cancel";
        if (contentState === "service") {
            if (service.status === "error")
                return "Enter retry · Esc back · keep typing to start over";
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
