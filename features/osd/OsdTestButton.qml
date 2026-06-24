import QtQuick
import "../../components" as Components

Components.QreepModule {
    id: rootOsdTestButton

    tooltipTitle: "OSD"
    tooltipContent: "Show a test OSD message"

    Text {
        text: "OSD"
        color: rootOsdTestButton.theme.primaryText
        font.pixelSize: rootOsdTestButton.theme.osd.testButtonTextPixelSize
        font.weight: Font.DemiBold
    }
}
