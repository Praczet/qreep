import QtQuick

QtObject {
    id: rootBorgTheme

    readonly property int iconPixelSize: 30
    readonly property int refreshInterval: 3600000
    readonly property string backupCommand: "borg-backup-notify"
    readonly property string backupStatusBackend: "qreep"
    readonly property real pulseScale: 1.68
    readonly property real pulseSettleScale: 0.94
    readonly property real pulseRotation: 8
    readonly property real pulseRotationSettle: 3
    readonly property int pulseOutDuration: 210
    readonly property int pulseSettleDuration: 190
    readonly property int pulseInDuration: 220
    readonly property color okColor: "#88c0d0"
    readonly property color warningColor: "#f9e2af"
    readonly property color errorColor: "#ffb4ab"
    readonly property int tooltipWidth: 360
    readonly property int tooltipLabelWidth: 92
    readonly property int tooltipColumnGap: 10
    readonly property int tooltipRowSpacing: 3
    readonly property int tooltipBlankHeight: 7
    readonly property int tooltipIconThreshold: 28
    readonly property int tooltipHeroSpacing: 12
    readonly property int tooltipHeroIconWidth: 58
    readonly property int tooltipHeroTextSpacing: 3
}
