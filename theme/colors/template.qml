import QtQuick

QtObject {
    id: rootTemplate

    readonly property color barBackground: "{{bar_background}}"
    readonly property color moduleBackground: "{{module_background}}"
    readonly property color moduleHoverBackground: "{{module_hover_background}}"
    readonly property color primaryText: "{{primary_text}}"
    readonly property color secondaryText: "{{secondary_text}}"
}
