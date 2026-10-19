import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

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
    required property QtObject calc
    required property QtObject dict
    required property QtObject windows
    property QtObject places: null
    required property QtObject binds
    required property QtObject timerCommand
    required property QtObject runner
    required property QtObject apps
    required property QtObject browser
    required property QtObject grep
    required property QtObject qreep
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
    // Re-parsed first thing in handleTextChanged. A binding on the text
    // updated after the handler ran, so handlers read the previous input:
    // /browse listed the folder you had just left.
    property var parsed: commands.parse("")

    // compose: reacting to typing. service: a submitted notes/ask/general
    // request. shots: /last screenshots. files: /fd. doc: static markdown
    // (/help) shown in the answer viewer.
    property string contentState: "compose"
    property int paletteIndex: 0
    property int resultIndex: 0
    property int appIndex: 0
    property bool hasInteracted: false
    // Original retrieved text of the selected hit, toggled with Tab.
    property bool showSnippet: false
    // Item waiting for an action choice ("Open with", screenshot actions);
    // null when the chooser is closed.
    property var chooserHit: null
    property var chooserOptions: []
    property string chooserTitle: ""
    property int chooserIndex: 0
    // Image shown beside the actions, so a menu opened before a distraction
    // still says which screenshot it belongs to. Empty for non-images.
    property string chooserPreview: ""
    property string notice: ""
    // Help sheet (header chip, Ctrl+/). Typing closes it.
    property bool shortcutsOpen: false
    property string currentMessage: ""
    // Icon in front of the message: the app a habit remark is about.
    property string messageIcon: ""
    property string docMarkdown: ""
    // help | tldr; and the message key a doc wants (empty: use the command's).
    property string docKind: ""
    property string docEventKey: ""

    // The Kip*Command that owns the current view, or null (compose, service,
    // doc). Its keys go first; Enter, labels and hints are its call.
    readonly property var activeCommand: ({
            run: runCommand,
            browse: browseCommand,
            qreep: qreepCommand,
            grep: grepCommand,
            files: filesCommand,
            shots: shotsCommand,
            windows: windowsCommand,
            projects: projectsCommand,
            ssh: sshCommand,
            keys: keysCommand
        })[contentState] || null
    // The text field lives in KipInput.
    readonly property TextInput promptInput: inputBox.field

    readonly property string messageKey: activeCommand !== null ? activeCommand.eventKey : contentState === "service" ? service.eventKey : contentState === "doc" && docEventKey.length > 0 ? docEventKey : (parsed.mode === "idle" && !hasInteracted ? "kip.open" : parsed.eventKey)
    readonly property bool paletteVisible: contentState === "compose" && (parsed.mode === "palette" || parsed.mode === "candidate" || parsed.mode === "unknown" || (parsed.mode === "ready" && parsed.command && !parsed.command.takesArgument))
    readonly property var paletteItems: paletteVisible ? parsed.matches : []
    readonly property bool resultsVisible: contentState === "service" && service.results.length > 0
    // Launcher: empty input, plain text, or /app [name]. A compose-time view
    // like the palette, so "/" still takes over the moment you type it.
    readonly property bool appsMode: contentState === "compose" && (parsed.mode === "idle" || parsed.mode === "plain" || (parsed.mode === "ready" && parsed.command !== null && parsed.command.kind === "apps"))
    readonly property string appsQuery: appsMode && parsed.mode !== "idle" ? parsed.argument : ""
    readonly property var appSections: appsMode ? apps.sections(appsQuery, apps.grouping) : []
    readonly property bool appsVisible: appsMode && appView.count > 0

    property string bloomWallpaper: ""
    readonly property string headerImagePath: kt.headerImage === "bloom" ? bloomWallpaper : kt.headerImage
    readonly property string headerImageUrl: headerImagePath.length > 0 ? "file://" + headerImagePath.split("/").map(encodeURIComponent).join("/") : ""

    // Unclaimed Bloom writes the wallpaper path here; read only when wanted.
    FileView {
        id: bloomWallpaperFile

        path: rootKipPanel.kt.headerImage === "bloom" ? rootKipPanel.kt.bloomWallpaperFile : ""
        preload: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: rootKipPanel.bloomWallpaper = text().trim()
        onLoadFailed: rootKipPanel.bloomWallpaper = ""
    }

    readonly property string phase: {
        if (!panelOpen)
            return openProgress > 0 ? "closing" : "hidden";
        if (openProgress < kt.signalEnd)
            return "signal";
        if (openProgress < kt.descendEnd)
            return "descend";
        if (openProgress < 1)
            return "assemble";
        if (contentState === "service")
            return service.busy ? "processing" : (service.status === "error" ? "error" : "results");
        return "ready";
    }

    // Motion slices, each eased on its own.
    readonly property real signalT: ease(segment(0, kt.signalEnd))
    readonly property real descendT: ease(segment(kt.signalEnd, kt.descendEnd))
    readonly property real headerT: ease(segment(kt.descendEnd, kt.descendEnd + (1 - kt.descendEnd) * 0.6))
    readonly property real bodyT: ease(segment(kt.descendEnd + (1 - kt.descendEnd) * 0.3, 1))

    // Geometry. The input box is full size from the first frame, so typing
    // works at once; it only fades in at the top and slides down.
    readonly property real cardWidth: Math.max(0, Math.min(kt.panelWidth, width - kt.screenMargin * 2))
    readonly property real boxWidth: cardWidth - kt.cardPadding * 2
    readonly property real boxHeight: kt.inputHeight
    readonly property real boxX: (width - boxWidth) / 2
    readonly property real boxY: lerp(kt.signalTopY, kt.anchorY, descendT)
    // Height cap for the body: the theme default, or what the bottom edge was
    // dragged to (userBodyLimit > 0), never past the bottom of the screen.
    property real userBodyLimit: 0
    property bool resizing: false
    readonly property real availableBodyHeight: height - (kt.anchorY + kt.inputHeight + kt.bodyGap + kt.cardPadding + kt.screenMargin)
    readonly property real maxBodyHeight: Math.max(80, Math.min(userBodyLimit > 0 ? userBodyLimit : kt.maxBodyHeight, availableBodyHeight))
    // The answer gets the body height left below whatever sits above it
    // (sources, status) and above the notice/hint lines, so its own bottom is
    // always inside the card. A fixed cap let the body clip the answer and
    // hide the end of a stream. answerView.y depends only on items above it,
    // so this does not loop through the answer's own height.
    readonly property real answerBelowHeight: (noticeText.visible ? noticeText.height + bodyContent.spacing : 0) + hintsText.height + bodyContent.spacing
    readonly property real answerLimit: Math.max(80, maxBodyHeight - answerView.y - answerBelowHeight)
    // Room for the floating chooser too, so a short list does not clip it.
    property real bodyAreaHeight: Math.min(Math.max(bodyContent.implicitHeight, chooserOverlay.visible ? chooserOverlay.height + 2 * kt.chooserOverlayMargin + hintsText.height + bodyContent.spacing : 0), maxBodyHeight)

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

    // /calc and /def run their tool after a pause in typing.
    Timer {
        id: liveDocTimer

        interval: rootKipPanel.kt.liveDocDebounce
        repeat: false
        onTriggered: rootKipPanel.refreshLiveDoc()
    }

    // Commands with their own view: each keeps its selection, timers, keys,
    // status line and Enter. The panel routes to them; see the host API
    // (setInput, inputText, backToCompose, chooser functions) further down.
    KipRunCommand {
        id: runCommand

        host: rootKipPanel
        runner: rootKipPanel.runner
    }

    KipBrowseCommand {
        id: browseCommand

        host: rootKipPanel
        browser: rootKipPanel.browser
    }

    KipQreepCommand {
        id: qreepCommand

        host: rootKipPanel
        qreep: rootKipPanel.qreep
    }

    KipGrepCommand {
        id: grepCommand

        host: rootKipPanel
        grep: rootKipPanel.grep
    }

    KipFilesCommand {
        id: filesCommand

        host: rootKipPanel
        files: rootKipPanel.files
    }

    KipShotsCommand {
        id: shotsCommand

        host: rootKipPanel
        shots: rootKipPanel.shots
    }

    KipWindowsCommand {
        id: windowsCommand

        host: rootKipPanel
        windows: rootKipPanel.windows
        view: windowView
    }

    KipProjectsCommand {
        id: projectsCommand

        host: rootKipPanel
        places: rootKipPanel.places
    }

    KipSshCommand {
        id: sshCommand

        host: rootKipPanel
        places: rootKipPanel.places
    }

    KipKeysCommand {
        id: keysCommand

        host: rootKipPanel
        binds: rootKipPanel.binds
    }

    // A timer preview counts down while it is on screen.
    Timer {
        interval: 1000
        repeat: true
        running: rootKipPanel.contentState === "doc" && rootKipPanel.docKind === "timer"
        onTriggered: rootKipPanel.showTimerPreview()
    }

    // Results land asynchronously; markdown is assigned last in both services.
    Connections {
        target: rootKipPanel.calc

        function onMarkdownChanged() {
            if (rootKipPanel.liveKind() === "calc" && rootKipPanel.calc.markdown.length > 0)
                rootKipPanel.showDoc(rootKipPanel.calc.markdown, "calc", rootKipPanel.calc.eventKey);
        }
    }

    Connections {
        target: rootKipPanel.dict

        function onMarkdownChanged() {
            if (rootKipPanel.liveKind() === "def" && rootKipPanel.dict.markdown.length > 0)
                rootKipPanel.showDoc(rootKipPanel.dict.markdown, "def", rootKipPanel.dict.eventKey);
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

    // Glow: brightest mid-descent, settles to a faint focus halo.
    Rectangle {
        x: rootKipPanel.boxX - 3
        y: rootKipPanel.boxY - 3
        width: rootKipPanel.boxWidth + 6
        height: rootKipPanel.boxHeight + 6
        radius: rootKipPanel.kt.inputRadius + 3
        color: "transparent"
        border.width: 3
        border.color: rootKipPanel.kt.glowColor
        opacity: rootKipPanel.signalT * (0.45 + 0.55 * Math.sin(Math.PI * rootKipPanel.descendT)) * (1 - 0.6 * rootKipPanel.headerT)
        visible: opacity > 0.01
    }

    // The card assembles outward from the input box.
    Rectangle {
        id: card

        readonly property real topExtent: (rootKipPanel.kt.cardPadding + rootKipPanel.kt.headerHeroSpace + rootKipPanel.kt.headerHeight + rootKipPanel.kt.headerGap) * rootKipPanel.headerT
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

        // Banner image behind header and input. The mask rounds the top
        // corners to the card; the gradient on top fades it into the body.
        Item {
            id: banner

            x: 1
            y: 1
            width: parent.width - 2
            height: Math.min(rootKipPanel.kt.headerImageHeight, parent.height - 2)
            visible: rootKipPanel.headerImageUrl.length > 0 && bannerImage.status === Image.Ready
            layer.enabled: visible
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: bannerMask
            }

            Image {
                id: bannerImage

                anchors.fill: parent
                source: rootKipPanel.headerImageUrl
                // Fixed decode size: the card width animates on open.
                sourceSize.width: rootKipPanel.kt.panelWidth
                fillMode: Image.PreserveAspectCrop
                verticalAlignment: rootKipPanel.kt.headerImageAlign === "top" ? Image.AlignTop : rootKipPanel.kt.headerImageAlign === "bottom" ? Image.AlignBottom : Image.AlignVCenter
                opacity: rootKipPanel.kt.headerImageOpacity
                asynchronous: true
                cache: false
            }

            Rectangle {
                anchors.fill: parent

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "transparent"
                    }
                    GradientStop {
                        position: rootKipPanel.kt.headerImageFadeStart
                        color: "transparent"
                    }
                    // Opaque card colour: a translucent end leaves a faint image edge.
                    GradientStop {
                        position: 1
                        color: Qt.rgba(rootKipPanel.kt.cardColor.r, rootKipPanel.kt.cardColor.g, rootKipPanel.kt.cardColor.b, 1)
                    }
                }
            }
        }

        Rectangle {
            id: bannerMask

            width: banner.width
            height: banner.height
            radius: rootKipPanel.kt.cardRadius - 1
            visible: false
            layer.enabled: true
        }

        // Swallow clicks so the outside-click catcher does not close KIP.
        MouseArea {
            anchors.fill: parent
            onClicked: promptInput.forceActiveFocus()
        }
    }

    // Microcopy. Changes only when messageKey changes. Lives in the hero
    // space, centred between the title row and the input, and arrives with
    // the header.
    Text {
        id: messageText

        x: rootKipPanel.boxX
        y: header.y + rootKipPanel.kt.headerHeight + (rootKipPanel.kt.headerHeroSpace - height) / 2
        width: rootKipPanel.boxWidth
        opacity: rootKipPanel.headerT
        maximumLineCount: 2
        elide: Text.ElideRight
        text: rootKipPanel.currentMessage
        visible: text.length > 0 && opacity > 0.01
        color: rootKipPanel.contentState === "service" && rootKipPanel.service.status === "error" ? rootKipPanel.kt.errorColor : rootKipPanel.kt.messageColor
        font.pixelSize: rootKipPanel.kt.messagePixelSize
        font.italic: true
        font.weight: Font.Medium
        // It sits on the wallpaper; the shadow keeps it readable over
        // whatever the image does there.
        style: Text.Raised
        styleColor: rootKipPanel.kt.messageShadowColor
        wrapMode: Text.WordWrap
        leftPadding: rootKipPanel.messageIcon.length > 0 ? rootKipPanel.kt.messageIconSize + 8 : 0

        Image {
            visible: rootKipPanel.messageIcon.length > 0
            y: (messageText.font.pixelSize * 1.3 - height) / 2
            width: rootKipPanel.kt.messageIconSize
            height: width
            source: rootKipPanel.messageIcon
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
    }

    // Keys sheet: floats over the body like the action chooser, not clipped
    // by it, so it fits even when the body is short.
    KipShortcuts {
        x: rootKipPanel.boxX
        y: rootKipPanel.boxY + rootKipPanel.boxHeight + rootKipPanel.kt.bodyGap
        z: 20
        width: rootKipPanel.boxWidth
        visible: rootKipPanel.shortcutsOpen && rootKipPanel.bodyT > 0.99
        kipTheme: rootKipPanel.kt
        groups: rootKipPanel.commands.shortcutGroups
        activeGroup: rootKipPanel.shortcutContext()
        maxHeight: Math.max(200, rootKipPanel.maxBodyHeight)

        onCloseRequested: rootKipPanel.shortcutsOpen = false
    }

    // Header: slides up from behind the input; icon drifts left, status right.
    // It sits at the top of the card; the hero space is between it and the input.
    KipHeader {
        id: header

        x: rootKipPanel.boxX
        y: rootKipPanel.boxY - rootKipPanel.kt.headerGap - (rootKipPanel.kt.headerHeroSpace + rootKipPanel.kt.headerHeight) * rootKipPanel.headerT
        width: rootKipPanel.boxWidth
        height: rootKipPanel.kt.headerHeight
        opacity: rootKipPanel.headerT
        visible: opacity > 0.01
        kipTheme: rootKipPanel.kt
        service: rootKipPanel.service
        iconFontFamily: rootKipPanel.theme.iconFontFamily
        reveal: rootKipPanel.headerT
        helpOpen: rootKipPanel.shortcutsOpen

        onHelpClicked: {
            rootKipPanel.shortcutsOpen = !rootKipPanel.shortcutsOpen;
            promptInput.forceActiveFocus();
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

            // Recognized command with an argument slot (/ask, /notes). Not for
            // /app: the launcher's toolbar and hints already say all of it.
            Column {
                width: parent.width
                spacing: 6
                visible: rootKipPanel.contentState === "compose" && rootKipPanel.parsed.mode === "ready" && rootKipPanel.parsed.command !== null && rootKipPanel.parsed.command.takesArgument && !rootKipPanel.appsMode

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

            KipAppView {
                id: appView

                width: parent.width
                visible: rootKipPanel.appsMode
                kipTheme: rootKipPanel.kt
                apps: rootKipPanel.apps
                iconFontFamily: rootKipPanel.theme.iconFontFamily
                sections: rootKipPanel.appSections
                searching: rootKipPanel.appsQuery.length > 0
                selectedIndex: rootKipPanel.appIndex
                maxHeight: rootKipPanel.maxBodyHeight * 0.85

                onActivated: index => {
                    rootKipPanel.appIndex = index;
                    rootKipPanel.launchSelectedApp();
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
                text: shotsCommand.status()
                color: rootKipPanel.shots.status === "error" ? rootKipPanel.kt.errorColor : rootKipPanel.kt.tertiaryAccentColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideMiddle
            }

            // /fd: files and folders, best guesses first.
            Text {
                width: parent.width
                visible: rootKipPanel.contentState === "files"
                text: filesCommand.status()
                color: rootKipPanel.files.status === "error" ? rootKipPanel.kt.errorColor : rootKipPanel.kt.tertiaryAccentColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideMiddle
            }

            KipResultList {
                width: parent.width
                height: Math.min(contentHeight, rootKipPanel.maxBodyHeight * 0.75)
                visible: filesCommand.listVisible
                kipTheme: rootKipPanel.kt
                results: filesCommand.shown
                compact: true
                currentIndex: filesCommand.index

                onActivated: index => {
                    filesCommand.index = index;
                    filesCommand.activate();
                }
            }

            // /qreep: curated IPC actions, grouped, raw call on the right.
            Text {
                width: parent.width
                visible: rootKipPanel.contentState === "qreep"
                text: qreepCommand.status()
                color: rootKipPanel.qreep.status === "error" || rootKipPanel.qreep.callStatus === "error" ? rootKipPanel.kt.errorColor : rootKipPanel.kt.tertiaryAccentColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideMiddle
            }

            KipQreepList {
                width: parent.width
                height: Math.min(contentHeight, rootKipPanel.maxBodyHeight * 0.7)
                visible: qreepCommand.listVisible
                kipTheme: rootKipPanel.kt
                iconFontFamily: rootKipPanel.theme.iconFontFamily
                groupIcons: rootKipPanel.qreep.groupIcons
                results: rootKipPanel.qreep.results
                currentIndex: qreepCommand.index

                onActivated: index => {
                    qreepCommand.index = index;
                    qreepCommand.submit();
                }
            }

            // /qreep toggle list: the items of a catalog `toggles` action.
            KipQreepToggleList {
                width: parent.width
                height: Math.min(contentHeight, rootKipPanel.maxBodyHeight * 0.7)
                visible: qreepCommand.toggleMode && rootKipPanel.qreep.toggleResults.length > 0
                kipTheme: rootKipPanel.kt
                iconFontFamily: rootKipPanel.theme.iconFontFamily
                items: rootKipPanel.qreep.toggleResults
                title: qreepCommand.toggleMode ? rootKipPanel.qreep.toggleEntry.title : ""
                icon: qreepCommand.toggleMode ? rootKipPanel.qreep.toggleEntry.icon : ""
                currentIndex: qreepCommand.toggleIndex

                onActivated: index => {
                    qreepCommand.toggleIndex = index;
                    qreepCommand.submit();
                }
            }

            // What a returning call said, selectable for Ctrl+C.
            TextEdit {
                width: parent.width
                visible: rootKipPanel.contentState === "qreep" && rootKipPanel.qreep.callOutput.length > 0
                text: rootKipPanel.qreep.callOutput
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                color: rootKipPanel.qreep.callStatus === "error" ? rootKipPanel.kt.errorColor : rootKipPanel.kt.primaryTextColor
                font.family: rootKipPanel.kt.monoFontFamily
                font.pixelSize: rootKipPanel.kt.metaPixelSize + 2
            }

            // /rg: matching lines, path:line with the line itself underneath.
            Text {
                width: parent.width
                visible: rootKipPanel.contentState === "grep"
                text: grepCommand.status()
                color: rootKipPanel.grep.status === "error" ? rootKipPanel.kt.errorColor : rootKipPanel.kt.tertiaryAccentColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideMiddle
            }

            KipResultList {
                width: parent.width
                height: Math.min(contentHeight, rootKipPanel.maxBodyHeight * 0.75)
                visible: grepCommand.listVisible
                kipTheme: rootKipPanel.kt
                results: rootKipPanel.grep.results
                currentIndex: grepCommand.index

                onActivated: index => {
                    grepCommand.index = index;
                    grepCommand.activate();
                }
            }

            // /browse: one folder, names only; the folder itself is in the input.
            Text {
                width: parent.width
                visible: rootKipPanel.contentState === "browse"
                text: browseCommand.status()
                color: rootKipPanel.browser.status === "error" ? rootKipPanel.kt.errorColor : rootKipPanel.kt.tertiaryAccentColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideMiddle
            }

            Row {
                width: parent.width
                spacing: 8
                visible: rootKipPanel.contentState === "browse" && rootKipPanel.browser.status !== "error"

                KipResultList {
                    id: browseList

                    width: rootKipPanel.browser.preview ? Math.round(parent.width * 0.5) : parent.width
                    // With a preview the height stays put, so the pane does not jump while filtering.
                    height: rootKipPanel.browser.preview ? rootKipPanel.maxBodyHeight * 0.7 : Math.min(contentHeight, rootKipPanel.maxBodyHeight * 0.75)
                    kipTheme: rootKipPanel.kt
                    results: rootKipPanel.browser.results
                    compact: true
                    currentIndex: browseCommand.index

                    onActivated: index => {
                        browseCommand.index = index;
                        browseCommand.submit(false);
                    }
                }

                KipBrowsePreview {
                    width: parent.width - browseList.width - parent.spacing
                    height: browseList.height
                    visible: rootKipPanel.browser.preview
                    kipTheme: rootKipPanel.kt
                    browser: rootKipPanel.browser
                }
            }

            // /win: windows, most recently focused first, as icons or live previews.
            KipWindowView {
                id: windowView

                width: parent.width
                visible: rootKipPanel.contentState === "windows"
                kipTheme: rootKipPanel.kt
                windows: rootKipPanel.windows
                selectedIndex: windowsCommand.index
                maxHeight: rootKipPanel.maxBodyHeight * 0.85

                onActivated: index => {
                    windowsCommand.index = index;
                    windowsCommand.focusSelected();
                }
            }

            // /p: Places' projects, group as the chip, git and quests below.
            Text {
                width: parent.width
                visible: rootKipPanel.contentState === "projects"
                text: projectsCommand.status()
                color: rootKipPanel.kt.tertiaryAccentColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideMiddle
            }

            KipResultList {
                width: parent.width
                height: Math.min(contentHeight, rootKipPanel.maxBodyHeight * 0.75)
                visible: projectsCommand.listVisible
                kipTheme: rootKipPanel.kt
                results: projectsCommand.results
                currentIndex: projectsCommand.index

                onActivated: index => {
                    projectsCommand.index = index;
                    projectsCommand.submit(false);
                }
            }

            // /ssh: Places' ssh hosts, reachability as the chip.
            Text {
                width: parent.width
                visible: rootKipPanel.contentState === "ssh"
                text: sshCommand.status()
                color: rootKipPanel.kt.tertiaryAccentColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideMiddle
            }

            KipResultList {
                width: parent.width
                height: Math.min(contentHeight, rootKipPanel.maxBodyHeight * 0.75)
                visible: sshCommand.listVisible
                kipTheme: rootKipPanel.kt
                results: sshCommand.results
                currentIndex: sshCommand.index

                onActivated: index => {
                    sshCommand.index = index;
                    sshCommand.submit(false);
                }
            }

            // /keys: Hyprland binds, combo in the chip, description beside it.
            Text {
                width: parent.width
                visible: rootKipPanel.contentState === "keys"
                text: keysCommand.status()
                color: rootKipPanel.binds.status === "error" ? rootKipPanel.kt.errorColor : rootKipPanel.kt.tertiaryAccentColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideMiddle
            }

            KipResultList {
                width: parent.width
                height: Math.min(contentHeight, rootKipPanel.maxBodyHeight * 0.75)
                visible: keysCommand.listVisible
                kipTheme: rootKipPanel.kt
                results: rootKipPanel.binds.results
                compact: true
                currentIndex: keysCommand.index

                onActivated: index => {
                    keysCommand.index = index;
                    keysCommand.submit();
                }
            }

            // /run: matching history entries, newest first.
            KipResultList {
                width: parent.width
                height: Math.min(contentHeight, rootKipPanel.maxBodyHeight * 0.4)
                visible: rootKipPanel.contentState === "run" && rootKipPanel.runner.matches.length > 0 && rootKipPanel.runner.runStatus !== "failed" && rootKipPanel.runner.runStatus !== "exited"
                kipTheme: rootKipPanel.kt
                results: rootKipPanel.runner.matches
                compact: true
                currentIndex: runCommand.picking ? runCommand.index : -1

                onActivated: index => {
                    runCommand.index = index;
                    runCommand.pick();
                }
            }

            KipShotGrid {
                width: parent.width
                visible: shotsCommand.listVisible
                kipTheme: rootKipPanel.kt
                shots: rootKipPanel.shots
                columns: shotsCommand.columns
                selectedIndex: shotsCommand.index
                maxHeight: rootKipPanel.maxBodyHeight * 0.75

                onActivated: index => {
                    shotsCommand.index = index;
                    shotsCommand.activate();
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

            KipAnswerView {
                id: answerView

                width: parent.width
                maxHeight: rootKipPanel.answerLimit
                visible: (rootKipPanel.contentState === "service" && rootKipPanel.service.answer.length > 0) || (answerView.showsDoc && rootKipPanel.docMarkdown.length > 0)
                kipTheme: rootKipPanel.kt
                service: rootKipPanel.service
                showsDoc: rootKipPanel.contentState === "doc" || rootKipPanel.contentState === "run"
                docMarkdown: rootKipPanel.docMarkdown

                onCopyCodeRequested: code => {
                    const lines = code.split("\n").length;

                    rootKipPanel.copyRequested(code);
                    rootKipPanel.notice = "Copied code block (" + lines + (lines === 1 ? " line)." : " lines).");
                }
                onFocusReturned: promptInput.forceActiveFocus()
                onSubmitRequested: {
                    promptInput.forceActiveFocus();
                    rootKipPanel.submit();
                }
                onTyped: text => {
                    promptInput.forceActiveFocus();
                    promptInput.insert(promptInput.cursorPosition, text);
                }
            }

            Text {
                id: noticeText

                width: parent.width
                visible: rootKipPanel.notice.length > 0
                text: rootKipPanel.notice
                color: rootKipPanel.kt.warningColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize + 1
                wrapMode: Text.WordWrap
            }

            Text {
                id: hintsText

                width: parent.width
                text: rootKipPanel.keyHints()
                color: rootKipPanel.kt.secondaryTextColor
                font.pixelSize: rootKipPanel.kt.metaPixelSize
                elide: Text.ElideRight
            }
        }

        // Action chooser floats over the lists instead of queueing after
        // them: a full grid fills the body limit, and a menu clipped below
        // it is not much of a menu. Centered above the key hints, with a
        // shadow so it reads as a layer and not as one more grid row.
        KipChooser {
            id: chooserOverlay

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -(hintsText.height + bodyContent.spacing) / 2
            width: Math.min(parent.width - 2 * rootKipPanel.kt.chooserOverlayMargin, rootKipPanel.kt.chooserOverlayMaxWidth + (rootKipPanel.chooserPreview.length > 0 ? rootKipPanel.kt.chooserPreviewWidth + 8 : 0))
            z: 1
            color: rootKipPanel.kt.chooserColor

            layer.enabled: visible
            layer.effect: MultiEffect {
                shadowEnabled: true
                autoPaddingEnabled: true
                shadowHorizontalOffset: 0
                shadowVerticalOffset: rootKipPanel.kt.chooserShadowOffset
                shadowBlur: rootKipPanel.kt.chooserShadowBlur
                shadowColor: rootKipPanel.kt.chooserShadowColor
            }
            visible: rootKipPanel.chooserHit !== null
            kipTheme: rootKipPanel.kt
            iconFontFamily: rootKipPanel.theme.iconFontFamily
            title: rootKipPanel.chooserTitle
            options: rootKipPanel.chooserOptions
            selectedIndex: rootKipPanel.chooserIndex
            previewSource: rootKipPanel.chooserPreview

            onPicked: index => {
                rootKipPanel.chooserIndex = index;
                rootKipPanel.confirmChooser();
            }
        }
    }

    KipInput {
        id: inputBox

        x: rootKipPanel.boxX
        y: rootKipPanel.boxY
        width: rootKipPanel.boxWidth
        height: rootKipPanel.boxHeight
        radius: rootKipPanel.kt.inputRadius
        opacity: rootKipPanel.signalT
        kipTheme: rootKipPanel.kt
        iconFontFamily: rootKipPanel.theme.iconFontFamily
        parsed: rootKipPanel.parsed
        enterLabel: rootKipPanel.enterLabel()

        onEdited: rootKipPanel.handleTextChanged()
        onKeyPressed: event => rootKipPanel.handleKey(event)
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
        parsed = commands.parse(promptInput.text);
        shortcutsOpen = false;

        if (promptInput.text.length > 0)
            hasInteracted = true;

        notice = "";
        showSnippet = false;
        chooserHit = null;
        // New query, new ranking: the best match is first.
        appIndex = 0;

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

        // /calc and /def: their tool runs after a pause; the old result stays up.
        if ((liveKind() === "calc" || liveKind() === "def") && parsed.argument.length > 0) {
            liveDocTimer.restart();
            return;
        }

        // /timer previews instantly: no process, just the timer's own parsers.
        if (liveKind() === "timer") {
            showTimerPreview();
            return;
        }

        // "/qreep words": the IPC list narrows; exact names take arguments.
        if (liveKind() === "qreep") {
            qreepCommand.show();
            return;
        }

        // "/browse path/filter": the input is the location.
        if (liveKind() === "browse") {
            browseCommand.show();
            return;
        }

        // "/win " lists windows; typing narrows them.
        if (liveKind() === "windows") {
            windowsCommand.show();
            return;
        }

        // "/p " lists Places' projects; typing narrows them.
        if (liveKind() === "projects") {
            projectsCommand.show();
            return;
        }

        // "/ssh " lists Places' ssh hosts; typing narrows them.
        if (liveKind() === "ssh") {
            sshCommand.show();
            return;
        }

        // "/keys " lists Hyprland binds; typing narrows them.
        if (liveKind() === "keys") {
            keysCommand.show();
            return;
        }

        // "/run cmd": history matches and a preview; nothing runs before Enter.
        if (liveKind() === "run") {
            runCommand.show();
            return;
        }

        if (parsed.mode === "unknown" && parsed.token.length > 0) {
            const guess = commands.suggest(parsed.token);

            if (guess)
                notice = "Did you mean /" + guess.name + "?";
        }

        // "/rg text" searches live after a short pause, from rgMinChars.
        if (grepCommand.wanted()) {
            if (contentState !== "grep" && contentState !== "compose")
                backToCompose();
            grepCommand.schedule();
            return;
        }

        if (grepCommand.flagProblem().length > 0)
            notice = grepCommand.flagProblem();

        // "/fd words" searches live after a short pause.
        if (filesCommand.wanted()) {
            if (contentState === "service")
                service.reset();
            if (contentState === "shots")
                shots.reset();
            filesCommand.schedule();
            return;
        }

        if (filesCommand.flagProblem().length > 0)
            notice = filesCommand.flagProblem();

        // "/last " and "/last 2" preview live, no Enter needed.
        if (shotsCommand.wanted()) {
            if (contentState === "service")
                service.reset();
            shotsCommand.schedule();
            return;
        }

        // Editing after a submit means a new question; drop the old request.
        if (contentState !== "compose")
            backToCompose();
    }

    // Host API for the Kip*Command files, next to contentState, parsed,
    // notice, chooserHit, docMarkdown, kt, closeRequested and clampIndex.
    // inputText is a function, not a binding: a binding on the text can lag
    // behind onTextChanged (see parsed).
    function inputText() {
        return promptInput.text;
    }

    function setInput(text) {
        promptInput.text = text;
        promptInput.cursorPosition = promptInput.text.length;
    }

    // The action menu for a file or folder hit (/fd, /rg and /browse share it).
    function chooseActionsFor(hit) {
        const title = hit.title || hit.folder + hit.file;

        if (hit.isDir) {
            openChooser(hit, title, kt.folderActions);
            return;
        }

        // Graph pages get the note openers; any other markdown is a file
        // like the rest, plus Vivify after nvim.
        if (/\.md$/i.test(hit.file) && hit.inLogseq) {
            openChooser(hit, "Open " + hit.file + " with", kt.markdownOpeners);
            return;
        }

        // A hit on a line (/rg) wants the editor first, not the default app.
        const actions = hit.atLine ? kt.fileActions.filter(action => action.id === "default").concat(kt.fileActions.filter(action => action.id !== "default")) : kt.fileActions;

        if (/\.md$/i.test(hit.file)) {
            const vivify = kt.markdownOpeners.filter(opener => opener.id === "vivify");

            openChooser(hit, title, actions.slice(0, 2).concat(vivify, actions.slice(2)));
            return;
        }

        openChooser(hit, title, actions);
    }

    // Which shortcut group applies right now (KipCommands.shortcutGroups ids).
    function shortcutContext() {
        if (chooserHit !== null)
            return "menus";
        if (contentState === "browse")
            return "browse";
        if (contentState === "qreep")
            return "qreep";
        if (contentState === "run")
            return "run";
        if (contentState === "shots")
            return "shots";
        if (contentState === "service")
            return answerDone() && !resultsVisible ? "answers" : "results";
        if (contentState === "files" || contentState === "windows" || contentState === "grep" || contentState === "keys" || contentState === "projects" || contentState === "ssh")
            return "results";
        if (appsMode)
            return "apps";
        return "everywhere";
    }

    // F1 launcher (empty input), F2 /browse at ~, F3 /fd, F4 /win. Same as typing it.
    function switchMode(text) {
        chooserHit = null;
        shortcutsOpen = false;
        setInput(text);
    }

    function backToCompose() {
        chooserHit = null;
        service.reset();
        shotsCommand.reset();
        filesCommand.reset();
        calc.reset();
        dict.reset();
        windowsCommand.reset();
        projectsCommand.reset();
        sshCommand.reset();
        keysCommand.reset();
        runCommand.reset();
        browseCommand.reset();
        grepCommand.reset();
        qreepCommand.reset();
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

    // The command whose live view the input currently asks for, or "".
    // Needs the space after the command, so "/ca" on the way somewhere stays quiet.
    function liveKind() {
        if (parsed.mode !== "ready" || parsed.command === null || promptInput.text.length <= parsed.token.length + 1)
            return "";
        return parsed.command.kind;
    }

    function refreshLiveDoc() {
        if (liveKind() === "calc")
            calc.evaluate(parsed.argument);
        else if (liveKind() === "def")
            dict.lookup(parsed.argument);
    }

    function showTimerPreview() {
        if (liveKind() !== "timer" && !(parsed.mode === "ready" && parsed.command && parsed.command.kind === "timer"))
            return;

        const planned = timerCommand.plan(parsed.argument);

        notice = planned.error;
        showDoc(planned.preview, "timer", "timer.ready");
    }

    // Static markdown in the answer viewer: /help, /tldr, /calc, /def, /timer.
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
        answerView.follow = false;
        renderAnswer();
        answerView.contentY = 0;
    }

    function handleKey(event) {
        // Mode keys work everywhere, menus included.
        const shifted = (event.modifiers & Qt.ShiftModifier) !== 0;
        const modeText = ({
                [Qt.Key_F1]: "",
                [Qt.Key_F2]: "/browse ",
                [Qt.Key_F3]: shifted ? "/rg " : "/fd ",
                [Qt.Key_F4]: "/win "
            })[event.key];

        if (modeText !== undefined) {
            event.accepted = true;
            switchMode(modeText);
            return;
        }

        if (event.key === Qt.Key_Slash && (event.modifiers & Qt.ControlModifier)) {
            event.accepted = true;
            shortcutsOpen = !shortcutsOpen;
            return;
        }

        if (shortcutsOpen && event.key === Qt.Key_Escape) {
            event.accepted = true;
            shortcutsOpen = false;
            return;
        }

        if (chooserHit !== null && handleChooserKey(event))
            return;

        // The current command's own keys first; what it leaves falls through.
        if (activeCommand !== null && activeCommand.handleKey(event))
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
            // Only in grids; otherwise the cursor keeps them.
            if (appsVisible) {
                appIndex = appView.neighbor(appIndex, event.key === Qt.Key_Right ? 1 : -1, 0);
                event.accepted = true;
            }
            return;
        case Qt.Key_Up:
        case Qt.Key_Down:
            {
                const step = event.key === Qt.Key_Down ? 1 : -1;

                if (appsVisible) {
                    appIndex = appView.neighbor(appIndex, 0, step);
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
        case Qt.Key_G:
            if (appsMode && (event.modifiers & Qt.ControlModifier)) {
                event.accepted = true;
                apps.cycleGrouping();
                appIndex = 0;
            }
            return;
        case Qt.Key_L:
            if (appsMode && (event.modifiers & Qt.ControlModifier)) {
                event.accepted = true;
                apps.toggleView();
                appIndex = 0;
            }
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
            submit((event.modifiers & Qt.ShiftModifier) !== 0);
            return;
        }
    }

    function submit(shifted) {
        if (activeCommand !== null) {
            activeCommand.submit(shifted === true);
            return;
        }

        if (contentState === "doc") {
            if (docKind === "tldr" && tldr.status === "done") {
                copyRequested(tldr.rawPage);
                notice = "Copied the tldr page for " + tldr.name + ".";
            } else if (docKind === "calc" && calc.status === "done") {
                copyRequested(calc.result);
                notice = "Copied " + calc.result + ".";
            } else if (docKind === "def" && dict.status === "done") {
                copyRequested(dict.plainText());
                notice = "Copied the definition of " + dict.word + ".";
            } else if (docKind === "timer") {
                const planned = timerCommand.plan(parsed.argument);

                if (planned.valid) {
                    timerCommand.run(planned);
                    closeRequested();
                } else if (planned.error.length > 0) {
                    notice = planned.error;
                }
            }
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
        case "idle":
        case "plain":
            launchSelectedApp();
            return;
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
        }
    }

    function launchSelectedApp() {
        const entry = appView.selectedEntry;

        if (!appsVisible || !entry) {
            notice = appsQuery.length > 0 ? "No app matches \"" + appsQuery + "\". /ask if it was a question." : "";
            return;
        }

        apps.launch(entry);
        closeRequested();
    }

    function run(kind, argument, detailed) {
        // Local commands never reach the model, even if Enter beats the
        // live preview's debounce.
        switch (kind) {
        case "qreep":
            qreepCommand.show();
            return;
        case "grep":
            grepCommand.searchNow();
            return;
        case "browse":
            browseCommand.show();
            return;
        case "apps":
            launchSelectedApp();
            return;
        case "calc":
            liveDocTimer.stop();
            calc.evaluate(argument);
            return;
        case "def":
            liveDocTimer.stop();
            dict.lookup(argument);
            return;
        case "tldr":
            tldrTimer.stop();
            tldr.lookup(argument);
            showTldr();
            return;
        case "timer":
            showTimerPreview();
            return;
        case "windows":
            windowsCommand.show();
            return;
        case "projects":
            projectsCommand.show();
            return;
        case "ssh":
            sshCommand.show();
            return;
        case "keys":
            keysCommand.show();
            return;
        case "run":
            runCommand.show();
            return;
        case "help":
            showDoc(commands.helpMarkdown(argument), "help", "");
            return;
        }

        if (kind === "files") {
            if (filesCommand.flagProblem().length === 0)
                filesCommand.search();
            return;
        }

        if (kind === "screenshots") {
            shotsCommand.load(argument);
            return;
        }

        contentState = "service";
        answerView.follow = true;
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
                return answerView.selectedText.length > 0;
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
            copyRequested(answerView.toPlain(service.answer));
            notice = "Copied the answer as plain text.";
            return;
        case "copy-selection":
            copyRequested(answerView.selectedText);
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
        answerView.render();
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

    function openChooser(item, title, options, preview) {
        chooserOptions = options;
        chooserTitle = title;
        chooserPreview = preview || "";
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

        setInput("/" + command.name + (command.takesArgument ? " " : ""));
        paletteIndex = 0;
    }

    function refreshMessage() {
        messageIcon = "";

        if (messageKey === "kip.open" && Math.random() < kt.appNudgeChance && nudgeAboutApps())
            return;

        currentMessage = messages.pick(messageKey, {
            count: contentState === "shots" ? shots.shots.length : contentState === "files" ? files.results.length : contentState === "windows" ? windows.results.length : service.results.length
        });
    }

    // A habit remark instead of the generic open line. Selects the app it
    // talks about, so "Enter" in the line is a promise the panel keeps.
    function nudgeAboutApps() {
        const nudge = apps.nudge();

        if (!nudge || !appsMode)
            return false;

        const tiles = appView.layout.tiles;
        const index = tiles.findIndex(tile => tile.entry.id === nudge.entry.id);

        if (index < 0)
            return false;

        currentMessage = messages.pick("apps.nudge." + nudge.kind, nudge.values);
        messageIcon = apps.iconSource(nudge.entry);
        appIndex = index;
        return true;
    }

    function enterLabel() {
        if (chooserHit !== null)
            return "pick";
        if (activeCommand !== null)
            return activeCommand.enterLabel();
        if (appsMode)
            return appsVisible ? "launch" : "";
        if (contentState === "doc") {
            if (docKind === "tldr")
                return tldr.status === "done" ? "copy page" : "";
            if (docKind === "calc")
                return calc.status === "done" ? "copy" : "";
            if (docKind === "def")
                return dict.status === "done" ? "copy" : "";
            if (docKind === "timer")
                return timerCommand.plan(parsed.argument).valid ? "do it" : "";
            return "";
        }
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
            return "↑↓ or 1–" + chooserOptions.length + " choose · Enter do it · Esc cancel";
        if (activeCommand !== null)
            return activeCommand.keyHints();
        if (contentState === "doc" && (docKind === "calc" || docKind === "def")) {
            // Only promise a copy when there is something to copy.
            const ready = docKind === "calc" ? calc.status === "done" : dict.status === "done";
            return (ready ? "Enter copies · " : "") + "Esc back · keep typing";
        }
        if (contentState === "doc" && docKind === "timer")
            return "Enter does it and closes KIP · Esc back";
        if (contentState === "doc" && docKind === "tldr")
            return tldr.status === "done" ? "Copy on an example · Enter copies the page · Esc back" : "Esc back · keep typing";
        if (contentState === "doc")
            return "select + Ctrl+C copies · Esc back · keep typing";
        if (contentState === "service") {
            if (service.status === "error")
                return "Enter retry · Esc back · keep typing to start over";
            if (answerDone())
                return (resultsVisible ? "↑↓ sources · Tab source text · " : "") + "Enter actions · select + Ctrl+C · Esc back";
            return resultsVisible ? "↑↓ move · Enter open · Tab source · Ctrl+Shift+C copy path · Esc back" : "Esc back · keep typing to start over";
        }
        if (appsMode)
            return (appsVisible ? "←→↑↓ move · Enter launch · " : "no app matches · ") + "Ctrl+G group · Ctrl+L grid/list · / commands · Esc close";
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
