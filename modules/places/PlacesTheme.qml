import QtQuick
import Quickshell

QtObject {
    id: rootPlacesTheme

    required property QtObject qreep

    readonly property string configPath: Quickshell.env("HOME") + "/.config/qreep/places.json"
    // Project icons (coma-symbolic, eos-symbolic, ...) live here, outside the
    // active Qt icon theme, so the theme lookup alone misses them.
    readonly property string iconFallbackDir: Quickshell.env("HOME") + "/.local/share/icons/ADArtWork/scalable/apps"

    // Panel size follows the screen it opens on. Height leads (82% of the
    // screen), width follows at 1.6x height, then both are clamped: never
    // smaller than the old fixed 1180x760, never wider than 90% of the
    // screen. On a 5120x1440 ultrawide that is ~1890x1180; on 1920x1200,
    // ~1574x984. Sizing from width alone would fill the whole ultrawide.
    readonly property real panelHeightRatio: 0.82
    readonly property real panelAspect: 1.6
    readonly property real panelMaxWidthRatio: 0.9
    readonly property int panelMinWidth: 1180
    readonly property int panelMinHeight: 760
    readonly property int screenMargin: 48
    readonly property int panelPadding: 18
    readonly property int panelRadius: 20
    // List column: 28% of the panel, at least 340.
    readonly property real listWidthRatio: 0.28
    readonly property int listMinWidth: 340
    readonly property int sectionGap: 16
    readonly property int cardRadius: 12
    readonly property int cardPadding: 14
    readonly property int rowHeight: 64
    // File / event / todo rows: text, icons at twice its size, room for both.
    readonly property int fileRowTextPixelSize: metaPixelSize + 1
    readonly property int fileRowIconPixelSize: 2 * fileRowTextPixelSize
    readonly property int fileRowHeight: fileRowIconPixelSize + 8
    readonly property int rowRadius: 10
    readonly property int listIconSize: 30
    readonly property int heroIconSize: 54
    readonly property int searchHeight: 44
    // Main action buttons: bigger than chips, they are what Enter runs.
    readonly property int actionHeight: 40
    readonly property int actionRadius: 12
    readonly property int actionPadding: 16
    readonly property int actionPixelSize: 14
    readonly property int actionIconPixelSize: 17
    readonly property int footerHeight: 30

    readonly property int titlePixelSize: 24
    readonly property int sectionPixelSize: 12
    readonly property int bodyPixelSize: 13
    readonly property int metaPixelSize: 11
    readonly property int searchPixelSize: 17
    readonly property string monoFontFamily: "FiraCode Nerd Font"

    // Lists fetch this many; the detail pane shows as many as fit (rowsFor()).
    readonly property int recentFileLimit: 20
    readonly property int recentFileDays: 14
    readonly property int commitLimit: 20
    readonly property int docLimit: 30
    readonly property int minListRows: 6
    readonly property int maxListRows: 18
    // Year grid: 53 columns so the current partial week fits after 52 full ones.
    readonly property int activityWeeks: 53
    readonly property int activityCellGap: 3
    readonly property int activityMaxCell: 16
    readonly property int languageLimit: 8
    readonly property int animationDuration: 180
    // Blur radius for the panel content under the chooser and the F1 sheet.
    readonly property int overlayBlurMax: 24

    readonly property real overlayOpacity: 0.32
    readonly property real panelOpacity: 0.93
    readonly property color overlayColor: Qt.rgba(qreep.background.r, qreep.background.g, qreep.background.b, overlayOpacity)
    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, panelOpacity)
    readonly property color cardColor: withAlpha(qreep.surfaceContainer, 0.82)
    readonly property color listColor: withAlpha(qreep.surfaceContainerLowest, 0.45)
    readonly property color searchColor: withAlpha(qreep.surfaceContainerHighest, 0.8)
    readonly property color borderColor: qreep.outline
    readonly property color hoveredRowColor: withAlpha(qreep.surfaceContainerHigh, 0.55)
    readonly property color selectedRowColor: withAlpha(qreep.primary, 0.16)
    readonly property color selectedBorderColor: qreep.primary
    readonly property color chipColor: withAlpha(qreep.surfaceContainerHigh, 0.85)

    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color sectionColor: qreep.tertiary
    readonly property color successColor: qreep.successColor
    readonly property color warningColor: qreep.warningColor
    readonly property color errorColor: qreep.error
    readonly property color trackColor: withAlpha(qreep.on_surface_variant, 0.35)

    function panelHeightFor(screenWidth, screenHeight) {
        return Math.min(screenHeight - screenMargin, Math.max(panelMinHeight, Math.round(screenHeight * panelHeightRatio)));
    }

    function panelWidthFor(screenWidth, screenHeight) {
        const wanted = Math.max(panelMinWidth, Math.round(panelHeightFor(screenWidth, screenHeight) * panelAspect));
        return Math.min(screenWidth - screenMargin, Math.round(screenWidth * panelMaxWidthRatio), wanted);
    }

    function listWidthFor(panelWidth) {
        return Math.max(listMinWidth, Math.round(panelWidth * listWidthRatio));
    }

    // Quest/step status -> color. Unknown statuses fall back to secondary text.
    function statusColor(status) {
        switch (String(status || "")) {
        case "done":
            return successColor;
        case "active":
            return accentColor;
        case "blocked":
            return errorColor;
        case "paused":
            return warningColor;
        default:
            return secondaryTextColor;
        }
    }

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
