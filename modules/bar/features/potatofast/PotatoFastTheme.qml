import QtQuick

QtObject {
    id: rootPotatoFastTheme

    required property QtObject qreep

    readonly property int refreshInterval: 60000
    readonly property string statusCommand: "potato-fast"

    readonly property int width: 116
    readonly property int contentSpacing: 8
    readonly property int iconPixelSize: 22
    readonly property int labelPixelSize: 12
    readonly property int labelWidth: 44
    readonly property int progressWidth: 52
    readonly property int progressHeight: 8
    readonly property int progressRadius: 4

    readonly property real inactiveOpacity: 0.42
    readonly property color idleColor: qreep.on_surface_variant
    readonly property color activeColor: qreep.error
    readonly property color doneColor: qreep.primary
    readonly property color warningColor: qreep.warningColor
    readonly property color errorColor: qreep.error
    readonly property color trackColor: qreep.surfaceContainerHigh
}
