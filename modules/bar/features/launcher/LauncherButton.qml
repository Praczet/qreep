import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootLauncherButton

    tooltipTitle: "Launcher"
    tooltipContent: "Open the launcher"
    tooltipStyle: "warning"

    Text {
        text: ""
        color: rootLauncherButton.theme.modules.bar.primaryTextColor
        font.family: rootLauncherButton.theme.iconFontFamily
        font.pixelSize: rootLauncherButton.theme.modules.bar.launcher.buttonIconPixelSize
    }
}
