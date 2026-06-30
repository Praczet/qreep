import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../../../components" as Components

Components.QreepModule {
    id: rootNetworkButton

    required property QtObject service

    tooltipTitle: rootNetworkButton.service.tooltipTitle
    tooltipContent: rootNetworkButton.service.tooltipContent
    tooltipStyle: rootNetworkButton.service.wifiConnected || rootNetworkButton.service.wiredActive ? "normal" : "warning"

    Row {
        id: networkContent

        spacing: rootNetworkButton.theme.modules.bar.network.buttonContentSpacing

        NetworkStatusIcon {
            theme: rootNetworkButton.theme
            iconName: rootNetworkButton.service.wiredIcon
            active: rootNetworkButton.service.wiredActive
        }

        NetworkStatusIcon {
            theme: rootNetworkButton.theme
            iconName: rootNetworkButton.service.wifiIcon
            active: rootNetworkButton.service.wifiConnected
        }

        NetworkStatusIcon {
            theme: rootNetworkButton.theme
            iconName: rootNetworkButton.service.bluetoothIcon
            active: rootNetworkButton.service.bluetoothConnected
        }
    }
}
