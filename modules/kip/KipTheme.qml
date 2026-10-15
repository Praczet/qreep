import QtQuick
import Quickshell

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
    // Lowest the bottom-edge drag may shrink the body to.
    readonly property int minBodyHeight: 120
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

    // /last
    readonly property string screenshotDir: Quickshell.env("HOME") + "/Pictures/Screenshots"
    readonly property int maxScreenshots: 12
    readonly property int screenshotColumns: 3
    readonly property int screenshotSinglePreviewHeight: 280
    // Enter on a screenshot asks; the first entry is the default. {mime} is
    // derived from the extension. sh only for the stdin redirect; values go in
    // as $1/$2, never into the script text.
    readonly property var screenshotActions: [
        {
            id: "copy-image",
            label: "Copy image",
            hint: "to the clipboard, as an image",
            icon: "󰆏",
            command: ["sh", "-c", "wl-copy --type \"$1\" < \"$2\"", "kip-copy-image", "{mime}", "{path}"]
        },
        {
            id: "copy-path",
            label: "Copy path",
            hint: "the file path as text",
            icon: "󰅍",
            command: ["wl-copy", "{path}"]
        },
        {
            id: "show",
            label: "Show image",
            hint: "in the default image viewer",
            icon: "󰋩",
            command: ["xdg-open", "{path}"]
        }
    ]

    // /fd
    readonly property string fdCommand: "fd"
    readonly property string fdDefaultRoot: "~"
    // fd stops itself here; KIP ranks what came back and shows fdShownResults.
    readonly property int fdMaxResults: 200
    readonly property int fdShownResults: 50
    readonly property int fdDebounce: 250
    // Only bite when searching /; harmless elsewhere (anchored to the search root).
    readonly property var fdExcludes: ["/proc", "/sys", "/dev", "/run"]
    readonly property var folderActions: [
        {
            id: "file-manager",
            label: "Open",
            hint: "in the file manager",
            icon: "󰉋",
            command: ["xdg-open", "{path}"]
        },
        {
            id: "terminal",
            label: "Terminal",
            hint: "ghostty in this folder",
            icon: "",
            command: ["ghostty", "--working-directory={path}"]
        },
        {
            id: "broot",
            label: "Broot",
            hint: "browse it in broot",
            icon: "󰙅",
            command: ["ghostty", "-e", "broot", "{path}"]
        },
        {
            id: "copy-path",
            label: "Copy path",
            hint: "the folder path as text",
            icon: "󰅍",
            command: ["wl-copy", "{path}"]
        }
    ]
    readonly property var fileActions: [
        {
            id: "open",
            label: "Open",
            hint: "with the default app",
            icon: "󰏌",
            command: ["xdg-open", "{path}"]
        },
        {
            id: "default",
            label: "nvim",
            hint: "in a terminal",
            icon: "",
            command: openCommand
        },
        {
            id: "folder",
            label: "Folder",
            hint: "open the containing folder",
            icon: "󰉋",
            command: ["xdg-open", "{dir}"]
        },
        {
            id: "copy-path",
            label: "Copy path",
            hint: "the file path as text",
            icon: "󰅍",
            command: ["wl-copy", "{path}"]
        }
    ]

    // {graph} and {page} are URL-encoded before substitution.
    readonly property string logseqGraph: "Logseq"
    // Where that graph lives, for recognizing /fd hits as Logseq pages.
    readonly property string logseqGraphDir: Quickshell.env("HOME") + "/Notes/Logseq"
    // A cold-started Logseq drops logseq:// links while it loads the graph.
    // When it was not running, KIP waits for its window, then resends the link
    // after each of these delays (ms). Resending to an open page is harmless.
    readonly property string logseqAppId: "Logseq"
    readonly property var logseqColdStartResendDelays: [2000, 5000]
    readonly property int logseqColdStartTimeout: 30000
    // Any .md hit asks "Open with" first; the first entry that applies is the
    // default. logseqOnly entries appear only for files in the Logseq graph.
    readonly property var markdownOpeners: [
        {
            id: "logseq",
            label: "Logseq",
            logseqOnly: true,
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

    // Answer typography (KipMarkdown). Rich text wants opaque colours, so the
    // code surfaces are tinted from the card colour instead of using alpha.
    readonly property int answerPixelSize: 14
    readonly property int answerLineHeight: 145
    readonly property int answerParagraphGap: 9
    readonly property int answerHeadingTopGap: 14
    readonly property int answerHeadingBottomGap: 5
    readonly property int answerListItemGap: 3
    readonly property int answerRenderInterval: 120
    readonly property string answerHeadingColor: String(qreep.primary)
    readonly property string answerCodeColor: String(qreep.on_surface)
    readonly property string answerMetaColor: String(qreep.on_surface_variant)
    readonly property string answerLinkColor: String(qreep.primary)
    readonly property string answerQuoteColor: String(qreep.on_surface_variant)
    readonly property string answerQuoteBarColor: String(qreep.outline)
    readonly property string answerCodeBackground: String(Qt.tint(qreep.surface, Qt.rgba(0, 0, 0, 0.28)))
    readonly property string answerInlineCodeBackground: String(Qt.tint(qreep.surface, Qt.rgba(qreep.on_surface.r, qreep.on_surface.g, qreep.on_surface.b, 0.1)))
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
