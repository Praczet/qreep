import QtQuick
import Quickshell

QtObject {
    id: rootWallpaperTheme

    required property QtObject qreep

    // Where wallpapers live (same default as Unclaimed Bloom's wallset), the
    // thumbnail cache, and what applies one: wallset with a path skips its own
    // picker and runs the Unclaimed Bloom pipeline (sow, grow, awww, plant).
    readonly property string wallpaperDir: Quickshell.env("UB_WALLPAPER_DIR") || Quickshell.env("HOME") + "/.config/backgrounds"
    readonly property string thumbnailDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/qreep/wallpapers"
    readonly property string currentWallpaperFile: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/unclaimed-bloom/current-wallpaper"
    readonly property string applyCommand: Quickshell.env("HOME") + "/.local/bin/wallset"
    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/qreep/wallpaper.json"
    // Unclaimed Bloom profiles: the picker lists the compositions (whole-desktop
    // setups) and, on apply, switches with `spore profile use` before wallset.
    readonly property string sporeCommand: Quickshell.env("HOME") + "/.local/bin/spore"
    readonly property string currentProfileFile: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/unclaimed-bloom/current-profile"

    // Grid tile sizes (image box). S-L use the 400x300 thumbnails, XL the
    // 800x600 ones, so a small grid never decodes big files.
    readonly property var sizes: ({
            s: { label: "S", width: 160, height: 120, thumb: 400 },
            m: { label: "M", width: 240, height: 180, thumb: 400 },
            l: { label: "L", width: 400, height: 300, thumb: 400 },
            xl: { label: "XL", width: 800, height: 600, thumb: 800 }
        })
    readonly property var sizeOrder: ["s", "m", "l", "xl"]
    // The preview pane earns its space only where tiles are too small to judge.
    readonly property var previewSizes: ["s", "m"]

    // Same footprint rules as Places, a little wider: grids like width.
    readonly property real panelHeightRatio: 0.82
    readonly property real panelAspect: 2.0
    readonly property real panelMaxWidthRatio: 0.9
    readonly property int panelMinWidth: 1180
    readonly property int panelMinHeight: 760
    readonly property int screenMargin: 48
    readonly property int panelPadding: 18
    readonly property int panelRadius: 20
    readonly property real previewWidthRatio: 0.36
    readonly property int sectionGap: 16
    readonly property int searchHeight: 44
    readonly property int tileGap: 12
    readonly property int tilePadding: 6
    readonly property int tileLabelHeight: 22
    readonly property int tileRadius: 10
    readonly property int listRowHeight: 64
    readonly property int listThumbWidth: 96
    readonly property int footerHeight: 30
    readonly property int chipHeight: 26
    readonly property int profileMenuWidth: 320
    readonly property int profileRowHeight: 32

    readonly property int titlePixelSize: 20
    readonly property int bodyPixelSize: 13
    readonly property int metaPixelSize: 11
    readonly property int searchPixelSize: 17
    readonly property int animationDuration: 180

    readonly property real overlayOpacity: 0.32
    // A normal window now: Hyprland's window blur sits behind the whole card.
    readonly property real panelOpacity: 0.75
    readonly property color overlayColor: Qt.rgba(qreep.background.r, qreep.background.g, qreep.background.b, overlayOpacity)
    // The F1 sheet sits on the dimmed card: solid enough to read.
    readonly property color sheetColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, 0.96)
    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, panelOpacity)
    readonly property color cardColor: withAlpha(qreep.surfaceContainer, 0.6)
    readonly property color imageBackgroundColor: withAlpha(qreep.surfaceContainerLowest, 0.6)
    readonly property color searchColor: withAlpha(qreep.surfaceContainerHighest, 0.8)
    readonly property color borderColor: qreep.outline
    readonly property color hoveredColor: withAlpha(qreep.surfaceContainerHigh, 0.55)
    readonly property color selectedColor: withAlpha(qreep.primary, 0.16)
    readonly property color selectedBorderColor: qreep.primary
    readonly property color chipColor: withAlpha(qreep.surfaceContainerHigh, 0.85)
    readonly property color activeChipColor: withAlpha(qreep.primary, 0.28)

    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color currentColor: qreep.successColor
    readonly property color errorColor: qreep.error

    function panelHeightFor(screenWidth, screenHeight) {
        return Math.min(screenHeight - screenMargin, Math.max(panelMinHeight, Math.round(screenHeight * panelHeightRatio)));
    }

    function panelWidthFor(screenWidth, screenHeight) {
        const wanted = Math.max(panelMinWidth, Math.round(panelHeightFor(screenWidth, screenHeight) * panelAspect));
        return Math.min(screenWidth - screenMargin, Math.round(screenWidth * panelMaxWidthRatio), wanted);
    }

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
