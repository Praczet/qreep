import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootPowerButton

    tooltipTitle: "Power"
    tooltipContent: "Open the power menu"
    tooltipStyle: "warning"

    Text {
        text: ""
        color: rootPowerButton.theme.modules.bar.primaryTextColor
        font.family: rootPowerButton.theme.iconFontFamily
        font.pixelSize: rootPowerButton.theme.modules.bar.power.buttonIconPixelSize
    }
}
