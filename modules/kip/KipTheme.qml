import QtQuick

QtObject {
    id: rootKipTheme

    required property QtObject qreep

    // Placement. Quickshell screen sizes are logical pixels, so these already
    // respect Hyprland scaling.
    readonly property int anchorY: 100
    readonly property int panelWidth: 780
    readonly property int screenMargin: 24
    readonly property int signalTopY: 4

    // Motion. reducedMotion skips the line/descend/morph theatre entirely.
    readonly property bool reducedMotion: false
    readonly property int openDuration: 880
    readonly property int closeDuration: 340
    readonly property int contentFadeDuration: 140
    readonly property int bodyResizeDuration: 180

    // openProgress slices: signal → descend → morph → assemble.
    readonly property real signalEnd: 0.12
    readonly property real descendEnd: 0.45
    readonly property real morphEnd: 0.72

    readonly property int lineHeight: 2
    readonly property int lineStartWidth: 120
    readonly property real lineDescendWidthRatio: 0.62

    // Card and input.
    readonly property int cardPadding: 14
    readonly property int cardRadius: 14
    readonly property int headerHeight: 30
    readonly property int headerGap: 10
    readonly property int inputHeight: 48
    readonly property int inputRadius: 10
    readonly property int inputPadding: 14
    readonly property int inputIconWidth: 30
    readonly property int bodyGap: 12
    readonly property int maxBodyHeight: 600
    readonly property int rowHeight: 52
    readonly property int commandRowHeight: 38
    readonly property int rowRadius: 7
    readonly property int rowGap: 4
    readonly property int chipRadius: 6

    readonly property int titlePixelSize: 15
    readonly property int subtitlePixelSize: 10
    readonly property int inputPixelSize: 17
    readonly property int bodyPixelSize: 13
    readonly property int metaPixelSize: 10
    readonly property int iconPixelSize: 18
    readonly property int headerIconPixelSize: 17

    // Backend. "jarvis" for real, "mock" for UI work without Ollama.
    readonly property string backend: "jarvis"
    readonly property string backendCommand: "jarvis"
    // Hits below this embedding similarity are shown dimmed as weak guesses.
    // Jarvis always returns its top 8, even for nonsense queries. Measured
    // 2026-10-15: real hits 0.30–0.48, gibberish ~0.20.
    readonly property real weakSimilarity: 0.25

    // Open a source at a line. Plain argv, no shell; {path} and {line} are
    // substituted per argument.
    readonly property var openCommand: ["ghostty", "-e", "nvim", "+{line}", "{path}"]

    // Logseq markdown hits ask "Open with" first; the first entry is the default.
    // {graph} and {page} are URL-encoded before substitution.
    readonly property string logseqGraph: "Logseq"
    // A cold-started Logseq drops logseq:// links while it loads the graph.
    // When it was not running, KIP waits for its window, then resends the link
    // after each of these delays (ms). Resending to an open page is harmless.
    readonly property string logseqAppId: "Logseq"
    readonly property var logseqColdStartResendDelays: [2000, 5000]
    readonly property int logseqColdStartTimeout: 30000
    readonly property var logseqOpeners: [
        {
            id: "logseq",
            label: "Logseq",
            hint: "the page in the Logseq app",
            icon: "󰠮",
            command: ["xdg-open", "logseq://graph/{graph}?page={page}"]
        },
        {
            id: "default",
            label: "Default",
            hint: "nvim at the line",
            icon: "",
            command: openCommand
        },
        {
            id: "vivify",
            label: "Vivify",
            hint: "rendered in the browser, scrolled to the line",
            icon: "󰈈",
            command: ["viv", "{path}:{line}"]
        }
    ]
    readonly property var copyCommand: ["wl-copy", "{text}"]

    readonly property int snippetMaxHeight: 180
    readonly property int answerMaxHeight: 260
    readonly property string monoFontFamily: "FiraCode Nerd Font"

    // Microcopy tone: "neutral" or "dry". Unknown tones fall back to neutral.
    readonly property string tone: "dry"

    readonly property string kipIcon: "󰚩"

    readonly property real cardOpacity: 0.9
    readonly property color cardColor: withAlpha(qreep.surface, cardOpacity)
    readonly property color inputColor: withAlpha(qreep.surfaceContainerHighest, 0.78)
    readonly property color borderColor: qreep.outline
    readonly property color focusBorderColor: qreep.primary
    readonly property color lineColor: qreep.primary
    readonly property color glowColor: withAlpha(qreep.primary, 0.32)
    readonly property color accentColor: qreep.primary
    readonly property color secondaryAccentColor: qreep.secondary
    readonly property color tertiaryAccentColor: qreep.tertiary
    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color errorColor: qreep.error
    readonly property color warningColor: qreep.warningColor
    readonly property color successColor: qreep.successColor
    readonly property color commandHighlightColor: withAlpha(qreep.primary, 0.2)
    readonly property color chipColor: withAlpha(qreep.surfaceContainerHigh, 0.85)
    readonly property color hoveredRowColor: withAlpha(qreep.surfaceContainerHigh, 0.5)
    readonly property color selectedRowColor: withAlpha(qreep.primary, 0.16)

    // Result path styling: folder and basename deliberately differ.
    readonly property color folderColor: qreep.on_surface_variant
    readonly property color fileColor: qreep.primary
    readonly property color lineNumberColor: qreep.tertiary

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
