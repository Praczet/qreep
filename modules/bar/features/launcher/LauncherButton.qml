import QtQuick
import "../../components" as Components

Components.QreepModule {
    id: rootLauncherButton

    tooltipTitle: "Launcher"
    tooltipContent: "Open the launcher"
    tooltipStyle: "warning"

    Text {
        text: ""
        color: rootLauncherButton.theme.primaryText
        font.family: rootLauncherButton.theme.iconFontFamily
        font.pixelSize: rootLauncherButton.theme.launcher.buttonIconPixelSize
    }
}
