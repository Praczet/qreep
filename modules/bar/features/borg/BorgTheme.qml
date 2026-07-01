import QtQuick
import Quickshell

QtObject {
    id: rootBorgTheme

    required property QtObject qreep

    readonly property int iconPixelSize: 24
    readonly property int refreshInterval: 3600000
    readonly property string backupCommand: "borg-to-borg-backup"
    readonly property string backupStatusBackend: "qreep"
    readonly property string backupStatePath: Quickshell.env("HOME") + "/.cache/qreep/borg/state.json"
    readonly property string backupFinalPath: Quickshell.env("HOME") + "/.cache/qreep/borg/final.json"
    readonly property int backupPanelHideDelay: 2000
    readonly property int backupStatePollInterval: 1000
    readonly property real pulseScale: 1.68
    readonly property real pulseSettleScale: 0.94
    readonly property real pulseRotation: 8
    readonly property real pulseRotationSettle: 3
    readonly property int pulseOutDuration: 210
    readonly property int pulseSettleDuration: 190
    readonly property int pulseInDuration: 220
    readonly property real shakeDistance: 5
    readonly property real shakeRotation: 7
    readonly property int shakeStepDuration: 55
    readonly property color okColor: qreep.successColor
    readonly property color warningColor: qreep.warningColor
    readonly property color errorColor: qreep.error
    readonly property int progressWidth: 420
    readonly property int progressLabelWidth: 96
    readonly property int progressColumnGap: 10
    readonly property int progressRowSpacing: 5
    readonly property int progressTitlePixelSize: 13
    readonly property int progressBodyPixelSize: 11
    readonly property int progressMetaPixelSize: 10
    readonly property int progressIconPixelSize: 32
    readonly property int progressMaxPathLength: 72
    readonly property int tooltipWidth: 360
    readonly property int tooltipLabelWidth: 92
    readonly property int tooltipColumnGap: 10
    readonly property int tooltipRowSpacing: 3
    readonly property int tooltipBlankHeight: 7
    readonly property int tooltipIconThreshold: 28
    readonly property int tooltipHeroSpacing: 12
    readonly property int tooltipHeroIconWidth: 58
    readonly property int tooltipHeroTextSpacing: 3

    function classColor(className) {
        switch (className) {
        case "ok":
            return okColor;
        case "warning":
            return warningColor;
        case "error":
            return errorColor;
        default:
            return qreep.on_surface;
        }
    }

    function tokenColor(token) {
        switch (String(token || "")) {
        case "{{primary}}":
            return qreep.on_surface;
        case "{{secondary}}":
            return qreep.on_surface_variant;
        case "{{tertiary}}":
            return okColor;
        case "{{on_surface}}":
            return qreep.on_surface;
        case "{{on_surface_variant}}":
            return qreep.on_surface_variant;
        case "{{error}}":
            return errorColor;
        case "{{warning}}":
            return warningColor;
        case "{{success}}":
            return okColor;
        default:
            return qreep.on_surface;
        }
    }
}
