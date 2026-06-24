import QtQuick
import "../components" as Components

Components.QreepModule {
    id: rootBorg

    tooltipTitle: "Borg"
    tooltipContent: "Open the Borg menu"
    tooltipStyle: "warning"

    Text {
        text: " "
        color: rootBorg.theme.primaryText
        font.family: rootBorg.theme.iconFontFamily
        font.pixelSize: rootBorg.theme.borg.iconPixelSize
    }
}
