import QtQuick
import "../components" as Components

Components.QreepModule {
    id: rootPowerButton

    tooltipTitle: "Power"
    tooltipContent: "Open the power menu"
    tooltipStyle: "warning"

    Text {
        text: ""
        color: rootPowerButton.theme.primaryText
        font.family: rootPowerButton.theme.iconFontFamily
        font.pixelSize: rootPowerButton.theme.power.buttonIconPixelSize
    }
}
