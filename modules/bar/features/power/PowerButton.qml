import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootPowerButton

    required property QtObject service

    tooltipTitle: "Power"
    tooltipContent: "Open the power menu"
    tooltipStyle: "warning"

    Connections {
        target: rootPowerButton.service
    }

    Text {
        text: ""
        color: rootPowerButton.theme.modules.bar.primaryTextColor
        font.family: rootPowerButton.theme.iconFontFamily
        font.pixelSize: rootPowerButton.theme.modules.bar.power.buttonIconPixelSize
    }
}
