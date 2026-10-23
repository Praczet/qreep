import QtQuick
import Quickshell

QtObject {
    id: rootKipTheme

    required property QtObject qreep

    // Placement. Quickshell screen sizes are logical pixels, so these already
    // respect Hyprland scaling.
    // Input box top. The header sits cardPadding + headerHeroSpace +
    // headerHeight + headerGap above it; the card itself always reaches up
    // to attachY, so the room above the header is just more banner.
    readonly property int anchorY: 230
    // Screen-edge line the card hangs from. 0 covers the bar; set it to the
    // bar height to hang from the bar instead.
    readonly property int attachY: 0
    // Concave flares joining the card to the edge, like a drawer pulled out
    // of it: how far they reach out sideways and down the card's sides.
    readonly property int shoulderWidth: 80
    readonly property int shoulderHeight: 120
    readonly property int panelWidth: 880
    readonly property int screenMargin: 24
    readonly property int signalTopY: 4

    // Motion. reducedMotion skips the deployment theatre entirely.
    readonly property bool reducedMotion: false
    readonly property int openDuration: 480
    readonly property int closeDuration: 340
    readonly property int contentFadeDuration: 140
    readonly property int bodyResizeDuration: 180

    // The whole surface deploys on one eased openProgress curve. signalEnd
    // only controls the quick initial fade; it is not a separate movement.
    // The input is full size and typeable throughout.
    readonly property real signalEnd: 0.15

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
    readonly property var openCommand: qreep.terminalCommand(["nvim", "+{line}", "{path}"])

    // Header banner behind the title and input, faded into the card so the
    // body stays plain. "bloom" follows Unclaimed Bloom's current wallpaper
    // (bloomWallpaperFile, watched, so wallset updates it live); any other
    // value is an image path; "" turns it off.
    readonly property string headerImage: "bloom"
    readonly property string bloomWallpaperFile: Quickshell.env("HOME") + "/.cache/unclaimed-bloom/current-wallpaper"
    // Picture room between the title row (top of the card) and the input,
    // so the banner shows an image and not just a backdrop for text.
    // 0 is the old compact header.
    readonly property int headerHeroSpace: 100
    readonly property int headerImageHeight: 250
    readonly property real headerImageOpacity: 0.6
    // Fraction of the banner height that stays solid before the fade starts.
    readonly property real headerImageFadeStart: 0.55
    // top | center | bottom: which part of a cropped wallpaper stays visible.
    readonly property string headerImageAlign: "center"

    // App launcher: the default view (empty input), plain text and /app.
    // Grouping and view start here and are switchable at runtime
    // (Ctrl+G / Ctrl+L or the toolbar); a Quickshell restart forgets them.
    readonly property string appDefaultGrouping: "category" // category | name | letter
    readonly property string appDefaultView: "grid" // grid | list
    readonly property int appGridColumns: 6
    readonly property int appListColumns: 2
    readonly property int appGridCellHeight: 118
    readonly property int appListRowHeight: 54
    readonly property int appSectionHeaderHeight: 28
    // Icon sizes; the cell/row heights above leave room for them plus text.
    readonly property int appGridIconSize: 56
    readonly property int appListIconSize: 36
    // /win: grid | list, icon | preview (Ctrl+L / Ctrl+P). Previews are live
    // ScreencopyView captures matched through Expose; unmatched windows show the icon.
    readonly property string windowDefaultView: "grid"
    readonly property string windowDefaultDisplay: "preview"
    readonly property int windowGridColumns: 3
    readonly property int windowGridIconCellHeight: 130
    readonly property int windowGridPreviewCellHeight: 200
    readonly property int windowListIconRowHeight: appListRowHeight
    readonly property int windowListPreviewRowHeight: 84
    readonly property int windowListPreviewWidth: 128
    readonly property int windowGridIconSize: appGridIconSize
    readonly property int windowListIconSize: appListIconSize
    readonly property int windowCaptionHeight: 44
    readonly property int appMostUsedCount: 10
    readonly property int appRecentCount: 5
    // On a fresh open, this often KIP comments on your habits instead of a
    // generic line: top app, the app you open around this hour, or the one
    // you just used. It shows the app's icon and preselects it. Needs at
    // least appNudgeMinLaunches launches of that app; 0 turns it off.
    readonly property real appNudgeChance: 0.5
    readonly property int appNudgeMinLaunches: 3
    // "recent" only counts if the last launch is this fresh (ms).
    readonly property int appNudgeRecentWindow: 3 * 60 * 60 * 1000
    readonly property int messageIconSize: 22
    // Desktop entries with Terminal=true run in this, as `<terminal> -e <command>`.

    // /last
    readonly property string screenshotDir: Quickshell.env("HOME") + "/Pictures/Screenshots"
    readonly property int maxScreenshots: 20
    readonly property int screenshotColumns: 4
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

    // Enter after a finished answer. local: handled by the panel, no command.
    // Order is the chooser order; the first that applies is the default.
    readonly property var answerActions: [
        {
            id: "copy-markdown",
            label: "Copy answer",
            hint: "as Markdown",
            icon: "󰆏",
            local: true
        },
        {
            id: "copy-plain",
            label: "Copy plain",
            hint: "as plain text, markers stripped",
            icon: "󰅍",
            local: true
        },
        {
            id: "copy-selection",
            label: "Copy selection",
            hint: "the text you selected",
            icon: "󰆐",
            local: true
        },
        {
            id: "open-source",
            label: "Open source",
            hint: "the highlighted source note",
            icon: "󰈙",
            local: true
        },
        {
            id: "retry",
            label: "Retry",
            hint: "ask again; replaces this answer",
            icon: "󰑐",
            local: true
        },
        {
            id: "explain",
            label: "More detail",
            hint: "ask again for a longer explanation",
            icon: "󰈈",
            local: true
        }
    ]

    // /calc: -t terse is avoided on purpose; the "x = y" form carries qalc's
    // interpretation. -nocurrencies: no exchange rates, no network.
    readonly property string calcCommand: "qalc"
    readonly property var calcArguments: ["-nocurrencies"]
    // /def
    readonly property string dictCommand: "sdcv"
    // /calc, /def, /timer previews refresh after this pause in typing.
    readonly property int liveDocDebounce: 180

    // /run
    readonly property int runHistoryShown: 8
    readonly property int runDebounce: 220

    // /tldr reads the tldr client's cache directly; it never runs the client.
    readonly property string tldrCacheDir: Quickshell.env("HOME") + "/.cache/tldr"
    readonly property var tldrPlatforms: ["linux", "common"]
    readonly property int tldrDebounce: 250

    // /fd
    readonly property string fdCommand: "fd"
    readonly property string fdDefaultRoot: "~"
    // fd stops itself here; KIP ranks what came back and shows fdShownResults.
    readonly property int fdMaxResults: 200
    readonly property int fdShownResults: 50
    readonly property int fdDebounce: 250
    // Only bite when searching /; harmless elsewhere (anchored to the search root).
    readonly property var fdExcludes: ["/proc", "/sys", "/dev", "/run"]
    // /qreep: what is listed lives in KipQreepCatalog.qml; these are just sizes.
    // Icon box matches appListIconSize so /qreep and the launcher list read alike.
    readonly property int qreepRowHeight: 48
    readonly property int qreepSectionHeight: 38
    // Group headers sit a step above row labels (bodyPixelSize) so they read as headers.
    readonly property int qreepSectionPixelSize: 14
    readonly property int qreepSectionIconPixelSize: 20
    readonly property int qreepIconBoxSize: appListIconSize
    readonly property int qreepIconPixelSize: 22
    readonly property int qreepToggleRowHeight: 38
    readonly property int qreepSwitchWidth: 36
    readonly property int qreepSwitchHeight: 20

    // /rg: ripgrep over file contents. Searching ~ is fine because rg skips
    // gitignored files; the caps keep a common word from becoming a novel.
    readonly property string rgCommand: "rg"
    readonly property string rgDefaultRoot: "~"
    readonly property int rgMaxResults: 200
    readonly property int rgMaxPerFile: 5
    readonly property int rgMaxColumns: 300
    readonly property string rgMaxFileSize: "2M"
    readonly property int rgDebounce: 300
    // Fewer characters than this do not search live (Enter still does).
    readonly property int rgMinChars: 3
    readonly property var rgExcludeGlobs: [".git", "node_modules"]

    // /browse starts with these; Alt+H / Alt+I / Alt+P flip them for the
    // session. respectGitignore hides what .gitignore/.ignore would hide.
    readonly property bool browseShowHidden: false
    readonly property bool browseRespectGitignore: false
    readonly property bool browsePreview: false
    // Text preview reads at most this much of the selected file.
    readonly property int browsePreviewBytes: 4096

    // Folders open here, not through xdg-open: the inode/directory default is
    // yazi, a Terminal=true app, and plain xdg-open has no terminal to put it
    // in, so it exited without a word. superfile (spf) gets the folder, not
    // the file: it has no "open with this file hovered" trick.
    readonly property var fileManagerCommand: qreep.terminalCommand(["spf"])
    readonly property var folderActions: [
        {
            id: "file-manager",
            label: "Open",
            hint: "in superfile",
            icon: "󰉋",
            command: fileManagerCommand.concat(["{path}"])
        },
        {
            id: "terminal",
            label: "Terminal",
            hint: qreep.terminal + " in this folder",
            icon: "󰆍",
            command: qreep.terminalCommand([], {
                cwd: "{path}"
            })
        },
        {
            id: "broot",
            label: "Broot",
            hint: "browse it in broot",
            icon: "󰙅",
            command: qreep.terminalCommand(["broot", "{path}"])
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
            icon: "󰕷",
            command: openCommand
        },
        {
            id: "folder",
            label: "Folder",
            hint: "its folder in superfile",
            icon: "󰉋",
            command: fileManagerCommand.concat(["{dir}"])
        },
        {
            id: "terminal",
            label: "Terminal",
            hint: qreep.terminal + " in its folder",
            icon: "󰆍",
            command: qreep.terminalCommand([], {
                cwd: "{dir}"
            })
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
            icon: "󰕷",
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
    readonly property string monoFontFamily: "FiraCode Nerd Font"

    // Microcopy tone: "neutral" or "dry". Unknown tones fall back to neutral.
    readonly property string tone: "dry"

    readonly property string kipIcon: "󰚩"

    // Deliberately above qreep-kip's Hyprland ignore_alpha (0.1): this gives
    // the compositor a full-screen blur region behind the crisp KIP surface.
    readonly property color backdropColor: withAlpha(qreep.background, 0.18)
    readonly property real cardOpacity: 0.9
    readonly property color cardColor: withAlpha(qreep.surface, cardOpacity)
    readonly property color inputColor: withAlpha(qreep.surfaceContainerHighest, 0.78)
    // Opaque: the chooser floats over screenshots and lists.
    readonly property color chooserColor: qreep.surfaceContainerHighest
    readonly property real chooserOverlayMaxWidth: 520
    // Screenshot thumbnail beside the actions; the menu widens to fit it.
    readonly property real chooserPreviewWidth: 180
    readonly property real chooserOverlayMargin: 24
    readonly property real chooserShadowBlur: 1.0
    readonly property real chooserShadowOffset: 6
    readonly property color chooserShadowColor: Qt.rgba(0, 0, 0, 0.55)
    readonly property color borderColor: qreep.outline
    readonly property color focusBorderColor: qreep.primary
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
    // KIP's own voice under the input: brighter than secondary text on purpose.
    readonly property color messageColor: qreep.on_surface
    readonly property int messagePixelSize: 15
    readonly property color messageShadowColor: Qt.rgba(0, 0, 0, 0.6)

    // Result path styling: folder and basename deliberately differ.
    readonly property color folderColor: qreep.on_surface_variant
    readonly property color fileColor: qreep.primary
    readonly property color lineNumberColor: qreep.tertiary

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
