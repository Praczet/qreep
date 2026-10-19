import QtQuick
import Quickshell

QtObject {
    id: rootPrismTheme

    required property QtObject qreep

    // One JSON file: history, favourites, palettes.
    readonly property string storePath: Quickshell.env("HOME") + "/.local/share/qreep/prism.json"
    // Same flags the old SUPER+P bind used: copy, notify, lowercase hex.
    readonly property var pickCommand: ["hyprpicker", "-a", "-n", "-l"]
    readonly property int historyLimit: 500

    // Same footprint rules as Places and Wallpaper.
    readonly property real panelHeightRatio: 0.82
    readonly property real panelAspect: 1.7
    readonly property real panelMaxWidthRatio: 0.9
    readonly property int panelMinWidth: 1100
    readonly property int panelMinHeight: 720
    readonly property int screenMargin: 48
    readonly property int panelPadding: 18
    readonly property int panelRadius: 20
    readonly property int sidebarWidth: 310
    readonly property int sectionGap: 16
    readonly property int searchHeight: 44
    readonly property int footerHeight: 30
    readonly property int rowHeight: 40
    readonly property int rowRadius: 10
    readonly property int swatchWidth: 150
    readonly property int swatchHeight: 110
    readonly property int swatchLabelHeight: 40
    readonly property int swatchGap: 12
    readonly property int swatchRadius: 12
    // Combo posters in a palette grid (portrait, like a phone post).
    readonly property int comboWidth: 240
    readonly property int comboHeight: 300
    // Palette posters: one band per colour, never thinner than this.
    readonly property int bandMinHeight: 120
    readonly property int bandTitlePixelSize: 54
    readonly property string bandFontFamily: "serif"

    readonly property int titlePixelSize: 20
    readonly property int bodyPixelSize: 13
    readonly property int metaPixelSize: 11
    readonly property int searchPixelSize: 17
    readonly property int animationDuration: 180

    readonly property real overlayOpacity: 0.32
    // Above 0.5: Hyprland's ignore_alpha for this layer, so the card stays blurred.
    readonly property real panelOpacity: 0.75
    readonly property color overlayColor: Qt.rgba(qreep.background.r, qreep.background.g, qreep.background.b, overlayOpacity)
    readonly property color panelColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, panelOpacity)
    readonly property color sheetColor: Qt.rgba(qreep.surface.r, qreep.surface.g, qreep.surface.b, 0.96)
    readonly property color cardColor: withAlpha(qreep.surfaceContainer, 0.6)
    readonly property color searchColor: withAlpha(qreep.surfaceContainerHighest, 0.8)
    readonly property color borderColor: qreep.outline
    readonly property color hoveredColor: withAlpha(qreep.surfaceContainerHigh, 0.55)
    readonly property color selectedColor: withAlpha(qreep.primary, 0.16)
    readonly property color selectedBorderColor: qreep.primary
    readonly property color chipColor: withAlpha(qreep.surfaceContainerHigh, 0.85)

    readonly property color primaryTextColor: qreep.on_surface
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary
    readonly property color sectionColor: qreep.tertiary
    readonly property color favoriteColor: qreep.warningColor
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
